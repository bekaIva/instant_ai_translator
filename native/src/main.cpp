#include "../include/instant_translator.h"
#include "text_selection_monitor.h"
#include "context_menu_injector.h"
#include "dbus_service.h"
#include "text_replacement.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <gtk/gtk.h>

// Global flag for main loop
static volatile int running = 1;

// Signal handler for clean shutdown
static void signal_handler(int sig) {
    printf("Received signal %d, shutting down...\n", sig);
    running = 0;
}

// Selection callback for testing
static void on_selection_changed(SelectionData* selection) {
    if (!selection || !selection->text) return;
    
    printf("Selection changed:\n");
    printf("  Text: '%.100s%s'\n", selection->text, 
           strlen(selection->text) > 100 ? "..." : "");
    printf("  Length: %d\n", selection->length);
    printf("  Position: (%d, %d)\n", selection->x, selection->y);
    printf("  App: %s\n", selection->app_name ? selection->app_name : "unknown");
    printf("\n");
}

// Menu action callback for testing
static void on_menu_action(const char* menu_id, SelectionData* selection) {
    if (!menu_id || !selection) return;
    
    printf("Menu action triggered:\n");
    printf("  Menu ID: %s\n", menu_id);
    printf("  Selected text: '%.50s%s'\n", selection->text,
           strlen(selection->text) > 50 ? "..." : "");
    
    // Simulate text processing
    char* result = NULL;
    int status = send_processing_request(selection->text, menu_id, &result);
    
    if (status == STATUS_SUCCESS && result) {
        printf("  Processing result: %s\n", result);
        
        // Replace the selected text
        int replace_status = replace_text_via_clipboard(result);
        if (replace_status == STATUS_SUCCESS) {
            printf("  Text replacement: SUCCESS\n");
        } else {
            printf("  Text replacement: FAILED (%d)\n", replace_status);
        }
        
        free(result);
    } else {
        printf("  Processing failed with status: %d\n", status);
        
        // Fallback: just add "[PROCESSED]" prefix
        char fallback_text[1024];
        snprintf(fallback_text, sizeof(fallback_text), "[PROCESSED] %s", selection->text);
        
        int replace_status = replace_text_via_clipboard(fallback_text);
        if (replace_status == STATUS_SUCCESS) {
            printf("  Fallback replacement: SUCCESS\n");
        } else {
            printf("  Fallback replacement: FAILED (%d)\n", replace_status);
        }
    }
    
    printf("\n");
}

// Create sample menu items for testing
#ifdef STANDALONE_TEST
// Standalone test program
int main(int argc, char* argv[]) {
    printf("Instant AI Translator - Native Library Test\n");
    printf("==========================================\n\n");
    
    // Set up signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // Check system compatibility
    if (!is_system_compatible()) {
        printf("ERROR: System is not compatible\n");
        printf("Requirements:\n");
        printf("- X11 display server\n");
        printf("- GTK 3.0\n");
        printf("- xclip utility\n");
        printf("- xdotool utility\n");
        return 1;
    }
    
    char* desktop_env = get_desktop_environment();
    printf("Desktop Environment: %s\n", desktop_env);
    free(desktop_env);
    
    // Initialize system hooks
    printf("Initializing system hooks...\n");
    int status = init_system_hooks();
    if (status != STATUS_SUCCESS) {
        char* error = get_last_error();
        printf("ERROR: Failed to initialize system hooks: %s\n", 
               error ? error : "Unknown error");
        if (error) free(error);
        return 1;
    }
    printf("System hooks initialized successfully\n");
    
    // Set up callbacks
    set_selection_callback(on_selection_changed);
    set_menu_action_callback(on_menu_action);
    
    // Start with empty menu - Flutter will register items
    printf("System ready. Context menu will show only Flutter-registered items.\n");
    printf("Use Flutter app to register menu items dynamically.\n");
    
    printf("\nSystem is ready!\n");
    printf("Instructions:\n");
    printf("1. Select text in any application\n");
    printf("2. Press Ctrl+Shift+M to show context menu\n");
    printf("3. Choose an AI operation from the menu\n");
    printf("4. Press Ctrl+C to exit this program\n\n");
    
    // Main loop
    while (running) {
        // Check for current selection periodically
        SelectionData* selection = get_current_selection();
        if (selection && selection->text && strlen(selection->text) > 0) {
            // Selection is available (monitoring will trigger callback)
        }
        if (selection) {
            free_selection_data(selection);
        }
        
        usleep(500000); // 500ms
    }
    
    printf("\nShutting down...\n");
    
    // Cleanup
    unregister_context_menu();
    cleanup_system_hooks();
    
    printf("Cleanup completed\n");
    return 0;
}
#endif
