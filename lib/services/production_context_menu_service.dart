import 'dart:async';
import 'dart:io';
import '../native/system_integration_safe.dart';
import 'context_menu_config_service.dart';
import 'gemini_ai_service.dart';

class ContextMenuAction {
  final String menuId;
  final String originalText;
  final String processedText;
  final DateTime timestamp;
  final bool success;
  final String? error;

  ContextMenuAction({
    required this.menuId,
    required this.originalText,
    required this.processedText,
    required this.timestamp,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'originalText': originalText,
      'processedText': processedText,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'error': error,
    };
  }
}

class ProductionContextMenuService {
  static final ProductionContextMenuService _instance =
      ProductionContextMenuService._internal();
  factory ProductionContextMenuService() => _instance;
  ProductionContextMenuService._internal();

  final SystemIntegration _systemIntegration = SystemIntegration();

  // Stream controllers
  final _statusController = StreamController<String>.broadcast();
  final _actionController = StreamController<ContextMenuAction>.broadcast();
  final _logController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<String> get statusStream => _statusController.stream;
  Stream<ContextMenuAction> get actionStream => _actionController.stream;
  Stream<String> get logStream => _logController.stream;

  // Getter for initialization state
  bool get isInitialized => _initialized;

  // Current status
  String _currentStatus = 'Initializing...';
  String get currentStatus => _currentStatus;

  // Persistent storage for logs and actions
  final List<String> _logs = [];
  final List<ContextMenuAction> _actions = [];

  // Getters for persistent data
  List<String> get logs => List.unmodifiable(_logs);
  List<ContextMenuAction> get actions => List.unmodifiable(_actions);

  bool _processing = false;
  String?
  _lastProcessedAction; // Track last processed action to prevent duplicates
  bool _initialized = false;
  bool _monitoring = false;
  List<ContextMenuConfig> _activeConfigs = [];
  Timer? _monitoringTimer;

  // Initialize the service
  Future<bool> initialize() async {
    if (_initialized) {
      _addLog('⚡ Service already initialized, skipping re-initialization');
      _updateStatus('Ready');
      return true;
    }

    _updateStatus('Initializing...');
    _addLog('🚀 Initializing production context menu service...');

    try {
      // Load configurations
      final configs = await ContextMenuConfigService.getEnabledConfigs();
      _activeConfigs = configs;
      _addLog('📋 Loaded ${configs.length} enabled menu configurations');

      // Android path: use Process Text integration (no native FFI)
      if (Platform.isAndroid) {
        _addLog('📱 Android detected: using Process Text OS integration (no native FFI)');
        // Test Gemini AI connection
        _addLog('🔍 Testing Gemini AI connection...');
        final aiConnected = await GeminiAIService.testConnection();
        if (aiConnected) {
          _addLog('✅ Gemini AI connection successful');
        } else {
          _addLog('⚠️  Gemini AI connection failed - text processing may fail without valid API configuration');
        }

        _initialized = true;
        _monitoring = true; // Represent OS-level availability as "Active"
        _updateStatus('Ready (Android Process Text)');
        _addLog('✅ Android mode initialized (Process Text)');
        return true;
      }

      // Initialize system integration (Linux)
      final success = await _systemIntegration.initialize();
      if (!success) {
        _addLog('❌ Failed to initialize system integration');
        _updateStatus('Failed to initialize');
        return false;
      }

      // Test Gemini AI connection
      _addLog('🔍 Testing Gemini AI connection...');
      final aiConnected = await GeminiAIService.testConnection();
      if (aiConnected) {
        _addLog('✅ Gemini AI connection successful');
      } else {
        _addLog('⚠️  Gemini AI connection failed - text processing may fail without valid API configuration');
      }

      // Register menu items
      if (_activeConfigs.isNotEmpty) {
        await _registerMenuItems();
      } else {
        _addLog('⚠️  No enabled menu items to register');
      }

      _initialized = true;
      _updateStatus('Ready');
      _addLog('✅ Production context menu service initialized successfully');

      // Start monitoring for menu actions (polling approach)
      _startMonitoring();

      return true;
    } catch (e) {
      _addLog('❌ Initialization error: $e');
      _updateStatus('Error: $e');
      return false;
    }
  }

  // Register menu items with the native system
  Future<bool> _registerMenuItems() async {
    try {
      // Android uses the OS "Process Text" integration; no native registration needed.
      if (Platform.isAndroid) {
        _addLog('📱 Android: skipping native menu registration (Process Text integration)');
        _updateStatus('Ready (Android mode)');
        return true;
      }

      final menuItems = _activeConfigs
          .map(
            (config) => MenuItemInfo(
              id: config.id,
              label: config.label,
              operation: config.operation,
              aiInstruction: config.description,
              enabled: config.enabled,
            ),
          )
          .toList();

      bool registered = _systemIntegration.registerMenuItems(menuItems);
      if (registered) {
        _addLog('✅ Registered ${menuItems.length} menu items successfully');
        return true;
      } else {
        String? error = _systemIntegration.getLastError();
        _addLog('❌ Failed to register menu items: ${error ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      _addLog('❌ Error registering menu items: $e');
      return false;
    }
  }

  // Start monitoring for actions (file-based communication)
  void _startMonitoring() {
    if (_monitoring) return;
    _monitoring = true;

    _addLog('📡 Starting action monitoring (file-based)...');

    // Monitor for menu actions via file system
    _monitoringTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _checkForMenuActions();
    });
  }

  // Check for menu actions written to file by native code
  Future<void> _checkForMenuActions() async {
    if (_processing) return; // Prevent multiple concurrent processing

    try {
      final actionFile = File('/tmp/instant_translator_action.txt');
      if (await actionFile.exists()) {
        final content = await actionFile.readAsString();
        final parts = content.trim().split('\t\n');

        if (parts.length == 2) {
          final menuId = parts[0];
          final selectedText = parts[1];
          final actionKey = '$menuId:$selectedText';

          // Check if this is a duplicate action
          if (_lastProcessedAction == actionKey) {
            await actionFile.delete(); // Clean up duplicate
            return;
          }

          _processing = true; // Mark as processing
          _lastProcessedAction = actionKey; // Remember this action

          _addLog('📨 Received menu action from native: $menuId');

          // Clean up the action file FIRST to prevent reprocessing
          await actionFile.delete();

          // Process the action
          await handleMenuAction(menuId, selectedText);
        } else {
          // Invalid format, clean up file
          await actionFile.delete();
        }
      }
    } catch (e) {
      // Silently handle errors to avoid spam
    } finally {
      _processing = false; // Always reset processing flag
      // Clear last action after a delay to allow new actions
      Future.delayed(Duration(seconds: 2), () {
        _lastProcessedAction = null;
      });
    }
  }

  // Handle menu action (to be called when menu is clicked)
  Future<void> handleMenuAction(String menuId, String selectedText) async {
    final config = _activeConfigs.where((c) => c.id == menuId).firstOrNull;
    if (config == null) {
      _addLog('❌ Unknown menu action: $menuId');
      return;
    }

    _addLog('🎯 Processing menu action: ${config.label} on "${selectedText}"');

    try {
      // Process the text based on the operation
      String processedText = await _processText(selectedText, config.operation);

      // Replace the text in the active application
      bool success = _systemIntegration.replaceSelection(processedText);

      // Create action record
      final action = ContextMenuAction(
        menuId: menuId,
        originalText: selectedText,
        processedText: processedText,
        timestamp: DateTime.now(),
        success: success,
        error: success ? null : 'Text replacement failed',
      );

      if (success) {
        _addLog('✅ Successfully processed and replaced text');
      } else {
        String? error = _systemIntegration.getLastError();
        _addLog('❌ Failed to replace text: ${error ?? 'Unknown error'}');
      }

      // Store action persistently and emit to stream
      _addAction(action);
    } catch (e) {
      _addLog('❌ Error processing menu action: $e');

      final errorText = 'ERROR: ${e.toString()}';
      
      // Replace the text in the active application with error details
      bool success = _systemIntegration.replaceSelection(errorText);

      final action = ContextMenuAction(
        menuId: menuId,
        originalText: selectedText,
        processedText: errorText,
        timestamp: DateTime.now(),
        success: false, // Still mark as failed since AI processing failed
        error: e.toString(),
      );

      if (success) {
        _addLog('📝 Error details replaced in editor');
      } else {
        String? error = _systemIntegration.getLastError();
        _addLog('❌ Failed to replace text with error details: ${error ?? 'Unknown error'}');
      }

      _addAction(action);
    }
  }

  // Process text based on operation type
  Future<String> _processText(String text, String operation) async {
    _addLog('🤖 Processing text with Gemini AI...');

    try {
      // Use Gemini AI to process the text with the operation as system instruction
      final processedText = await GeminiAIService.processText(text, operation);
      _addLog('✅ Gemini AI processing completed successfully');
      return processedText;
    } catch (e) {
      _addLog('❌ Gemini AI processing failed: $e');
      
      // Re-throw the error to let the caller handle it
      rethrow;
    }
  }

  // Public method to process text without system integration (for reprocessing from activity monitor)
  Future<String> processTextOnly(String text, String operation) async {
    return await _processText(text, operation);
  }

  // Reload configurations and re-register menus
  Future<bool> reloadConfigurations() async {
    try {
      _addLog('🔄 Reloading menu configurations...');
      _activeConfigs = await ContextMenuConfigService.getEnabledConfigs();

      if (_initialized) {
        await _registerMenuItems();
      }

      _addLog('✅ Configurations reloaded successfully');
      return true;
    } catch (e) {
      _addLog('❌ Error reloading configurations: $e');
      return false;
    }
  }

  // Get current status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'monitoring': Platform.isAndroid ? true : _monitoring,
      'activeMenus': _activeConfigs.length,
      'systemCompatible': Platform.isAndroid ? true : _systemIntegration.isSystemCompatible(),
      'desktopEnvironment': Platform.isAndroid ? 'Android' : _systemIntegration.getDesktopEnvironment(),
      'aiService': GeminiAIService.getApiInfo(),
    };
  }

  // Get active configurations
  List<ContextMenuConfig> getActiveConfigurations() {
    return List.from(_activeConfigs);
  }

  // Test menu action (for UI testing)
  Future<void> testMenuAction(String menuId) async {
    try {
      // Get the configuration for this menu action
      final config = _activeConfigs.where((c) => c.id == menuId).firstOrNull;
      if (config == null) {
        _addLog('❌ Test failed: Unknown menu ID $menuId');
        return;
      }

      // Use sample text for testing
      const sampleText = "This is sample text for testing the AI processing functionality.";

      _addLog('🧪 Testing menu action: ${config.label} with sample text');

      // Process the test text using the actual AI operation
      final processedText = await _processText(sampleText, config.operation);

      // Create a test action record
      final action = ContextMenuAction(
        menuId: menuId,
        originalText: sampleText,
        processedText: processedText,
        timestamp: DateTime.now(),
        success: true,
      );

      // Store action persistently and emit to stream
      _addAction(action);

      _addLog('✅ Test completed: "$sampleText" → "$processedText"');
    } catch (e) {
      _addLog('❌ Test failed for menu $menuId: $e');

      // Add failed action record (only if not closed)
      if (!_actionController.isClosed) {
        final action = ContextMenuAction(
          menuId: menuId,
          originalText: "Test sample text",
          processedText: "ERROR: ${e.toString()}",
          timestamp: DateTime.now(),
          success: false,
          error: e.toString(),
        );
        _addAction(action);
      }
    }
  }

  // Add log entry
  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    print(logEntry); // Also print to console

    // Store in persistent list
    _logs.insert(0, logEntry);
    if (_logs.length > 100) {
      _logs.removeLast();
    }

    // Only add to stream if not closed
    if (!_logController.isClosed) {
      _logController.add(logEntry);
    }
  }

  // Helper method to safely update status
  void _updateStatus(String status) {
    _currentStatus = status; // Store current status
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  // Helper method to add actions persistently
  void _addAction(ContextMenuAction action) {
    // Store in persistent list
    _actions.insert(0, action);
    if (_actions.length > 50) {
      _actions.removeLast();
    }

    // Only add to stream if not closed
    if (!_actionController.isClosed) {
      _actionController.add(action);
    }
  }

  // Cleanup
  void dispose() {
    if (!_initialized) return; // Already disposed

    _monitoring = false;
    _monitoringTimer?.cancel();
    _systemIntegration.cleanup();

    // Close streams safely
    if (!_statusController.isClosed) _statusController.close();
    if (!_actionController.isClosed) _actionController.close();
    if (!_logController.isClosed) _logController.close();

    _initialized = false;
  }

  // Clear persistent data methods
  void clearActions() {
    _actions.clear();
  }

  void clearLogs() {
    _logs.clear();
  }

  void clearAllData() {
    clearActions();
    clearLogs();
  }
}
