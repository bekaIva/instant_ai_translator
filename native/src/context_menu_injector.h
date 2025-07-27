#ifndef CONTEXT_MENU_INJECTOR_H
#define CONTEXT_MENU_INJECTOR_H

#include "../include/instant_translator.h"

#ifdef __cplusplus
extern "C" {
#endif

// Initialize context menu system
int init_context_menu_system();

// Cleanup context menu system
void cleanup_context_menu_system();

// Register menu items
int register_menu_items(MenuItem* menu_items, int count);

// Unregister menu items
int unregister_menu_items();

// Set callback for menu actions
int set_context_menu_callback(MenuActionCallback callback);

// Show context menu at coordinates
int show_context_menu_at(int x, int y, SelectionData* selection);

#ifdef __cplusplus
}
#endif

#endif // CONTEXT_MENU_INJECTOR_H
