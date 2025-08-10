import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// =======================
// FFI data structures
// =======================
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

// Status codes (must match native)
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
typedef CleanupSystemHooksNative = Void Function();
typedef RegisterContextMenuNative = Int32 Function(Pointer<MenuItem>, Int32);
typedef GetCurrentSelectionNative = Pointer<SelectionData> Function();
typedef FreeSelectionDataNative = Void Function(Pointer<SelectionData>);
typedef ReplaceSelectionNative = Int32 Function(Pointer<Utf8>);
typedef SetSelectionCallbackNative = Int32 Function(Pointer<NativeFunction<SelectionCallbackNative>>);
typedef SetMenuActionCallbackNative = Int32 Function(Pointer<NativeFunction<MenuActionCallbackNative>>);
typedef IsSystemCompatibleNative = Int32 Function();
typedef GetDesktopEnvironmentNative = Pointer<Utf8> Function();
typedef GetLastErrorNative = Pointer<Utf8> Function();
typedef FreeStringNative = Void Function(Pointer<Utf8>);

// =======================
// Platform-safe bindings
// =======================

abstract class _NativeApi {
  int initSystemHooks();
  void cleanupSystemHooks();

  int registerContextMenu(Pointer<MenuItem> items, int count);
  Pointer<SelectionData> getCurrentSelection();
  void freeSelectionData(Pointer<SelectionData> data);

  int replaceSelection(Pointer<Utf8> newText);

  int setSelectionCallback(Pointer<NativeFunction<SelectionCallbackNative>> cb);
  int setMenuActionCallback(Pointer<NativeFunction<MenuActionCallbackNative>> cb);

  int isSystemCompatible();

  Pointer<Utf8> getDesktopEnvironment();
  Pointer<Utf8> getLastError();
  void freeString(Pointer<Utf8> str);
}

class _LinuxNativeApi implements _NativeApi {
  late final DynamicLibrary _lib;

  // Late-bound native functions (looked up once on first use)
  late final int Function() _initSystemHooks =
      _lib.lookup<NativeFunction<InitSystemHooksNative>>('init_system_hooks').asFunction();
  late final void Function() _cleanupSystemHooks =
      _lib.lookup<NativeFunction<CleanupSystemHooksNative>>('cleanup_system_hooks').asFunction();

  late final int Function(Pointer<MenuItem>, int) _registerContextMenu =
      _lib.lookup<NativeFunction<RegisterContextMenuNative>>('register_context_menu').asFunction();

  late final Pointer<SelectionData> Function() _getCurrentSelection =
      _lib.lookup<NativeFunction<GetCurrentSelectionNative>>('get_current_selection').asFunction();

  late final void Function(Pointer<SelectionData>) _freeSelectionData =
      _lib.lookup<NativeFunction<FreeSelectionDataNative>>('free_selection_data').asFunction();

  late final int Function(Pointer<Utf8>) _replaceSelection =
      _lib.lookup<NativeFunction<ReplaceSelectionNative>>('replace_selection').asFunction();

  late final int Function(Pointer<NativeFunction<SelectionCallbackNative>>) _setSelectionCallback =
      _lib.lookup<NativeFunction<SetSelectionCallbackNative>>('set_selection_callback').asFunction();

  late final int Function(Pointer<NativeFunction<MenuActionCallbackNative>>) _setMenuActionCallback =
      _lib.lookup<NativeFunction<SetMenuActionCallbackNative>>('set_menu_action_callback').asFunction();

  late final int Function() _isSystemCompatible =
      _lib.lookup<NativeFunction<IsSystemCompatibleNative>>('is_system_compatible').asFunction();

  late final Pointer<Utf8> Function() _getDesktopEnvironment =
      _lib.lookup<NativeFunction<GetDesktopEnvironmentNative>>('get_desktop_environment').asFunction();

  late final Pointer<Utf8> Function() _getLastError =
      _lib.lookup<NativeFunction<GetLastErrorNative>>('get_last_error').asFunction();

  late final void Function(Pointer<Utf8>) _freeString =
      _lib.lookup<NativeFunction<FreeStringNative>>('free_string').asFunction();

  _LinuxNativeApi() {
    _lib = _openLibrary();
  }

  DynamicLibrary _openLibrary() {
    final possiblePaths = <String>[
      'lib/native/libs/libinstant_translator_native.so', // Dev
      './lib/native/libs/libinstant_translator_native.so',
      'lib/libinstant_translator_native.so', // Bundle
      './lib/libinstant_translator_native.so',
      'libinstant_translator_native.so', // System
    ];
    for (final path in possiblePaths) {
      try {
        return DynamicLibrary.open(path);
      } catch (_) {
        // try next
      }
    }
    // As a last resort, try process lookup (if linked)
    try {
      return DynamicLibrary.process();
    } catch (_) {
      // ignore
    }
    throw UnsupportedError(
        'Could not find libinstant_translator_native.so in: ${possiblePaths.join(', ')}');
  }

  Pointer<T> _lookup<T extends NativeType>(String symbol) {
    return _lib.lookup<T>(symbol);
  }

  @override
  int initSystemHooks() => _initSystemHooks();

  @override
  void cleanupSystemHooks() => _cleanupSystemHooks();

  @override
  int registerContextMenu(Pointer<MenuItem> items, int count) =>
      _registerContextMenu(items, count);

  @override
  Pointer<SelectionData> getCurrentSelection() => _getCurrentSelection();

  @override
  void freeSelectionData(Pointer<SelectionData> data) => _freeSelectionData(data);

  @override
  int replaceSelection(Pointer<Utf8> newText) => _replaceSelection(newText);

  @override
  int setSelectionCallback(Pointer<NativeFunction<SelectionCallbackNative>> cb) =>
      _setSelectionCallback(cb);

  @override
  int setMenuActionCallback(Pointer<NativeFunction<MenuActionCallbackNative>> cb) =>
      _setMenuActionCallback(cb);

  @override
  int isSystemCompatible() => _isSystemCompatible();

  @override
  Pointer<Utf8> getDesktopEnvironment() => _getDesktopEnvironment();

  @override
  Pointer<Utf8> getLastError() => _getLastError();

  @override
  void freeString(Pointer<Utf8> str) => _freeString(str);
}

// No-op implementation for non-Linux platforms (Android, macOS, Windows, iOS, Web)
class _NoopNativeApi implements _NativeApi {
  @override
  void cleanupSystemHooks() {}

  @override
  void freeSelectionData(Pointer<SelectionData> data) {}

  @override
  void freeString(Pointer<Utf8> str) {}

  @override
  Pointer<SelectionData> getCurrentSelection() => Pointer.fromAddress(0);

  @override
  Pointer<Utf8> getDesktopEnvironment() => Pointer.fromAddress(0);

  @override
  Pointer<Utf8> getLastError() => Pointer.fromAddress(0);

  @override
  int initSystemHooks() => StatusCode.errorInit;

  @override
  int isSystemCompatible() => 0;

  @override
  int registerContextMenu(Pointer<MenuItem> items, int count) => StatusCode.errorInit;

  @override
  int replaceSelection(Pointer<Utf8> newText) => StatusCode.errorInit;

  @override
  int setMenuActionCallback(Pointer<NativeFunction<MenuActionCallbackNative>> cb) =>
      StatusCode.errorInit;

  @override
  int setSelectionCallback(Pointer<NativeFunction<SelectionCallbackNative>> cb) =>
      StatusCode.errorInit;
}

// Pick the proper backend once (import-safe)
final _NativeApi _api = Platform.isLinux ? _LinuxNativeApi() : _NoopNativeApi();

// =======================
// Dart-side convenience models
// =======================
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

// =======================
// Public SystemIntegration facade (platform-safe)
// =======================
class SystemIntegration {
  static final SystemIntegration _instance = SystemIntegration._internal();
  factory SystemIntegration() => _instance;
  SystemIntegration._internal();

  // Callbacks
  void Function(SelectionInfo)? _onSelectionChanged;
  void Function(String menuId, SelectionInfo selection)? _onMenuAction;

  // Native callback wrappers (allocated only if used and supported)
  late final Pointer<NativeFunction<SelectionCallbackNative>> _selectionCallbackPtr;
  late final Pointer<NativeFunction<MenuActionCallbackNative>> _menuActionCallbackPtr;

  bool _initialized = false;

  // Initialize the system integration
  Future<bool> initialize({bool enableCallbacks = false}) async {
    if (_initialized) return true;

    // Check system compatibility first (Linux-only returns 1)
    if (!isSystemCompatible()) {
      // Non-Linux platforms will return false here and we remain a no-op.
      return false;
    }

    final result = _api.initSystemHooks();
    if (result != StatusCode.success) {
      return false;
    }

    // Only set up callbacks if explicitly requested and safe
    if (enableCallbacks) {
      try {
        _selectionCallbackPtr =
            Pointer.fromFunction<SelectionCallbackNative>(_onSelectionChangedNative);
        _menuActionCallbackPtr =
            Pointer.fromFunction<MenuActionCallbackNative>(_onMenuActionNative);

        _api.setSelectionCallback(_selectionCallbackPtr);
        _api.setMenuActionCallback(_menuActionCallbackPtr);
        // ignore: avoid_print
        print('✅ Callbacks enabled');
      } catch (e) {
        // ignore: avoid_print
        print('⚠️  Callback setup failed: $e');
        // ignore: avoid_print
        print('   Continuing without callbacks');
      }
    } else {
      // ignore: avoid_print
      print('📋 Running without callbacks to avoid isolate issues');
    }

    _initialized = true;
    return true;
  }

  // Cleanup system integration
  void cleanup() {
    if (!_initialized) return;
    _api.cleanupSystemHooks();
    _initialized = false;
  }

  // Check if system is compatible (Linux returns 1; others 0)
  bool isSystemCompatible() {
    try {
      return _api.isSystemCompatible() == 1;
    } catch (_) {
      return false;
    }
  }

  // Get desktop environment (Linux only)
  String getDesktopEnvironment() {
    final ptr = _api.getDesktopEnvironment();
    if (ptr == nullptr) return 'unknown';
    final result = ptr.toDartString();
    _api.freeString(ptr);
    return result;
  }

  // Get last error (Linux only)
  String? getLastError() {
    final ptr = _api.getLastError();
    if (ptr == nullptr) return null;
    final result = ptr.toDartString();
    _api.freeString(ptr);
    return result;
  }

  // Register menu items (Linux only)
  bool registerMenuItems(List<MenuItemInfo> menuItems) {
    if (!_initialized || menuItems.isEmpty) return false;

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

      final result = _api.registerContextMenu(menuItemsPtr, menuItems.length);
      return result == StatusCode.success;
    } finally {
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

  // Get current selection (Linux only)
  SelectionInfo? getCurrentSelection() {
    if (!_initialized) return null;

    final selectionPtr = _api.getCurrentSelection();
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
      _api.freeSelectionData(selectionPtr);
    }
  }

  // Replace selected text (Linux only)
  bool replaceSelection(String newText) {
    if (!_initialized) return false;

    final textPtr = newText.toNativeUtf8();
    try {
      final result = _api.replaceSelection(textPtr);
      return result == StatusCode.success;
    } finally {
      calloc.free(textPtr);
    }
  }

  // Set selection change callback (Dart-side)
  void setOnSelectionChanged(void Function(SelectionInfo)? callback) {
    _onSelectionChanged = callback;
  }

  // Set menu action callback (Dart-side)
  void setOnMenuAction(void Function(String menuId, SelectionInfo selection)? callback) {
    _onMenuAction = callback;
  }

  // Native callback implementations (Linux-only)
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
      // ignore: avoid_print
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
      // ignore: avoid_print
      print('Error in menu action callback: $e');
    }
  }
}
