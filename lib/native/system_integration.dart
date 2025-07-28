import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Native library loading
final DynamicLibrary _nativeLib = () {
  if (Platform.isLinux) {
    // Try multiple paths for the native library
    final possiblePaths = [
      'lib/native/libs/libinstant_translator_native.so',  // Development mode
      './lib/native/libs/libinstant_translator_native.so', // Development mode with relative path
      'lib/libinstant_translator_native.so',              // Release bundle mode
      './lib/libinstant_translator_native.so',            // Release bundle with relative path
      'libinstant_translator_native.so',                  // System library path
    ];
    
    for (final path in possiblePaths) {
      try {
        return DynamicLibrary.open(path);
      } catch (e) {
        // Continue to next path
      }
    }
    
    throw UnsupportedError('Could not find libinstant_translator_native.so in any of: ${possiblePaths.join(', ')}');
  }
  throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
}();

// Native structures
final class SelectionData extends Struct {
  external Pointer<Utf8> text;
  @Int32()
  external int x;
  @Int32()
  external int y;
  external Pointer<Utf8> appName;
  @Int32()
  external int length;
}

final class MenuItem extends Struct {
  external Pointer<Utf8> id;
  external Pointer<Utf8> label;
  external Pointer<Utf8> operation;
  external Pointer<Utf8> aiInstruction;
  @Int32()
  external int enabled;
}

// Status codes
class StatusCode {
  static const int success = 0;
  static const int errorInit = -1;
  static const int errorNoSelection = -2;
  static const int errorNoDisplay = -3;
  static const int errorDbus = -4;
  static const int errorGtk = -5;
}

// Callback types
typedef SelectionCallbackNative = Void Function(Pointer<SelectionData>);
typedef MenuActionCallbackNative = Void Function(Pointer<Utf8>, Pointer<SelectionData>);

typedef SelectionCallbackDart = void Function(Pointer<SelectionData>);
typedef MenuActionCallbackDart = void Function(Pointer<Utf8>, Pointer<SelectionData>);

// Native function signatures
typedef InitSystemHooksNative = Int32 Function();
typedef InitSystemHooksDart = int Function();

typedef CleanupSystemHooksNative = Void Function();
typedef CleanupSystemHooksDart = void Function();

typedef RegisterContextMenuNative = Int32 Function(Pointer<MenuItem>, Int32);
typedef RegisterContextMenuDart = int Function(Pointer<MenuItem>, int);

typedef GetCurrentSelectionNative = Pointer<SelectionData> Function();
typedef GetCurrentSelectionDart = Pointer<SelectionData> Function();

typedef FreeSelectionDataNative = Void Function(Pointer<SelectionData>);
typedef FreeSelectionDataDart = void Function(Pointer<SelectionData>);

typedef ReplaceSelectionNative = Int32 Function(Pointer<Utf8>);
typedef ReplaceSelectionDart = int Function(Pointer<Utf8>);

typedef SetSelectionCallbackNative = Int32 Function(Pointer<NativeFunction<SelectionCallbackNative>>);
typedef SetSelectionCallbackDart = int Function(Pointer<NativeFunction<SelectionCallbackNative>>);

typedef SetMenuActionCallbackNative = Int32 Function(Pointer<NativeFunction<MenuActionCallbackNative>>);
typedef SetMenuActionCallbackDart = int Function(Pointer<NativeFunction<MenuActionCallbackNative>>);

typedef IsSystemCompatibleNative = Int32 Function();
typedef IsSystemCompatibleDart = int Function();

typedef GetDesktopEnvironmentNative = Pointer<Utf8> Function();
typedef GetDesktopEnvironmentDart = Pointer<Utf8> Function();

typedef GetLastErrorNative = Pointer<Utf8> Function();
typedef GetLastErrorDart = Pointer<Utf8> Function();

typedef FreeStringNative = Void Function(Pointer<Utf8>);
typedef FreeStringDart = void Function(Pointer<Utf8>);

// Native function bindings
final InitSystemHooksDart _initSystemHooks = _nativeLib
    .lookup<NativeFunction<InitSystemHooksNative>>('init_system_hooks')
    .asFunction();

final CleanupSystemHooksDart _cleanupSystemHooks = _nativeLib
    .lookup<NativeFunction<CleanupSystemHooksNative>>('cleanup_system_hooks')
    .asFunction();

final RegisterContextMenuDart _registerContextMenu = _nativeLib
    .lookup<NativeFunction<RegisterContextMenuNative>>('register_context_menu')
    .asFunction();

final GetCurrentSelectionDart _getCurrentSelection = _nativeLib
    .lookup<NativeFunction<GetCurrentSelectionNative>>('get_current_selection')
    .asFunction();

final FreeSelectionDataDart _freeSelectionData = _nativeLib
    .lookup<NativeFunction<FreeSelectionDataNative>>('free_selection_data')
    .asFunction();

final ReplaceSelectionDart _replaceSelection = _nativeLib
    .lookup<NativeFunction<ReplaceSelectionNative>>('replace_selection')
    .asFunction();

final SetSelectionCallbackDart _setSelectionCallback = _nativeLib
    .lookup<NativeFunction<SetSelectionCallbackNative>>('set_selection_callback')
    .asFunction();

final SetMenuActionCallbackDart _setMenuActionCallback = _nativeLib
    .lookup<NativeFunction<SetMenuActionCallbackNative>>('set_menu_action_callback')
    .asFunction();

final IsSystemCompatibleDart _isSystemCompatible = _nativeLib
    .lookup<NativeFunction<IsSystemCompatibleNative>>('is_system_compatible')
    .asFunction();

final GetDesktopEnvironmentDart _getDesktopEnvironment = _nativeLib
    .lookup<NativeFunction<GetDesktopEnvironmentNative>>('get_desktop_environment')
    .asFunction();

final GetLastErrorDart _getLastError = _nativeLib
    .lookup<NativeFunction<GetLastErrorNative>>('get_last_error')
    .asFunction();

final FreeStringDart _freeString = _nativeLib
    .lookup<NativeFunction<FreeStringNative>>('free_string')
    .asFunction();

// Dart wrapper classes
class SelectionInfo {
  final String text;
  final int x;
  final int y;
  final String appName;
  final int length;

  const SelectionInfo({
    required this.text,
    required this.x,
    required this.y,
    required this.appName,
    required this.length,
  });

  @override
  String toString() {
    return 'SelectionInfo(text: "$text", position: ($x, $y), app: "$appName", length: $length)';
  }
}

class MenuItemInfo {
  final String id;
  final String label;
  final String operation;
  final String aiInstruction;
  final bool enabled;

  const MenuItemInfo({
    required this.id,
    required this.label,
    required this.operation,
    required this.aiInstruction,
    required this.enabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'operation': operation,
      'aiInstruction': aiInstruction,
      'enabled': enabled,
    };
  }

  factory MenuItemInfo.fromJson(Map<String, dynamic> json) {
    return MenuItemInfo(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      operation: json['operation'] ?? '',
      aiInstruction: json['aiInstruction'] ?? '',
      enabled: json['enabled'] ?? false,
    );
  }
}

// Main system integration class
class SystemIntegration {
  static final SystemIntegration _instance = SystemIntegration._internal();
  factory SystemIntegration() => _instance;
  SystemIntegration._internal();

  // Callbacks
  void Function(SelectionInfo)? _onSelectionChanged;
  void Function(String menuId, SelectionInfo selection)? _onMenuAction;

  // Native callback wrappers
  late final Pointer<NativeFunction<SelectionCallbackNative>> _selectionCallbackPtr;
  late final Pointer<NativeFunction<MenuActionCallbackNative>> _menuActionCallbackPtr;

  bool _initialized = false;

  // Initialize the system integration
  Future<bool> initialize() async {
    if (_initialized) return true;

    // Check system compatibility first
    if (!isSystemCompatible()) {
      return false;
    }

    // Set up native callbacks
    _selectionCallbackPtr = Pointer.fromFunction<SelectionCallbackNative>(_onSelectionChangedNative);
    _menuActionCallbackPtr = Pointer.fromFunction<MenuActionCallbackNative>(_onMenuActionNative);

    // Initialize native system
    int result = _initSystemHooks();
    if (result != StatusCode.success) {
      return false;
    }

    // Set callbacks
    _setSelectionCallback(_selectionCallbackPtr);
    _setMenuActionCallback(_menuActionCallbackPtr);

    _initialized = true;
    return true;
  }

  // Cleanup system integration
  void cleanup() {
    if (!_initialized) return;

    _cleanupSystemHooks();
    _initialized = false;
  }

  // Check if system is compatible
  bool isSystemCompatible() {
    return _isSystemCompatible() == 1;
  }

  // Get desktop environment
  String getDesktopEnvironment() {
    final ptr = _getDesktopEnvironment();
    if (ptr == nullptr) return 'unknown';
    
    final result = ptr.toDartString();
    _freeString(ptr);
    return result;
  }

  // Get last error
  String? getLastError() {
    final ptr = _getLastError();
    if (ptr == nullptr) return null;
    
    final result = ptr.toDartString();
    _freeString(ptr);
    return result;
  }

  // Register menu items
  bool registerMenuItems(List<MenuItemInfo> menuItems) {
    if (!_initialized || menuItems.isEmpty) return false;

    // Allocate native menu items array
    final menuItemsPtr = calloc<MenuItem>(menuItems.length);

    try {
      for (int i = 0; i < menuItems.length; i++) {
        final item = menuItems[i];
        final nativeItem = (menuItemsPtr + i).ref;
        
        nativeItem.id = item.id.toNativeUtf8();
        nativeItem.label = item.label.toNativeUtf8();
        nativeItem.operation = item.operation.toNativeUtf8();
        nativeItem.aiInstruction = item.aiInstruction.toNativeUtf8();
        nativeItem.enabled = item.enabled ? 1 : 0;
      }

      int result = _registerContextMenu(menuItemsPtr, menuItems.length);
      return result == StatusCode.success;

    } finally {
      // Free allocated memory
      for (int i = 0; i < menuItems.length; i++) {
        final nativeItem = (menuItemsPtr + i).ref;
        calloc.free(nativeItem.id);
        calloc.free(nativeItem.label);
        calloc.free(nativeItem.operation);
        calloc.free(nativeItem.aiInstruction);
      }
      calloc.free(menuItemsPtr);
    }
  }

  // Get current selection
  SelectionInfo? getCurrentSelection() {
    if (!_initialized) return null;

    final selectionPtr = _getCurrentSelection();
    if (selectionPtr == nullptr) return null;

    try {
      final selection = selectionPtr.ref;
      return SelectionInfo(
        text: selection.text.toDartString(),
        x: selection.x,
        y: selection.y,
        appName: selection.appName.toDartString(),
        length: selection.length,
      );
    } finally {
      _freeSelectionData(selectionPtr);
    }
  }

  // Replace selected text
  bool replaceSelection(String newText) {
    if (!_initialized) return false;

    final textPtr = newText.toNativeUtf8();
    try {
      int result = _replaceSelection(textPtr);
      return result == StatusCode.success;
    } finally {
      calloc.free(textPtr);
    }
  }

  // Set selection change callback
  void setOnSelectionChanged(void Function(SelectionInfo)? callback) {
    _onSelectionChanged = callback;
  }

  // Set menu action callback
  void setOnMenuAction(void Function(String menuId, SelectionInfo selection)? callback) {
    _onMenuAction = callback;
  }

  // Native callback implementations
  static void _onSelectionChangedNative(Pointer<SelectionData> selectionPtr) {
    final instance = SystemIntegration._instance;
    if (instance._onSelectionChanged == null || selectionPtr == nullptr) return;

    try {
      final selection = selectionPtr.ref;
      final selectionInfo = SelectionInfo(
        text: selection.text.toDartString(),
        x: selection.x,
        y: selection.y,
        appName: selection.appName.toDartString(),
        length: selection.length,
      );

      instance._onSelectionChanged!(selectionInfo);
    } catch (e) {
      print('Error in selection callback: $e');
    }
  }

  static void _onMenuActionNative(Pointer<Utf8> menuIdPtr, Pointer<SelectionData> selectionPtr) {
    final instance = SystemIntegration._instance;
    if (instance._onMenuAction == null || menuIdPtr == nullptr || selectionPtr == nullptr) return;

    try {
      final menuId = menuIdPtr.toDartString();
      final selection = selectionPtr.ref;
      final selectionInfo = SelectionInfo(
        text: selection.text.toDartString(),
        x: selection.x,
        y: selection.y,
        appName: selection.appName.toDartString(),
        length: selection.length,
      );

      instance._onMenuAction!(menuId, selectionInfo);
    } catch (e) {
      print('Error in menu action callback: $e');
    }
  }
}
