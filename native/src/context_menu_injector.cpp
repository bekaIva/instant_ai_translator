#include "context_menu_injector.h"
#include "text_selection_monitor.h"
#include "text_replacement.h"
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <X11/extensions/XTest.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// Menu state
static MenuItem* registered_menu_items = NULL;
static int menu_item_count = 0;
static MenuActionCallback menu_action_callback = NULL;
static GtkWidget* popup_menu = NULL;
static SelectionData* current_selection = NULL;
static GtkWidget* current_menu_window = NULL; // Track current menu window for toggle functionality

// Global hotkey monitoring
static Display* x_display = NULL;
static gboolean hotkey_monitoring = FALSE;
static GThread* hotkey_thread = NULL;

// Menu item callback data
typedef struct {
    char* menu_id;
    SelectionData* selection;
} MenuCallbackData;

// Menu item click handler
static void menu_item_activated(GtkMenuItem* item, gpointer user_data) {
    MenuCallbackData* data = (MenuCallbackData*)user_data;
    
    if (menu_action_callback && data) {
        menu_action_callback(data->menu_id, data->selection);
    }
    
    // Hide menu
    if (popup_menu) {
        gtk_widget_hide(popup_menu);
    }
}

// Create menu item widget
static GtkWidget* create_menu_item(MenuItem* item, SelectionData* selection) {
    GtkWidget* menu_item = gtk_menu_item_new_with_label(item->label);
    
    // Create callback data
    MenuCallbackData* data = (MenuCallbackData*)malloc(sizeof(MenuCallbackData));
    data->menu_id = strdup(item->id);
    data->selection = selection; // Reference to selection data
    
    // Connect signal
    g_signal_connect(menu_item, "activate", G_CALLBACK(menu_item_activated), data);
    
    // Set sensitivity based on enabled flag
    gtk_widget_set_sensitive(menu_item, item->enabled);
    
    return menu_item;
}

// Create context menu
static GtkWidget* create_context_menu(SelectionData* selection) {
    GtkWidget* menu = gtk_menu_new();
    
    if (!registered_menu_items || menu_item_count == 0) {
        // Add default "No actions available" item
        GtkWidget* item = gtk_menu_item_new_with_label("No AI actions available");
        gtk_widget_set_sensitive(item, FALSE);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
        gtk_widget_show(item);
        return menu;
    }
    
    // Add separator with selected text info
    if (selection && selection->text) {
        char info_text[256];
        int text_len = strlen(selection->text);
        if (text_len > 50) {
            snprintf(info_text, sizeof(info_text), "Selected: %.47s...", selection->text);
        } else {
            snprintf(info_text, sizeof(info_text), "Selected: %s", selection->text);
        }
        
        GtkWidget* info_item = gtk_menu_item_new_with_label(info_text);
        gtk_widget_set_sensitive(info_item, FALSE);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu), info_item);
        gtk_widget_show(info_item);
        
        // Add separator
        GtkWidget* separator = gtk_separator_menu_item_new();
        gtk_menu_shell_append(GTK_MENU_SHELL(menu), separator);
        gtk_widget_show(separator);
    }
    
    // Add registered menu items
    for (int i = 0; i < menu_item_count; i++) {
        GtkWidget* item = create_menu_item(&registered_menu_items[i], selection);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
        gtk_widget_show(item);
    }
    
    return menu;
}

// Callback for menu button clicks
static void on_menu_button_clicked(GtkWidget* button, gpointer data) {
    const char* menu_id = (const char*)g_object_get_data(G_OBJECT(button), "menu_id");
    GtkWidget* window = (GtkWidget*)g_object_get_data(G_OBJECT(button), "window");
    
    printf("Menu item clicked: %s\n", menu_id);
    
    if (current_selection) {
        printf("Processing selection: %s\n", current_selection->text);
        
        // Call the callback if registered
        if (menu_action_callback) {
            printf("Calling menu action callback for: %s\n", menu_id);
            menu_action_callback(menu_id, current_selection);
        } else {
            // Fallback: write action to file for Flutter processing (no native replacement)
            printf("No callback registered, delegating to Flutter via file\n");
            
            // Write action to file for Flutter to pick up and process
            FILE* action_file = fopen("/tmp/instant_translator_action.txt", "w");
            if (action_file) {
                fprintf(action_file, "%s\t\n%s\n", menu_id, current_selection->text);
                fclose(action_file);
                printf("Action written to file for Flutter pickup\n");
            }
            
            // Don't do native replacement - let Flutter handle everything
        }
    }
    
    // Close menu and reset state
    if (window) {
        gtk_widget_destroy(window);
        current_menu_window = NULL;
    }
}

// Callback for window destroy event
static void on_window_destroy(GtkWidget* window, gpointer data) {
    printf("Menu window destroyed\n");
    current_menu_window = NULL;
}

// Callback for focus out event (removed timeout handling since we don't use timeout anymore)
static gboolean on_window_focus_out(GtkWidget* window, GdkEvent* event, gpointer data) {
    gtk_widget_destroy(window);
    current_menu_window = NULL;
    return FALSE;
}

// Data structure for menu creation in main thread
typedef struct {
    int x;
    int y;
    SelectionData* selection;
} MenuCreationData;

// Show notification dialog in main thread
static gboolean show_notification_in_main_thread(gpointer data) {
    printf("Showing no-text-selected notification\n");
    
    GtkWidget* dialog = gtk_message_dialog_new(NULL,
        GTK_DIALOG_MODAL,
        GTK_MESSAGE_INFO,
        GTK_BUTTONS_OK,
        "Instant AI Translator\n\nHotkey Ctrl+Shift+M detected!\nPlease select some text first.");
    
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
    
    // Return FALSE to remove this idle handler
    return FALSE;
}

// Show no-text notification (thread-safe)
static void show_no_text_notification() {
    printf("Queuing no-text notification\n");
    g_idle_add(show_notification_in_main_thread, NULL);
}

// Create menu in GTK main thread
static gboolean create_menu_in_main_thread(gpointer data) {
    MenuCreationData* menu_data = (MenuCreationData*)data;
    int x = menu_data->x;
    int y = menu_data->y;
    SelectionData* selection = menu_data->selection;
    
    printf("Creating context menu at position (%d, %d) in main thread\n", x, y);
    
    // Store current selection
    current_selection = selection;
    
    // Create a simple window-based menu instead of popup
    GtkWidget* window = gtk_window_new(GTK_WINDOW_POPUP);
    gtk_window_set_type_hint(GTK_WINDOW(window), GDK_WINDOW_TYPE_HINT_MENU);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
    // Create menu container
    GtkWidget* vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
    gtk_container_add(GTK_CONTAINER(window), vbox);
    
    // Add title
    char title_text[256];
    if (selection && selection->text) {
        int text_len = strlen(selection->text);
        if (text_len > 30) {
            snprintf(title_text, sizeof(title_text), "AI Translate: %.27s...", selection->text);
        } else {
            snprintf(title_text, sizeof(title_text), "AI Translate: %s", selection->text);
        }
    } else {
        snprintf(title_text, sizeof(title_text), "AI Translator");
    }
    
    GtkWidget* title_label = gtk_label_new(title_text);
    gtk_widget_set_margin_top(title_label, 8);
    gtk_widget_set_margin_bottom(title_label, 4);
    gtk_widget_set_margin_start(title_label, 8);
    gtk_widget_set_margin_end(title_label, 8);
    
    // Make title bold
    PangoAttrList* attrs = pango_attr_list_new();
    pango_attr_list_insert(attrs, pango_attr_weight_new(PANGO_WEIGHT_BOLD));
    gtk_label_set_attributes(GTK_LABEL(title_label), attrs);
    pango_attr_list_unref(attrs);
    
    gtk_box_pack_start(GTK_BOX(vbox), title_label, FALSE, FALSE, 0);
    
    // Add separator
    GtkWidget* separator = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_box_pack_start(GTK_BOX(vbox), separator, FALSE, FALSE, 0);
    
    // Add menu items
    if (registered_menu_items && menu_item_count > 0) {
        for (int i = 0; i < menu_item_count; i++) {
            if (registered_menu_items[i].enabled) {
                GtkWidget* button = gtk_button_new_with_label(registered_menu_items[i].label);
                gtk_widget_set_margin_start(button, 4);
                gtk_widget_set_margin_end(button, 4);
                gtk_widget_set_margin_top(button, 2);
                gtk_widget_set_margin_bottom(button, 2);
                
                // Set button data
                g_object_set_data(G_OBJECT(button), "menu_id", (gpointer)registered_menu_items[i].id);
                g_object_set_data(G_OBJECT(button), "window", window);
                
                // Connect click handler
                g_signal_connect(button, "clicked", G_CALLBACK(on_menu_button_clicked), NULL);
                
                gtk_box_pack_start(GTK_BOX(vbox), button, FALSE, FALSE, 0);
            }
        }
    } else {
        GtkWidget* no_items_label = gtk_label_new("No AI actions available");
        gtk_widget_set_margin_start(no_items_label, 8);
        gtk_widget_set_margin_end(no_items_label, 8);
        gtk_widget_set_margin_top(no_items_label, 4);
        gtk_widget_set_margin_bottom(no_items_label, 8);
        gtk_box_pack_start(GTK_BOX(vbox), no_items_label, FALSE, FALSE, 0);
    }
    
    // Position the window
    gtk_window_move(GTK_WINDOW(window), x, y);
    
    // Track this window for toggle functionality
    current_menu_window = window;
    
    // Show the window
    gtk_widget_show_all(window);
    
    // Connect destroy signal to reset tracking
    g_signal_connect(window, "destroy", G_CALLBACK(on_window_destroy), NULL);
    
    // Close on focus out
    g_signal_connect(window, "focus-out-event", G_CALLBACK(on_window_focus_out), NULL);
    
    printf("Context menu window created and shown\n");
    
    // Cleanup menu creation data
    free(menu_data);
    
    // Return FALSE to remove this idle handler
    return FALSE;
}

// Show context menu at specific position (thread-safe)
static void show_menu_at_position(int x, int y, SelectionData* selection) {
    printf("Queuing context menu creation for position (%d, %d)\n", x, y);
    
    // Create data for menu creation in main thread
    MenuCreationData* menu_data = (MenuCreationData*)malloc(sizeof(MenuCreationData));
    menu_data->x = x;
    menu_data->y = y;
    menu_data->selection = selection;
    
    // Schedule menu creation in GTK main thread
    g_idle_add(create_menu_in_main_thread, menu_data);
}

// Hotkey monitoring thread (Ctrl+Shift+M)
static gpointer hotkey_monitor_thread(gpointer data) {
    KeySym ctrl_l = XK_Control_L;
    KeySym ctrl_r = XK_Control_R;
    KeySym shift_l = XK_Shift_L;
    KeySym shift_r = XK_Shift_R;
    KeySym m_key = XK_m;
    
    KeyCode ctrl_l_code = XKeysymToKeycode(x_display, ctrl_l);
    KeyCode ctrl_r_code = XKeysymToKeycode(x_display, ctrl_r);
    KeyCode shift_l_code = XKeysymToKeycode(x_display, shift_l);
    KeyCode shift_r_code = XKeysymToKeycode(x_display, shift_r);
    KeyCode m_code = XKeysymToKeycode(x_display, m_key);
    
    printf("Registering global hotkey: Ctrl+Shift+M\n");
    printf("Keycodes: Ctrl=%d/%d, Shift=%d/%d, M=%d\n", 
           ctrl_l_code, ctrl_r_code, shift_l_code, shift_r_code, m_code);
    
    Window root = DefaultRootWindow(x_display);
    
    // Register global hotkey using XGrabKey
    // Modifier mask: ControlMask + ShiftMask
    unsigned int modifiers = ControlMask | ShiftMask;
    
    // Grab the key combination globally
    XGrabKey(x_display, m_code, modifiers, root, True, GrabModeAsync, GrabModeAsync);
    XGrabKey(x_display, m_code, modifiers | LockMask, root, True, GrabModeAsync, GrabModeAsync); // With CapsLock
    XGrabKey(x_display, m_code, modifiers | Mod2Mask, root, True, GrabModeAsync, GrabModeAsync); // With NumLock
    XGrabKey(x_display, m_code, modifiers | LockMask | Mod2Mask, root, True, GrabModeAsync, GrabModeAsync); // Both
    
    XSelectInput(x_display, root, KeyPressMask);
    XSync(x_display, False);
    
    printf("Global hotkey registered successfully\n");
    
    while (hotkey_monitoring) {
        XEvent event;
        if (XPending(x_display) > 0) {
            XNextEvent(x_display, &event);
            
            if (event.type == KeyPress) {
                printf("Global key event: keycode=%d, state=%d\n", event.xkey.keycode, event.xkey.state);
                
                // Check if this is our hotkey
                if (event.xkey.keycode == m_code && 
                    (event.xkey.state & (ControlMask | ShiftMask)) == (ControlMask | ShiftMask)) {
                    
                    printf("🎯 Hotkey triggered: Ctrl+Shift+M detected!\n");
                    
                    // Check if menu is currently open - toggle functionality
                    if (current_menu_window && GTK_IS_WIDGET(current_menu_window)) {
                        printf("🔽 Menu is open - closing it\n");
                        gtk_widget_destroy(current_menu_window);
                        current_menu_window = NULL;
                    } else {
                        printf("🔼 Menu is closed - opening it\n");
                        
                        // Get current selection
                        SelectionData* selection = get_selected_text();
                        if (selection && selection->text && strlen(selection->text) > 0) {
                            printf("📝 Showing menu for selected text: '%s'\n", selection->text);
                            
                            // Show menu at mouse position
                            show_menu_at_position(selection->x, selection->y, selection);
                        } else {
                            printf("⚠️  No text selected - showing simple notification\n");
                            
                            // Show a simple notification that hotkey works (thread-safe)
                            show_no_text_notification();
                        }
                    }
                }
            }
        }
        
        // Small sleep to prevent high CPU usage
        usleep(10000); // 10ms
        
        // Small delay to prevent high CPU usage
        usleep(10000); // 10ms
    }
    
    return NULL;
}

// Initialize context menu system
int init_context_menu_system() {
    // Initialize X11 threading support before any X11 calls
    if (!XInitThreads()) {
        printf("Warning: XInitThreads() failed - X11 threading may not be safe\n");
    } else {
        printf("✅ X11 threading initialized successfully\n");
    }
    
    // Open X display for hotkey monitoring
    x_display = XOpenDisplay(NULL);
    if (!x_display) {
        return STATUS_ERROR_NO_DISPLAY;
    }
    
    // Check if XTest extension is available
    int event_base, error_base, major_version, minor_version;
    if (!XTestQueryExtension(x_display, &event_base, &error_base, &major_version, &minor_version)) {
        XCloseDisplay(x_display);
        return STATUS_ERROR_INIT;
    }
    
    // Start hotkey monitoring
    hotkey_monitoring = TRUE;
    hotkey_thread = g_thread_new("hotkey-monitor", hotkey_monitor_thread, NULL);
    
    if (!hotkey_thread) {
        cleanup_context_menu_system();
        return STATUS_ERROR_INIT;
    }
    
    return STATUS_SUCCESS;
}

// Cleanup context menu system
void cleanup_context_menu_system() {
    // Stop hotkey monitoring
    hotkey_monitoring = FALSE;
    
    if (hotkey_thread) {
        g_thread_join(hotkey_thread);
        hotkey_thread = NULL;
    }
    
    // Ungrab the global hotkey
    if (x_display) {
        KeyCode m_code = XKeysymToKeycode(x_display, XK_m);
        unsigned int modifiers = ControlMask | ShiftMask;
        Window root = DefaultRootWindow(x_display);
        
        XUngrabKey(x_display, m_code, modifiers, root);
        XUngrabKey(x_display, m_code, modifiers | LockMask, root);
        XUngrabKey(x_display, m_code, modifiers | Mod2Mask, root);
        XUngrabKey(x_display, m_code, modifiers | LockMask | Mod2Mask, root);
        
        XSync(x_display, False);
        printf("Global hotkey unregistered\n");
    }
    
    // Cleanup menu windows
    if (current_menu_window) {
        gtk_widget_destroy(current_menu_window);
        current_menu_window = NULL;
    }
    if (popup_menu) {
        gtk_widget_destroy(popup_menu);
        popup_menu = NULL;
    }
    
    // Cleanup registered menu items
    if (registered_menu_items) {
        for (int i = 0; i < menu_item_count; i++) {
            if (registered_menu_items[i].id) free(registered_menu_items[i].id);
            if (registered_menu_items[i].label) free(registered_menu_items[i].label);
            if (registered_menu_items[i].operation) free(registered_menu_items[i].operation);
            if (registered_menu_items[i].ai_instruction) free(registered_menu_items[i].ai_instruction);
        }
        free(registered_menu_items);
        registered_menu_items = NULL;
        menu_item_count = 0;
    }
    
    // Close X display
    if (x_display) {
        XCloseDisplay(x_display);
        x_display = NULL;
    }
}

// Register menu items
int register_menu_items(MenuItem* menu_items, int count) {
    if (!menu_items || count <= 0) {
        return STATUS_ERROR_INIT;
    }
    
    // Cleanup existing menu items
    unregister_menu_items();
    
    // Allocate memory for new menu items
    registered_menu_items = (MenuItem*)malloc(sizeof(MenuItem) * count);
    if (!registered_menu_items) {
        return STATUS_ERROR_INIT;
    }
    
    // Copy menu items
    for (int i = 0; i < count; i++) {
        registered_menu_items[i].id = strdup(menu_items[i].id);
        registered_menu_items[i].label = strdup(menu_items[i].label);
        registered_menu_items[i].operation = strdup(menu_items[i].operation);
        registered_menu_items[i].ai_instruction = strdup(menu_items[i].ai_instruction);
        registered_menu_items[i].enabled = menu_items[i].enabled;
    }
    
    menu_item_count = count;
    return STATUS_SUCCESS;
}

// Unregister menu items
int unregister_menu_items() {
    if (registered_menu_items) {
        for (int i = 0; i < menu_item_count; i++) {
            if (registered_menu_items[i].id) free(registered_menu_items[i].id);
            if (registered_menu_items[i].label) free(registered_menu_items[i].label);
            if (registered_menu_items[i].operation) free(registered_menu_items[i].operation);
            if (registered_menu_items[i].ai_instruction) free(registered_menu_items[i].ai_instruction);
        }
        free(registered_menu_items);
        registered_menu_items = NULL;
        menu_item_count = 0;
    }
    
    return STATUS_SUCCESS;
}

// Set callback for menu actions
int set_context_menu_callback(MenuActionCallback callback) {
    menu_action_callback = callback;
    return STATUS_SUCCESS;
}

// Show context menu at coordinates
int show_context_menu_at(int x, int y, SelectionData* selection) {
    if (!selection) {
        return STATUS_ERROR_NO_SELECTION;
    }
    
    // Show menu directly
    show_menu_at_position(x, y, selection);
    
    return STATUS_SUCCESS;
}
