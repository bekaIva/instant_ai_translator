import 'dart:async';
import '../native/system_integration_safe.dart';

class NativeIntegrationService {
  static final NativeIntegrationService _instance = NativeIntegrationService._internal();
  factory NativeIntegrationService() => _instance;
  NativeIntegrationService._internal();

  SystemIntegration? _systemIntegration;
  bool _isInitialized = false;
  
  // Stream controllers for events
  final _selectionController = StreamController<SelectionInfo>.broadcast();
  final _menuActionController = StreamController<MenuActionEvent>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  // Streams
  Stream<SelectionInfo> get onSelectionChanged => _selectionController.stream;
  Stream<MenuActionEvent> get onMenuAction => _menuActionController.stream;
  Stream<String> get onStatusChanged => _statusController.stream;

  // Simple AI text processing function
  Future<String> processText(String text, String operation) async {
    _statusController.add('Processing text with operation: $operation');
    
    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
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
      case 'explain':
        result = _simulateExplanation(text);
        break;
      default:
        result = '[PROCESSED] $text';
    }
    
    _statusController.add('Text processing completed');
    return result;
  }

  String _simulateTranslation(String text) {
    // Simple mock translation
    if (text.toLowerCase().contains('hello')) {
      return text.replaceAll(RegExp(r'hello', caseSensitive: false), 'Hola');
    }
    if (text.toLowerCase().contains('good')) {
      return text.replaceAll(RegExp(r'good', caseSensitive: false), 'Bueno');
    }
    return '[EN→ES] $text';
  }

  String _simulateImprovement(String text) {
    // Simple text improvement
    String improved = text.trim();
    if (!improved.endsWith('.') && !improved.endsWith('!') && !improved.endsWith('?')) {
      improved += '.';
    }
    // Capitalize first letter
    if (improved.isNotEmpty) {
      improved = improved[0].toUpperCase() + improved.substring(1);
    }
    return improved;
  }

  String _simulateSummary(String text) {
    final words = text.split(' ');
    if (words.length <= 5) {
      return text; // Too short to summarize
    }
    // Take first few words as summary
    final summaryWords = words.take((words.length / 2).ceil()).toList();
    return '${summaryWords.join(' ')}...';
  }

  String _simulateExplanation(String text) {
    return 'This text says: "$text" - which appears to be discussing ${_getTopicGuess(text)}.';
  }

  String _getTopicGuess(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('technology') || lower.contains('computer') || lower.contains('software')) {
      return 'technology';
    }
    if (lower.contains('food') || lower.contains('eat') || lower.contains('cook')) {
      return 'food and cooking';
    }
    if (lower.contains('travel') || lower.contains('trip') || lower.contains('visit')) {
      return 'travel';
    }
    return 'general topics';
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _statusController.add('Initializing native system integration...');
      
      _systemIntegration = SystemIntegration();
      
      // Check compatibility
      if (!_systemIntegration!.isSystemCompatible()) {
        _statusController.add('❌ System not compatible with native integration');
        return false;
      }
      
      _statusController.add('✅ System compatible');
      
      // Initialize native system
      bool initialized = await _systemIntegration!.initialize();
      if (!initialized) {
        final error = _systemIntegration!.getLastError();
        _statusController.add('❌ Failed to initialize: ${error ?? "Unknown error"}');
        return false;
      }
      
      _statusController.add('✅ Native system initialized');
      
      // Set up callbacks
      _systemIntegration!.setOnSelectionChanged((selection) {
        _selectionController.add(selection);
      });
      
      _systemIntegration!.setOnMenuAction((menuId, selection) async {
        final event = MenuActionEvent(menuId, selection);
        _menuActionController.add(event);
        
        // Process the text
        try {
          final processedText = await processText(selection.text, menuId);
          
          // Replace the selected text
          bool replaced = _systemIntegration!.replaceSelection(processedText);
          _statusController.add(replaced ? 
            '✅ Text replaced successfully' : 
            '❌ Failed to replace text');
        } catch (e) {
          _statusController.add('❌ Error processing text: $e');
        }
      });
      
      // Register a single menu item for testing
      await registerSingleMenuItem();
      
      _isInitialized = true;
      _statusController.add('🚀 System ready! Select text and press Ctrl+Shift+M');
      return true;
      
    } catch (e) {
      _statusController.add('❌ Initialization error: $e');
      return false;
    }
  }

  Future<bool> registerSingleMenuItem() async {
    if (_systemIntegration == null) return false;
    
    final menuItem = MenuItemInfo(
      id: 'translate',
      label: '🌐 AI Translate',
      operation: 'translate', 
      aiInstruction: 'Translate this text to Spanish',
      enabled: true,
    );
    
    bool registered = _systemIntegration!.registerMenuItems([menuItem]);
    if (registered) {
      _statusController.add('✅ Registered menu item: ${menuItem.label}');
    } else {
      _statusController.add('❌ Failed to register menu item');
    }
    
    return registered;
  }

  Future<bool> registerCustomMenuItems(List<MenuItemInfo> items) async {
    if (_systemIntegration == null) return false;
    
    bool registered = _systemIntegration!.registerMenuItems(items);
    if (registered) {
      _statusController.add('✅ Registered ${items.length} menu items');
    } else {
      _statusController.add('❌ Failed to register menu items');
    }
    
    return registered;
  }

  void dispose() {
    _systemIntegration?.cleanup();
    _selectionController.close();
    _menuActionController.close();
    _statusController.close();
    _isInitialized = false;
  }

  SelectionInfo? getCurrentSelection() {
    return _systemIntegration?.getCurrentSelection();
  }

  String getDesktopEnvironment() {
    return _systemIntegration?.getDesktopEnvironment() ?? 'unknown';
  }
}

class MenuActionEvent {
  final String menuId;
  final SelectionInfo selection;
  
  const MenuActionEvent(this.menuId, this.selection);
  
  @override
  String toString() => 'MenuActionEvent(menuId: $menuId, selection: ${selection.text})';
}
