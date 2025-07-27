#include "../include/instant_translator.h"
#include "text_selection_monitor.h"
#include "context_menu_injector.h"
#include "dbus_service.h"

#include <gtk/gtk.h>
#include <glib.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// Global state
static gboolean system_initialized = FALSE;
static GMainLoop* main_loop = NULL;
static GThread* gtk_thread = NULL;
static char* last_error = NULL;

// Callbacks
static SelectionCallback selection_callback = NULL;
static MenuActionCallback menu_action_callback = NULL;

// Internal error handling
static void set_last_error(const char* error) {
    if (last_error) {
        free(last_error);
    }
    last_error = strdup(error);
}

// GTK thread function
static gpointer gtk_thread_func(gpointer data) {
    // Initialize GTK in this thread
    if (!gtk_init_check(NULL, NULL)) {
        set_last_error("Failed to initialize GTK");
        return GINT_TO_POINTER(STATUS_ERROR_GTK);
    }
    
    // Create and run main loop for GTK events
    main_loop = g_main_loop_new(NULL, FALSE);
    g_main_loop_run(main_loop);
    
    return GINT_TO_POINTER(STATUS_SUCCESS);
}

// Initialize the system hooks
int init_system_hooks() {
    if (system_initialized) {
        return STATUS_SUCCESS;
    }
    
    // Check if we can connect to X11 display
    if (!getenv("DISPLAY")) {
        set_last_error("No DISPLAY environment variable - X11 required");
        return STATUS_ERROR_NO_DISPLAY;
    }
    
    // Initialize threading (g_thread_init is deprecated since GLib 2.32)
    // Threading is automatically initialized in modern GLib versions
    
    // Start GTK in separate thread
    gtk_thread = g_thread_new("gtk-thread", gtk_thread_func, NULL);
    if (!gtk_thread) {
        set_last_error("Failed to create GTK thread");
        return STATUS_ERROR_INIT;
    }
    
    // Give GTK thread time to initialize
    g_usleep(100000); // 100ms
    
    // Initialize text selection monitoring
    if (init_text_selection_monitor() != STATUS_SUCCESS) {
        set_last_error("Failed to initialize text selection monitor");
        cleanup_system_hooks();
        return STATUS_ERROR_INIT;
    }
    
    // Initialize context menu system
    if (init_context_menu_system() != STATUS_SUCCESS) {
        set_last_error("Failed to initialize context menu system");
        cleanup_system_hooks();
        return STATUS_ERROR_INIT;
    }
    
    // Initialize D-Bus service
    if (init_dbus_service() != STATUS_SUCCESS) {
        set_last_error("Failed to initialize D-Bus service");
        cleanup_system_hooks();
        return STATUS_ERROR_INIT;
    }
    
    system_initialized = TRUE;
    return STATUS_SUCCESS;
}

// Cleanup system hooks
void cleanup_system_hooks() {
    if (!system_initialized) {
        return;
    }
    
    // Cleanup D-Bus
    cleanup_dbus_service();
    
    // Cleanup context menu system
    cleanup_context_menu_system();
    
    // Cleanup text selection monitor
    cleanup_text_selection_monitor();
    
    // Stop GTK main loop
    if (main_loop) {
        g_main_loop_quit(main_loop);
        g_main_loop_unref(main_loop);
        main_loop = NULL;
    }
    
    // Join GTK thread
    if (gtk_thread) {
        g_thread_join(gtk_thread);
        gtk_thread = NULL;
    }
    
    // Cleanup error string
    if (last_error) {
        free(last_error);
        last_error = NULL;
    }
    
    system_initialized = FALSE;
}

// Register context menu items
int register_context_menu(MenuItem* menu_items, int count) {
    if (!system_initialized) {
        set_last_error("System not initialized");
        return STATUS_ERROR_INIT;
    }
    
    return register_menu_items(menu_items, count);
}

// Unregister context menu
int unregister_context_menu() {
    if (!system_initialized) {
        set_last_error("System not initialized");
        return STATUS_ERROR_INIT;
    }
    
    return unregister_menu_items();
}

// Get current text selection
SelectionData* get_current_selection() {
    if (!system_initialized) {
        set_last_error("System not initialized");
        return NULL;
    }
    
    return get_selected_text();
}

// Free selection data
void free_selection_data(SelectionData* data) {
    if (!data) return;
    
    if (data->text) {
        free(data->text);
    }
    if (data->app_name) {
        free(data->app_name);
    }
    free(data);
}

// Replace selected text
int replace_selection(const char* new_text) {
    if (!system_initialized) {
        set_last_error("System not initialized");
        return STATUS_ERROR_INIT;
    }
    
    if (!new_text) {
        set_last_error("New text cannot be NULL");
        return STATUS_ERROR_INIT;
    }
    
    return replace_selected_text(new_text);
}

// Replace text at specific coordinates
int replace_selection_at_coords(const char* new_text, int x, int y) {
    if (!system_initialized) {
        set_last_error("System not initialized");
        return STATUS_ERROR_INIT;
    }
    
    if (!new_text) {
        set_last_error("New text cannot be NULL");
        return STATUS_ERROR_INIT;
    }
    
    return replace_text_at_coords(new_text, x, y);
}

// Set selection callback
int set_selection_callback(SelectionCallback callback) {
    selection_callback = callback;
    return set_text_selection_callback(callback);
}

// Set menu action callback
int set_menu_action_callback(MenuActionCallback callback) {
    menu_action_callback = callback;
    return set_context_menu_callback(callback);
}

// Check system compatibility
int is_system_compatible() {
    // Check for X11
    if (!getenv("DISPLAY")) {
        return 0;
    }
    
    // Check for GTK
    if (!gtk_init_check(NULL, NULL)) {
        return 0;
    }
    
    return 1;
}

// Get desktop environment
char* get_desktop_environment() {
    const char* desktop = getenv("XDG_CURRENT_DESKTOP");
    if (!desktop) {
        desktop = getenv("DESKTOP_SESSION");
    }
    if (!desktop) {
        desktop = "unknown";
    }
    
    return strdup(desktop);
}

// Get last error message
char* get_last_error() {
    return last_error ? strdup(last_error) : NULL;
}

// Memory management helpers
void free_string(char* str) {
    if (str) {
        free(str);
    }
}

void free_menu_items(MenuItem* items, int count) {
    if (!items) return;
    
    for (int i = 0; i < count; i++) {
        if (items[i].id) free(items[i].id);
        if (items[i].label) free(items[i].label);
        if (items[i].operation) free(items[i].operation);
        if (items[i].ai_instruction) free(items[i].ai_instruction);
    }
    free(items);
}
