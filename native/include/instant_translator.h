#ifndef INSTANT_TRANSLATOR_H
#define INSTANT_TRANSLATOR_H

#ifdef __cplusplus
extern "C" {
#endif

// Data structures for FFI
typedef struct {
    char* text;
    int x, y;           // Selection coordinates (screen coordinates)
    char* app_name;     // Source application name
    int length;         // Length of selected text
} SelectionData;

typedef struct {
    char* id;           // Menu item ID
    char* label;        // Display label
    char* operation;    // Operation type (translate, enhance, etc.)
    char* ai_instruction; // Custom AI instruction
    int enabled;        // Whether menu item is enabled
} MenuItem;

typedef enum {
    STATUS_SUCCESS = 0,
    STATUS_ERROR_INIT = -1,
    STATUS_ERROR_NO_SELECTION = -2,
    STATUS_ERROR_NO_DISPLAY = -3,
    STATUS_ERROR_DBUS = -4,
    STATUS_ERROR_GTK = -5
} StatusCode;

// Core system hooks functions
int init_system_hooks();
void cleanup_system_hooks();

// Context menu management
int register_context_menu(MenuItem* menu_items, int count);
int unregister_context_menu();

// Text selection operations
SelectionData* get_current_selection();
void free_selection_data(SelectionData* data);

// Text replacement operations
int replace_selection(const char* new_text);
int replace_selection_at_coords(const char* new_text, int x, int y);

// D-Bus communication
int init_dbus_service();
void cleanup_dbus_service();
int send_processing_request(const char* text, const char* operation, char** result);

// Event system
typedef void (*SelectionCallback)(SelectionData* selection);
typedef void (*MenuActionCallback)(const char* menu_id, SelectionData* selection);

int set_selection_callback(SelectionCallback callback);
int set_menu_action_callback(MenuActionCallback callback);

// Utility functions
int is_system_compatible();
char* get_desktop_environment();
char* get_last_error();

// Memory management helpers
void free_string(char* str);
void free_menu_items(MenuItem* items, int count);

#ifdef __cplusplus
}
#endif

#endif // INSTANT_TRANSLATOR_H
