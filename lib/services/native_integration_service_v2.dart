import 'dart:async';
import '../native/system_integration_safe.dart';

class NativeIntegrationService {
  static final NativeIntegrationService _instance = NativeIntegrationService._internal();
  factory NativeIntegrationService() => _instance;
  NativeIntegrationService._internal();

  final SystemIntegration _systemIntegration = SystemIntegration();
  
  // Stream controllers for events
  final _statusController = StreamController<String>.broadcast();
  final _selectionController = StreamController<SelectionInfo?>.broadcast();
  final _menuActionController = StreamController<MenuAction>.broadcast();
  final _logController = StreamController<String>.broadcast();
  
  // Getters for streams
  Stream<String> get statusStream => _statusController.stream;
  Stream<SelectionInfo?> get selectionStream => _selectionController.stream;
  Stream<MenuAction> get menuActionStream => _menuActionController.stream;
  Stream<String> get logStream => _logController.stream;

  bool _initialized = false;
  bool _monitoring = false;
  SelectionInfo? _lastSelection;
  Timer? _monitoringTimer;

  // Initialize the native integration
  Future<bool> initialize() async {
    if (_initialized) return true;

    _addLog('🚀 Initializing native integration...');
    _statusController.add('Initializing...');

    try {
      // Initialize without problematic callbacks
      bool success = await _systemIntegration.initialize(enableCallbacks: false);
      if (!success) {
        String? error = _systemIntegration.getLastError();
        _addLog('❌ Failed to initialize: ${error ?? 'Unknown error'}');
        _statusController.add('Failed to initialize');
        return false;
      }

      // Register menu items
      final menuItems = [
        MenuItemInfo(
          id: 'translate',
          label: '🌐 AI Translate',
          operation: 'translate',
          aiInstruction: 'Translate this text to Spanish',
          enabled: true,
        ),
        MenuItemInfo(
          id: 'improve',
          label: '✨ AI Improve',
          operation: 'improve',
          aiInstruction: 'Improve the grammar and style of this text',
          enabled: true,
        ),
        MenuItemInfo(
          id: 'summarize',
          label: '📝 AI Summarize',
          operation: 'summarize',
          aiInstruction: 'Summarize this text concisely',
          enabled: true,
        ),
      ];

      bool registered = _systemIntegration.registerMenuItems(menuItems);
      if (!registered) {
        _addLog('❌ Failed to register menu items');
        _statusController.add('Failed to register menus');
        return false;
      }

      _addLog('✅ Registered ${menuItems.length} menu items');
      _initialized = true;
      _statusController.add('Ready');
      
      // Start monitoring
      _startMonitoring();
      
      return true;
    } catch (e) {
      _addLog('❌ Initialization error: $e');
      _statusController.add('Error: $e');
      return false;
    }
  }

  // Start monitoring for selection changes and menu actions
  void _startMonitoring() {
    if (_monitoring) return;
    _monitoring = true;
    
    _addLog('📡 Starting monitoring for selection changes...');
    
    // Poll for selection changes every 500ms
    _monitoringTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _checkSelectionChanges();
    });
  }

  void _checkSelectionChanges() {
    try {
      final currentSelection = _systemIntegration.getCurrentSelection();
      
      // Only update if selection actually changed
      if (_hasSelectionChanged(currentSelection, _lastSelection)) {
        _lastSelection = currentSelection;
        _selectionController.add(currentSelection);
        
        if (currentSelection != null && currentSelection.text.isNotEmpty) {
          _addLog('📝 Selection: "${currentSelection.text}" (${currentSelection.length} chars)');
        }
      }
    } catch (e) {
      // Silently handle errors to avoid spam
    }
  }

  bool _hasSelectionChanged(SelectionInfo? current, SelectionInfo? last) {
    if (current == null && last == null) return false;
    if (current == null || last == null) return true;
    return current.text != last.text || 
           current.x != last.x || 
           current.y != last.y ||
           current.appName != last.appName;
  }

  // Process text with AI simulation
  Future<String> processText(String text, String operation) async {
    _addLog('🤖 Processing text with operation: $operation');
    
    // Simulate AI processing delay
    await Future.delayed(Duration(milliseconds: 300));
    
    String result;
    switch (operation) {
      case 'translate':
        result = _simulateTranslation(text);
        break;
      case 'improve':
        result = _simulateImprovement(text);
        break;
      case 'summarize':
        result = _simulateSummary(text);
        break;
      default:
        result = '[PROCESSED] $text';
    }
    
    _addLog('✅ Processed: "$text" → "$result"');
    return result;
  }

  // Replace text in the currently active application
  Future<bool> replaceText(String newText) async {
    try {
      _addLog('🔄 Replacing text with: "$newText"');
      bool success = _systemIntegration.replaceSelection(newText);
      
      if (success) {
        _addLog('✅ Text replacement successful!');
        return true;
      } else {
        String? error = _systemIntegration.getLastError();
        _addLog('❌ Text replacement failed: ${error ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      _addLog('❌ Text replacement error: $e');
      return false;
    }
  }

  // Complete workflow: process and replace text
  Future<bool> processAndReplace(String text, String operation) async {
    try {
      // Process text
      String processedText = await processText(text, operation);
      
      // Replace text
      bool success = await replaceText(processedText);
      
      if (success) {
        // Emit menu action event
        _menuActionController.add(MenuAction(
          menuId: operation,
          originalText: text,
          processedText: processedText,
          success: true,
        ));
      }
      
      return success;
    } catch (e) {
      _addLog('❌ Process and replace error: $e');
      return false;
    }
  }

  // Get system information
  Map<String, dynamic> getSystemInfo() {
    return {
      'compatible': _systemIntegration.isSystemCompatible(),
      'desktop': _systemIntegration.getDesktopEnvironment(),
      'initialized': _initialized,
      'monitoring': _monitoring,
    };
  }

  // Get current selection
  SelectionInfo? getCurrentSelection() {
    return _systemIntegration.getCurrentSelection();
  }

  // Add log entry
  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    print(logEntry); // Also print to console
    _logController.add(logEntry);
  }

  // AI simulation methods
  String _simulateTranslation(String text) {
    String result = text;
    
    // Simple word replacements for Spanish translation
    final translations = {
      RegExp(r'\bhello\b', caseSensitive: false): 'Hola',
      RegExp(r'\bworld\b', caseSensitive: false): 'mundo',
      RegExp(r'\btest\b', caseSensitive: false): 'prueba',
      RegExp(r'\bthis\b', caseSensitive: false): 'esto',
      RegExp(r'\bis\b', caseSensitive: false): 'es',
      RegExp(r'\bthe\b', caseSensitive: false): 'el',
      RegExp(r'\band\b', caseSensitive: false): 'y',
      RegExp(r'\bwith\b', caseSensitive: false): 'con',
      RegExp(r'\bfor\b', caseSensitive: false): 'para',
      RegExp(r'\bgood\b', caseSensitive: false): 'bueno',
      RegExp(r'\bthank you\b', caseSensitive: false): 'gracias',
    };
    
    for (final entry in translations.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    
    return result != text ? result : '(ES) $text';
  }

  String _simulateImprovement(String text) {
    String improved = text.trim();
    
    // Capitalize first letter
    if (improved.isNotEmpty) {
      improved = improved[0].toUpperCase() + improved.substring(1);
    }
    
    // Add punctuation if missing
    if (!improved.endsWith('.') && !improved.endsWith('!') && !improved.endsWith('?')) {
      improved += '.';
    }
    
    // Simple improvements
    improved = improved.replaceAll(RegExp(r'\s+'), ' '); // Multiple spaces to single
    improved = improved.replaceAll('cant', "can't");
    improved = improved.replaceAll('wont', "won't");
    improved = improved.replaceAll('dont', "don't");
    
    return improved;
  }

  String _simulateSummary(String text) {
    final words = text.split(' ');
    if (words.length <= 5) return text;
    
    // Take first half of words and add ellipsis
    final summaryWords = words.take((words.length / 2).ceil()).toList();
    return '${summaryWords.join(' ')}...';
  }

  // Cleanup
  void dispose() {
    _monitoring = false;
    _monitoringTimer?.cancel();
    _systemIntegration.cleanup();
    _statusController.close();
    _selectionController.close();
    _menuActionController.close();
    _logController.close();
    _initialized = false;
  }
}

// Data classes
class MenuAction {
  final String menuId;
  final String originalText;
  final String processedText;
  final bool success;

  MenuAction({
    required this.menuId,
    required this.originalText,
    required this.processedText,
    required this.success,
  });
}
