#include "text_selection_monitor.h"
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

// X11 display and atoms
static Display* display = NULL;
static Window root_window;
static Atom clipboard_atom;
static Atom primary_atom;
static Atom utf8_string_atom;
static Atom targets_atom;

// Selection monitoring
static SelectionCallback selection_callback = NULL;
static char* last_selection = NULL;
static GThread* monitor_thread = NULL;
static gboolean monitoring = FALSE;

// Get active window information
static Window get_active_window() {
    Window active_window = 0;
    Atom active_window_atom = XInternAtom(display, "_NET_ACTIVE_WINDOW", False);
    
    Atom actual_type;
    int actual_format;
    unsigned long nitems, bytes_after;
    unsigned char* prop;
    
    if (XGetWindowProperty(display, root_window, active_window_atom,
                          0, 1, False, XA_WINDOW, &actual_type,
                          &actual_format, &nitems, &bytes_after, &prop) == Success) {
        if (prop) {
            active_window = *(Window*)prop;
            XFree(prop);
        }
    }
    
    return active_window;
}

// Get window class name (application name)
static char* get_window_class(Window window) {
    if (window == 0) return strdup("unknown");
    
    XClassHint class_hint;
    if (XGetClassHint(display, window, &class_hint) == Success) {
        char* app_name = strdup(class_hint.res_class ? class_hint.res_class : "unknown");
        if (class_hint.res_name) XFree(class_hint.res_name);
        if (class_hint.res_class) XFree(class_hint.res_class);
        return app_name;
    }
    
    return strdup("unknown");
}

// Get selection text using xclip (more reliable than X11 selection API)
static char* get_selection_via_xclip() {
    FILE* pipe = popen("xclip -selection primary -o 2>/dev/null", "r");
    if (!pipe) {
        return NULL;
    }
    
    char buffer[4096];
    char* result = NULL;
    size_t total_size = 0;
    size_t read_size;
    
    while ((read_size = fread(buffer, 1, sizeof(buffer), pipe)) > 0) {
        result = (char*)realloc(result, total_size + read_size + 1);
        if (!result) {
            pclose(pipe);
            return NULL;
        }
        memcpy(result + total_size, buffer, read_size);
        total_size += read_size;
    }
    
    pclose(pipe);
    
    if (result) {
        result[total_size] = '\0';
        
        // Remove trailing newlines
        while (total_size > 0 && (result[total_size - 1] == '\n' || result[total_size - 1] == '\r')) {
            result[--total_size] = '\0';
        }
        
        // Return NULL if empty
        if (total_size == 0) {
            free(result);
            return NULL;
        }
    }
    
    return result;
}

// Get current mouse position
static void get_mouse_position(int* x, int* y) {
    Window root_return, child_return;
    int root_x, root_y, win_x, win_y;
    unsigned int mask_return;
    
    if (XQueryPointer(display, root_window, &root_return, &child_return,
                     &root_x, &root_y, &win_x, &win_y, &mask_return)) {
        *x = root_x;
        *y = root_y;
    } else {
        *x = 0;
        *y = 0;
    }
}

// Selection monitoring thread
static gpointer selection_monitor_thread(gpointer data) {
    while (monitoring) {
        char* current_selection = get_selection_via_xclip();
        
        // Check if selection changed
        if (current_selection && 
            (!last_selection || strcmp(current_selection, last_selection) != 0)) {
            
            // Update last selection
            if (last_selection) {
                free(last_selection);
            }
            last_selection = strdup(current_selection);
            
            // Create selection data
            if (selection_callback && strlen(current_selection) > 0) {
                SelectionData* data = (SelectionData*)malloc(sizeof(SelectionData));
                data->text = strdup(current_selection);
                data->length = strlen(current_selection);
                
                // Get mouse position
                get_mouse_position(&data->x, &data->y);
                
                // Get active window application name
                Window active_window = get_active_window();
                data->app_name = get_window_class(active_window);
                
                // Call callback
                selection_callback(data);
                
                // Note: Don't free data here - it's caller's responsibility
            }
        }
        
        if (current_selection) {
            free(current_selection);
        }
        
        // Check every 100ms
        g_usleep(100000);
    }
    
    return NULL;
}

// Initialize text selection monitoring
int init_text_selection_monitor() {
    // Open X11 display
    display = XOpenDisplay(NULL);
    if (!display) {
        return STATUS_ERROR_NO_DISPLAY;
    }
    
    root_window = DefaultRootWindow(display);
    
    // Initialize atoms
    clipboard_atom = XInternAtom(display, "CLIPBOARD", False);
    primary_atom = XA_PRIMARY;
    utf8_string_atom = XInternAtom(display, "UTF8_STRING", False);
    targets_atom = XInternAtom(display, "TARGETS", False);
    
    // Start monitoring thread
    monitoring = TRUE;
    monitor_thread = g_thread_new("selection-monitor", selection_monitor_thread, NULL);
    
    if (!monitor_thread) {
        cleanup_text_selection_monitor();
        return STATUS_ERROR_INIT;
    }
    
    return STATUS_SUCCESS;
}

// Cleanup text selection monitoring
void cleanup_text_selection_monitor() {
    // Stop monitoring
    monitoring = FALSE;
    
    // Join monitor thread
    if (monitor_thread) {
        g_thread_join(monitor_thread);
        monitor_thread = NULL;
    }
    
    // Cleanup last selection
    if (last_selection) {
        free(last_selection);
        last_selection = NULL;
    }
    
    // Close X11 display
    if (display) {
        XCloseDisplay(display);
        display = NULL;
    }
}

// Get currently selected text
SelectionData* get_selected_text() {
    char* text = get_selection_via_xclip();
    if (!text || strlen(text) == 0) {
        if (text) free(text);
        return NULL;
    }
    
    SelectionData* data = (SelectionData*)malloc(sizeof(SelectionData));
    data->text = text;
    data->length = strlen(text);
    
    // Get mouse position
    get_mouse_position(&data->x, &data->y);
    
    // Get active window application name
    Window active_window = get_active_window();
    data->app_name = get_window_class(active_window);
    
    return data;
}

// Replace selected text using clipboard and keyboard simulation
int replace_selected_text(const char* new_text) {
    if (!new_text) {
        return STATUS_ERROR_INIT;
    }
    
    // Store current clipboard content
    char* original_clipboard = NULL;
    FILE* pipe = popen("xclip -selection clipboard -o 2>/dev/null", "r");
    if (pipe) {
        char buffer[4096];
        size_t read_size = fread(buffer, 1, sizeof(buffer) - 1, pipe);
        if (read_size > 0) {
            buffer[read_size] = '\0';
            original_clipboard = strdup(buffer);
        }
        pclose(pipe);
    }
    
    // Set new text to clipboard
    FILE* clip_pipe = popen("xclip -selection clipboard", "w");
    if (!clip_pipe) {
        if (original_clipboard) free(original_clipboard);
        return STATUS_ERROR_INIT;
    }
    
    fwrite(new_text, 1, strlen(new_text), clip_pipe);
    pclose(clip_pipe);
    
    // Simulate Ctrl+V to paste
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "xdotool key ctrl+v");
    int result = system(cmd);
    
    // Give some time for the paste to complete
    usleep(100000); // 100ms
    
    // Restore original clipboard content
    if (original_clipboard) {
        FILE* restore_pipe = popen("xclip -selection clipboard", "w");
        if (restore_pipe) {
            fwrite(original_clipboard, 1, strlen(original_clipboard), restore_pipe);
            pclose(restore_pipe);
        }
        free(original_clipboard);
    }
    
    return result == 0 ? STATUS_SUCCESS : STATUS_ERROR_INIT;
}

// Replace text at specific coordinates
int replace_text_at_coords(const char* new_text, int x, int y) {
    if (!new_text) {
        return STATUS_ERROR_INIT;
    }
    
    // Click at the specified coordinates first
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "xdotool mousemove %d %d click 1", x, y);
    int result = system(cmd);
    (void)result; // Suppress unused result warning
    
    // Give time for the click to register
    usleep(50000); // 50ms
    
    // Then replace the text
    return replace_selected_text(new_text);
}

// Set callback for selection changes
int set_text_selection_callback(SelectionCallback callback) {
    selection_callback = callback;
    return STATUS_SUCCESS;
}
