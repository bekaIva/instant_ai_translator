#include "text_replacement.h"
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <X11/keysym.h>
#include <gtk/gtk.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

// X11 display for keyboard simulation
static Display* display = NULL;

// Initialize text replacement system
int init_text_replacement() {
    display = XOpenDisplay(NULL);
    if (!display) {
        return STATUS_ERROR_NO_DISPLAY;
    }
    
    // Check if XTest extension is available
    int event_base, error_base, major_version, minor_version;
    if (!XTestQueryExtension(display, &event_base, &error_base, &major_version, &minor_version)) {
        XCloseDisplay(display);
        display = NULL;
        return STATUS_ERROR_INIT;
    }
    
    return STATUS_SUCCESS;
}

// Cleanup text replacement system
void cleanup_text_replacement() {
    if (display) {
        XCloseDisplay(display);
        display = NULL;
    }
}

// Send key combination
static void send_key_combo(unsigned int modifiers, KeySym key) {
    KeyCode keycode = XKeysymToKeycode(display, key);
    
    // Press modifier keys
    if (modifiers & ControlMask) {
        XTestFakeKeyEvent(display, XKeysymToKeycode(display, XK_Control_L), True, 0);
    }
    if (modifiers & ShiftMask) {
        XTestFakeKeyEvent(display, XKeysymToKeycode(display, XK_Shift_L), True, 0);
    }
    if (modifiers & Mod1Mask) {
        XTestFakeKeyEvent(display, XKeysymToKeycode(display, XK_Alt_L), True, 0);
    }
    
    // Press main key
    XTestFakeKeyEvent(display, keycode, True, 0);
    XTestFakeKeyEvent(display, keycode, False, 0);
    
    // Release modifier keys
    if (modifiers & Mod1Mask) {
        XTestFakeKeyEvent(display, XKeysymToKeycode(display, XK_Alt_L), False, 0);
    }
    if (modifiers & ShiftMask) {
        XTestFakeKeyEvent(display, XKeysymToKeycode(display, XK_Shift_L), False, 0);
    }
    if (modifiers & ControlMask) {
        XTestFakeKeyEvent(display, XKeysymToKeycode(display, XK_Control_L), False, 0);
    }
    
    XFlush(display);
}

// Type text using keyboard simulation
static void type_text(const char* text) {
    if (!text || !display) return;
    
    size_t len = strlen(text);
    for (size_t i = 0; i < len; i++) {
        char c = text[i];
        KeySym keysym = 0;
        unsigned int modifiers = 0;
        
        // Convert character to KeySym
        if (c >= 'a' && c <= 'z') {
            keysym = XK_a + (c - 'a');
        } else if (c >= 'A' && c <= 'Z') {
            keysym = XK_a + (c - 'A');
            modifiers = ShiftMask;
        } else if (c >= '0' && c <= '9') {
            keysym = XK_0 + (c - '0');
        } else {
            // Handle special characters
            switch (c) {
                case ' ': keysym = XK_space; break;
                case '\n': keysym = XK_Return; break;
                case '\t': keysym = XK_Tab; break;
                case '.': keysym = XK_period; break;
                case ',': keysym = XK_comma; break;
                case ';': keysym = XK_semicolon; break;
                case ':': keysym = XK_colon; break;
                case '!': keysym = XK_exclam; break;
                case '?': keysym = XK_question; break;
                case '"': keysym = XK_quotedbl; break;
                case '\'': keysym = XK_apostrophe; break;
                case '(': keysym = XK_parenleft; break;
                case ')': keysym = XK_parenright; break;
                case '[': keysym = XK_bracketleft; break;
                case ']': keysym = XK_bracketright; break;
                case '{': keysym = XK_braceleft; break;
                case '}': keysym = XK_braceright; break;
                case '-': keysym = XK_minus; break;
                case '+': keysym = XK_plus; break;
                case '=': keysym = XK_equal; break;
                case '_': keysym = XK_underscore; break;
                case '/': keysym = XK_slash; break;
                case '\\': keysym = XK_backslash; break;
                case '@': keysym = XK_at; break;
                case '#': keysym = XK_numbersign; break;
                case '$': keysym = XK_dollar; break;
                case '%': keysym = XK_percent; break;
                case '^': keysym = XK_asciicircum; break;
                case '&': keysym = XK_ampersand; break;
                case '*': keysym = XK_asterisk; break;
                default:
                    // Skip unsupported characters
                    continue;
            }
        }
        
        if (keysym != 0) {
            KeyCode keycode = XKeysymToKeycode(display, keysym);
            
            // Press modifier keys
            if (modifiers & ShiftMask) {
                XTestFakeKeyEvent(display, XKeysymToKeycode(display, XK_Shift_L), True, 0);
            }
            
            // Press and release main key
            XTestFakeKeyEvent(display, keycode, True, 0);
            XTestFakeKeyEvent(display, keycode, False, 0);
            
            // Release modifier keys
            if (modifiers & ShiftMask) {
                XTestFakeKeyEvent(display, XKeysymToKeycode(display, XK_Shift_L), False, 0);
            }
            
            // Small delay between keystrokes
            usleep(10000); // 10ms
        }
    }
    
    XFlush(display);
}

// Replace selected text with new text
int replace_selected_text_advanced(const char* new_text) {
    if (!new_text || !display) {
        return STATUS_ERROR_INIT;
    }
    
    // Method 1: Try Ctrl+A, then type (select all in current context)
    send_key_combo(ControlMask, XK_a);
    usleep(50000); // 50ms delay
    
    // Type the new text
    type_text(new_text);
    
    return STATUS_SUCCESS;
}

// Replace text using clipboard method (more reliable)
int replace_text_via_clipboard(const char* new_text) {
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
    
    // Select current text and paste
    send_key_combo(ControlMask, XK_a);  // Select all
    usleep(50000); // 50ms delay
    send_key_combo(ControlMask, XK_v);  // Paste
    
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
    
    return STATUS_SUCCESS;
}

// Click at coordinates and replace text
int replace_text_at_coordinates(const char* new_text, int x, int y) {
    if (!new_text || !display) {
        return STATUS_ERROR_INIT;
    }
    
    // Move mouse to coordinates and click
    XTestFakeMotionEvent(display, -1, x, y, 0);
    XTestFakeButtonEvent(display, 1, True, 0);   // Left mouse down
    XTestFakeButtonEvent(display, 1, False, 0);  // Left mouse up
    XFlush(display);
    
    // Give time for the click to register
    usleep(100000); // 100ms
    
    // Replace text using clipboard method
    return replace_text_via_clipboard(new_text);
}
