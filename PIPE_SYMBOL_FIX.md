# Fix for Pipe Symbol Bug

## Problem
When text containing the pipe symbol `|` was selected and processed through the context menu, the text replacement would fail. This happened because the pipe symbol was used as a delimiter in the communication between the native code and Flutter.

## Root Cause
The issue was in the file-based communication format between native C++ code and Flutter:

1. **Native code** (`context_menu_injector.cpp`): Wrote actions to `/tmp/instant_translator_action.txt` using format: `menuId|selectedText`
2. **Flutter code** (`production_context_menu_service.dart`): Split the content by `|` to extract menuId and selectedText

When text contained pipe symbols (e.g., `"|"` or `text|with|pipes`), the split operation would create more than 2 parts, breaking the parsing logic.

## Solution
Changed the delimiter from pipe `|` to tab+newline `\t\n`:

### Files Modified:
1. **`native/src/context_menu_injector.cpp`** (line 132):
   - Changed: `fprintf(action_file, "%s|%s\n", menu_id, current_selection->text);`
   - To: `fprintf(action_file, "%s\t\n%s\n", menu_id, current_selection->text);`

2. **`lib/services/production_context_menu_service.dart`** (line 174):
   - Changed: `final parts = content.trim().split('|');`
   - To: `final parts = content.trim().split('\t\n');`

3. **`FEATURES_EXPLAINED.md`** (line 74):
   - Updated documentation to reflect the new format

## Testing
- Verified the fix works with various pipe symbol combinations:
  - Single pipe: `|`
  - Quoted pipe: `"|"`
  - Multiple pipes: `|||`
  - Text with pipes: `hello|world|test`
  - All cases now correctly process and replace text

## Result
✅ Text containing pipe symbols now processes and replaces correctly
✅ The success message "Successfully processed and replaced text" now appears for all text
✅ No regression for normal text without pipe symbols
