#!/usr/bin/env dart

import 'dart:io';
import 'lib/native/system_integration_safe.dart';

void main() async {
  print('🧪 Phase 3: Working Text Replacement Demo');
  print('==========================================\n');

  // Initialize system integration
  final systemIntegration = SystemIntegration();
  
  print('📋 Checking system compatibility...');
  if (!systemIntegration.isSystemCompatible()) {
    print('❌ System not compatible');
    exit(1);
  }
  
  print('✅ System compatible');
  print('🌍 Desktop Environment: ${systemIntegration.getDesktopEnvironment()}');
  
  print('\n🚀 Initializing system hooks...');
  
  // Initialize system integration
  bool initialized = await systemIntegration.initialize();
  if (!initialized) {
    print('❌ Failed to initialize system hooks');
    String? error = systemIntegration.getLastError();
    if (error != null) {
      print('   Error: $error');
    }
    exit(1);
  }
  
  print('✅ System hooks initialized');
  
  print('\n📋 Registering menu items...');
  
  // Register menu items directly
  final menuItems = [
    MenuItemInfo(
      id: 'translate',
      label: '🌐 AI Translate',
      operation: 'translate',
      aiInstruction: 'Translate this text to Spanish',
      enabled: true,
    ),
  ];
  
  bool registered = systemIntegration.registerMenuItems(menuItems);
  if (!registered) {
    print('❌ Failed to register menu items');
    exit(1);
  }
  
  print('✅ Registered ${menuItems.length} menu items');
  
  print('\n🎯 MANUAL WORKFLOW TEST:');
  print('=' * 50);
  print('This test will demonstrate the working components:');
  print('');
  print('STEP 1: Menu Registration ✅ (Already done)');
  print('STEP 2: Text Selection & Context Menu');
  print('   → Open any text editor');
  print('   → Type: "Hello world this is a test"');
  print('   → Select the text');
  print('   → Press Ctrl+Shift+M');
  print('   → You should see "🌐 AI Translate" menu');
  print('');
  print('STEP 3: Manual Text Replacement Test');
  print('   → We will now test text replacement directly');
  print('');
  
  // Test text replacement functionality
  print('🔧 Testing text replacement functionality...');
  
  // First, let's see if we can get current selection
  print('\n📝 Checking current selection...');
  final selection = systemIntegration.getCurrentSelection();
  
  if (selection != null && selection.text.isNotEmpty) {
    print('✅ Found selected text: "${selection.text}"');
    print('   Position: (${selection.x}, ${selection.y})');
    print('   App: ${selection.appName}');
    
    // Process the text
    String processedText = _processText(selection.text, 'translate');
    print('\n🤖 Processed text: "$processedText"');
    
    // Replace the text
    print('\n🔄 Attempting text replacement...');
    bool replaced = systemIntegration.replaceSelection(processedText);
    
    if (replaced) {
      print('✅ SUCCESS! Text should be replaced in your editor!');
      print('📍 Check your text editor - the selected text should have changed.');
    } else {
      print('❌ Text replacement failed');
    }
  } else {
    print('⚠️  No text currently selected');
    print('   Please select some text in an editor and run the test again');
  }
  
  print('\n🔄 CONTINUOUS MONITORING MODE:');
  print('   The system is now running...');
  print('   1. Select text in any application');
  print('   2. Press Ctrl+Shift+M to see the context menu');
  print('   3. Click the menu item');
  print('   4. The text should be replaced automatically!');
  print('');
  print('   📍 Note: Due to callback limitations, you won\'t see logs here,');
  print('   📍 but the replacement should work in the background.');
  print('');
  print('   Press Ctrl+C to exit');
  print('=' * 50);
  
  // Keep the program running
  try {
    while (true) {
      await Future.delayed(Duration(seconds: 2));
      
      // Optionally check for selection changes
      final currentSelection = systemIntegration.getCurrentSelection();
      if (currentSelection != null && currentSelection.text.isNotEmpty) {
        // Just update silently, don't spam logs
      }
    }
  } catch (e) {
    print('\n⚡ Received signal: $e');
  } finally {
    print('\n🧹 Cleaning up...');
    systemIntegration.cleanup();
    print('✅ Cleanup completed');
  }
}

String _processText(String text, String operation) {
  switch (operation) {
    case 'translate':
      return _simulateTranslation(text);
    case 'improve':
      return _simulateImprovement(text);
    case 'summarize':
      return _simulateSummary(text);
    default:
      return '[PROCESSED] $text';
  }
}

String _simulateTranslation(String text) {
  String result = text;
  
  // Simple word replacements
  result = result.replaceAll(RegExp(r'\bhello\b', caseSensitive: false), 'Hola');
  result = result.replaceAll(RegExp(r'\bworld\b', caseSensitive: false), 'mundo');
  result = result.replaceAll(RegExp(r'\btest\b', caseSensitive: false), 'prueba');
  result = result.replaceAll(RegExp(r'\bthis\b', caseSensitive: false), 'esto');
  result = result.replaceAll(RegExp(r'\bis\b', caseSensitive: false), 'es');
  
  return result != text ? result : '[ES] $text';
}

String _simulateImprovement(String text) {
  String improved = text.trim();
  if (improved.isNotEmpty) {
    improved = improved[0].toUpperCase() + improved.substring(1);
  }
  if (!improved.endsWith('.') && !improved.endsWith('!') && !improved.endsWith('?')) {
    improved += '.';
  }
  return improved;
}

String _simulateSummary(String text) {
  final words = text.split(' ');
  if (words.length <= 3) return text;
  final summaryWords = words.take((words.length / 2).ceil()).toList();
  return '${summaryWords.join(' ')}...';
}
