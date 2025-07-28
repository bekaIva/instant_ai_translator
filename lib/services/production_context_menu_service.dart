import 'dart:async';
import 'dart:io';
import '../native/system_integration_safe.dart';
import 'context_menu_config_service.dart';

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

      // Initialize system integration
      final success = await _systemIntegration.initialize();
      if (!success) {
        _addLog('❌ Failed to initialize system integration');
        _updateStatus('Failed to initialize');
        return false;
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
    try {
      final actionFile = File('/tmp/instant_translator_action.txt');
      if (await actionFile.exists()) {
        final content = await actionFile.readAsString();
        final parts = content.trim().split('|');

        if (parts.length == 2) {
          final menuId = parts[0];
          final selectedText = parts[1];

          _addLog('📨 Received menu action from native: $menuId');

          // Process the action
          await handleMenuAction(menuId, selectedText);

          // Clean up the action file
          await actionFile.delete();
        }
      }
    } catch (e) {
      // Silently handle errors to avoid spam
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

      // Emit action event
      _actionController.add(action);
    } catch (e) {
      _addLog('❌ Error processing menu action: $e');

      final action = ContextMenuAction(
        menuId: menuId,
        originalText: selectedText,
        processedText: selectedText,
        timestamp: DateTime.now(),
        success: false,
        error: e.toString(),
      );

      _actionController.add(action);
    }
  }

  // Process text based on operation type
  Future<String> _processText(String text, String operation) async {
    _addLog('🤖 Processing text with operation: $operation');

    // Simulate processing delay
    await Future.delayed(Duration(milliseconds: 200));

    switch (operation) {
      case 'translate':
        return _translateText(text);
      case 'improve':
        return _improveText(text);
      case 'summarize':
        return _summarizeText(text);
      case 'explain':
        return _explainText(text);
      case 'rewrite':
        return _rewriteText(text);
      case 'expand':
        return _expandText(text);
      default:
        return '[PROCESSED] $text';
    }
  }

  // Simple text processing functions (to be replaced with actual AI later)
  String _translateText(String text) {
    // Simple Spanish translation simulation
    final translations = <String, String>{
      'hello': 'hola',
      'world': 'mundo',
      'good': 'bueno',
      'bad': 'malo',
      'yes': 'sí',
      'no': 'no',
      'thank you': 'gracias',
      'please': 'por favor',
      'how are you': 'cómo estás',
      'goodbye': 'adiós',
    };

    String result = text.toLowerCase();
    for (final entry in translations.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result != text.toLowerCase() ? result : '🌐 $text (ES)';
  }

  String _improveText(String text) {
    String improved = text.trim();

    // Capitalize first letter
    if (improved.isNotEmpty) {
      improved = improved[0].toUpperCase() + improved.substring(1);
    }

    // Fix common contractions
    improved = improved.replaceAll('cant', "can't");
    improved = improved.replaceAll('wont', "won't");
    improved = improved.replaceAll('dont', "don't");
    improved = improved.replaceAll('im', "I'm");
    improved = improved.replaceAll('youre', "you're");

    // Remove multiple spaces
    improved = improved.replaceAll(RegExp(r'\s+'), ' ');

    // Add punctuation if missing
    if (!improved.endsWith('.') &&
        !improved.endsWith('!') &&
        !improved.endsWith('?')) {
      improved += '.';
    }

    return improved;
  }

  String _summarizeText(String text) {
    final words = text.split(' ');
    if (words.length <= 10) return text;

    // Take first 40% of words and add summary indicator
    final summaryWords = words.take((words.length * 0.4).ceil()).toList();
    return '📝 ${summaryWords.join(' ')}... (summary)';
  }

  String _explainText(String text) {
    // Simple explanation template
    return '💡 Explanation: "$text" refers to a concept that can be understood as... (This would be a detailed AI-generated explanation)';
  }

  String _rewriteText(String text) {
    // Simple rewriting examples
    final rewrites = <String, String>{
      'good': 'excellent',
      'bad': 'poor',
      'big': 'large',
      'small': 'tiny',
      'fast': 'quick',
      'slow': 'sluggish',
    };

    String result = text;
    for (final entry in rewrites.entries) {
      result = result.replaceAll(
        RegExp(entry.key, caseSensitive: false),
        entry.value,
      );
    }

    return result != text ? result : '🔄 $text (rewritten)';
  }

  String _expandText(String text) {
    // Simple expansion
    return '📈 $text (with additional context and detailed explanations that provide comprehensive understanding of the topic)';
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
      'monitoring': _monitoring,
      'activeMenus': _activeConfigs.length,
      'systemCompatible': _systemIntegration.isSystemCompatible(),
      'desktopEnvironment': _systemIntegration.getDesktopEnvironment(),
    };
  }

  // Get active configurations
  List<ContextMenuConfig> getActiveConfigurations() {
    return List.from(_activeConfigs);
  }

  // Test menu action (for UI testing)
  Future<void> testMenuAction(String menuId) async {
    try {
      // Use sample text for testing instead of trying to get current selection
      // which can cause issues when called from Flutter UI context
      const sampleText = "This is sample text for testing the menu action.";

      _addLog('🧪 Testing menu action: $menuId with sample text');

      // Process the test text
      final processedText = await _processText(menuId, sampleText);

      // Create a test action record
      final action = ContextMenuAction(
        menuId: menuId,
        originalText: sampleText,
        processedText: processedText,
        timestamp: DateTime.now(),
        success: true,
      );

      // Add to action stream for UI feedback (only if not closed)
      if (!_actionController.isClosed) {
        _actionController.add(action);
      }

      _addLog('✅ Test completed: "$sampleText" → "$processedText"');
    } catch (e) {
      _addLog('❌ Test failed for menu $menuId: $e');

      // Add failed action record (only if not closed)
      if (!_actionController.isClosed) {
        final action = ContextMenuAction(
          menuId: menuId,
          originalText: "Test sample text",
          processedText: "Test failed: $e",
          timestamp: DateTime.now(),
          success: false,
        );
        _actionController.add(action);
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
}
