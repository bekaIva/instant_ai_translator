#ifndef TEXT_SELECTION_MONITOR_H
#define TEXT_SELECTION_MONITOR_H

#include "../include/instant_translator.h"

#ifdef __cplusplus
extern "C" {
#endif

// Initialize text selection monitoring
int init_text_selection_monitor();

// Cleanup text selection monitoring
void cleanup_text_selection_monitor();

// Get currently selected text
SelectionData* get_selected_text();

// Replace selected text
int replace_selected_text(const char* new_text);

// Replace text at specific coordinates
int replace_text_at_coords(const char* new_text, int x, int y);

// Set callback for selection changes
int set_text_selection_callback(SelectionCallback callback);

#ifdef __cplusplus
}
#endif

#endif // TEXT_SELECTION_MONITOR_H
