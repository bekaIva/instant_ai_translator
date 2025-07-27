#ifndef TEXT_REPLACEMENT_H
#define TEXT_REPLACEMENT_H

#include "../include/instant_translator.h"

#ifdef __cplusplus
extern "C" {
#endif

// Initialize text replacement system
int init_text_replacement();

// Cleanup text replacement system
void cleanup_text_replacement();

// Replace selected text with new text (advanced keyboard simulation)
int replace_selected_text_advanced(const char* new_text);

// Replace text using clipboard method
int replace_text_via_clipboard(const char* new_text);

// Click at coordinates and replace text
int replace_text_at_coordinates(const char* new_text, int x, int y);

#ifdef __cplusplus
}
#endif

#endif // TEXT_REPLACEMENT_H
