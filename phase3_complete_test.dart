#!/usr/bin/env dart

import 'dart:io';
import 'lib/native/system_integration.dart';

void main() async {
  print('🧪 Phase 3: Complete Workflow Test');
  print('===================================\n');

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
  bool initialized = await systemIntegration.initialize();
  if (!initialized) {
    print('❌ Failed to initialize system hooks');
    final error = systemIntegration.getLastError();
    if (error != null) {
      print('   Error: $error');
    }
    exit(1);
  }
  
  print('✅ System hooks initialized');
  
  // Set up callbacks with detailed logging
  systemIntegration.setOnSelectionChanged((selection) {
    print('\n📝 TEXT SELECTION DETECTED:');
    print('   Text: "${selection.text}"');
    print('   Position: (${selection.x}, ${selection.y})');
    print('   App: ${selection.appName}');
    print('   Length: ${selection.length}');
  });
  
  systemIntegration.setOnMenuAction((menuId, selection) async {
    print('\n🎯 MENU ACTION TRIGGERED!');
    print('   ════════════════════════════════');
    print('   Menu ID: $menuId');
    print('   Selected text: "${selection.text}"');
    print('   From app: ${selection.appName}');
    print('   ════════════════════════════════');
    
    print('\n🤖 Processing with AI...');
    
    // Simulate AI processing based on menu action
    String processedText;
    await Future.delayed(Duration(milliseconds: 1500)); // Simulate processing time
    
    switch (menuId) {
      case 'translate':
        processedText = _simulateTranslation(selection.text);
        print('   🌐 Translation: "$processedText"');
        break;
      case 'improve':
        processedText = _simulateImprovement(selection.text);
        print('   ✨ Improvement: "$processedText"');
        break;
      case 'summarize':
        processedText = _simulateSummary(selection.text);
        print('   📝 Summary: "$processedText"');
        break;
      default:
        processedText = '[PROCESSED] ${selection.text}';
        print('   🔧 Processed: "$processedText"');
    }
    
    print('\n🔄 Attempting text replacement...');
    
    // Replace the selected text
    bool replaced = systemIntegration.replaceSelection(processedText);
    
    if (replaced) {
      print('   ✅ SUCCESS! Text replaced in external application!');
      print('   📍 Check your editor - the text should have changed!');
    } else {
      print('   ❌ FAILED to replace text');
      print('   📍 The text should still be selected in your editor');
    }
    
    print('\n' + '=' * 60);
  });
  
  print('\n📋 Registering menu items...');
  
  // Register multiple menu items for testing
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
      label: '✨ Improve Text',
      operation: 'improve',
      aiInstruction: 'Improve the grammar and clarity',
      enabled: true,
    ),
    MenuItemInfo(
      id: 'summarize',
      label: '📝 Summarize',
      operation: 'summarize',
      aiInstruction: 'Create a concise summary',
      enabled: true,
    ),
  ];
  
  bool registered = systemIntegration.registerMenuItems(menuItems);
  if (!registered) {
    print('❌ Failed to register menu items');
    exit(1);
  }
  
  print('✅ Registered ${menuItems.length} menu items:');
  for (final item in menuItems) {
    print('   - ${item.label} (${item.id})');
  }
  
  print('\n🎯 COMPLETE WORKFLOW TEST READY!');
  print('=' * 50);
  print('📋 Test Instructions:');
  print('   1. Open any text editor (VS Code, gedit, etc.)');
  print('   2. Type: "Hello world this is a test message"');
  print('   3. SELECT the text with your mouse');
  print('   4. Press Ctrl+Shift+M');
  print('   5. Choose one of the menu options:');
  print('      • 🌐 AI Translate');
  print('      • ✨ Improve Text');
  print('      • 📝 Summarize');
  print('   6. Watch this terminal for processing logs');
  print('   7. Check your editor - text should be replaced!');
  print('');
  print('🔍 Expected Results:');
  print('   - Menu appears with 3 options ✅');
  print('   - This terminal shows selection detection ✅');
  print('   - Processing logs appear after menu click ✅');
  print('   - Original text gets replaced in editor ✅');
  print('');
  print('📍 Watch this terminal for real-time feedback!');
  print('   Press Ctrl+C to exit when done testing');
  print('=' * 50);
  print('');
  
  // Keep the program running
  try {
    while (true) {
      await Future.delayed(Duration(milliseconds: 500));
    }
  } catch (e) {
    print('\n⚡ Received signal or error: $e');
  } finally {
    print('\n🧹 Cleaning up...');
    systemIntegration.cleanup();
    print('✅ Cleanup completed');
  }
}

String _simulateTranslation(String text) {
  String result = text;
  
  // Simple word replacements
  result = result.replaceAll(RegExp(r'\bhello\b', caseSensitive: false), 'Hola');
  result = result.replaceAll(RegExp(r'\bworld\b', caseSensitive: false), 'mundo');
  result = result.replaceAll(RegExp(r'\bgood\b', caseSensitive: false), 'bueno');
  result = result.replaceAll(RegExp(r'\btest\b', caseSensitive: false), 'prueba');
  result = result.replaceAll(RegExp(r'\bmessage\b', caseSensitive: false), 'mensaje');
  result = result.replaceAll(RegExp(r'\bthis\b', caseSensitive: false), 'esto');
  result = result.replaceAll(RegExp(r'\bis\b', caseSensitive: false), 'es');
  
  return result != text ? result : '[ES] $text';
}

String _simulateImprovement(String text) {
  String improved = text.trim();
  
  // Capitalize first letter
  if (improved.isNotEmpty) {
    improved = improved[0].toUpperCase() + improved.substring(1);
  }
  
  // Add period if missing
  if (!improved.endsWith('.') && !improved.endsWith('!') && !improved.endsWith('?')) {
    improved += '.';
  }
  
  // Fix double spaces
  improved = improved.replaceAll(RegExp(r'\s+'), ' ');
  
  return improved;
}

String _simulateSummary(String text) {
  final words = text.split(' ');
  if (words.length <= 3) {
    return text; // Too short to summarize
  }
  
  // Take first half of words as summary
  final summaryWords = words.take((words.length / 2).ceil()).toList();
  return '${summaryWords.join(' ')}...';
}
