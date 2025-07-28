#!/usr/bin/env dart

import 'dart:io';
import 'lib/native/system_integration.dart';

void main() async {
  print('🧪 Phase 3: Single Menu Item Test');
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
  
  // Set up callbacks
  systemIntegration.setOnSelectionChanged((selection) {
    print('📝 Text selected: "${selection.text}" at (${selection.x}, ${selection.y})');
    print('   App: ${selection.appName}');
  });
  
  systemIntegration.setOnMenuAction((menuId, selection) async {
    print('\n🎯 MENU ACTION TRIGGERED!');
    print('   Menu ID: $menuId');
    print('   Selected text: "${selection.text}"');
    print('   Processing...');
    
    // Simulate AI processing based on menu action
    String processedText;
    switch (menuId) {
      case 'translate':
        await Future.delayed(Duration(seconds: 1)); // Simulate processing time
        processedText = _simulateTranslation(selection.text);
        break;
      default:
        processedText = '[PROCESSED] ${selection.text}';
    }
    
    print('   🤖 Result: "$processedText"');
    
    // Replace the selected text
    bool replaced = systemIntegration.replaceSelection(processedText);
    print('   📝 Text replacement: ${replaced ? "SUCCESS ✅" : "FAILED ❌"}');
    
    if (replaced) {
      print('\n🎉 SUCCESS! The text was replaced in the external application!');
    }
  });
  
  print('\n📋 Registering single menu item...');
  
  // Register a single menu item for testing
  final menuItem = MenuItemInfo(
    id: 'translate',
    label: '🌐 AI Translate',
    operation: 'translate',
    aiInstruction: 'Translate this text to Spanish',
    enabled: true,
  );
  
  bool registered = systemIntegration.registerMenuItems([menuItem]);
  if (!registered) {
    print('❌ Failed to register menu item');
    exit(1);
  }
  
  print('✅ Registered menu item: ${menuItem.label}');
  
  print('\n🎯 System ready! Test the context menu:');
  print('   1. Open any text editor (VS Code, text editor, terminal)');
  print('   2. Type some text: "Hello world this is a test"');
  print('   3. Select the text with your mouse');
  print('   4. Press Ctrl+Shift+M');
  print('   5. Click "🌐 AI Translate" in the context menu');
  print('   6. Watch the text get replaced with a translation!');
  print('\n   📍 Expected: Text should change to something like "[EN→ES] Hello world..."');
  print('   📍 Check this terminal for processing logs');
  print('\n   Press Ctrl+C to exit\n');
  
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
  // Simple mock translation
  final lower = text.toLowerCase();
  
  if (lower.contains('hello')) {
    return text.replaceAll(RegExp(r'hello', caseSensitive: false), 'Hola');
  }
  if (lower.contains('world')) {
    return text.replaceAll(RegExp(r'world', caseSensitive: false), 'mundo');
  }
  if (lower.contains('good')) {
    return text.replaceAll(RegExp(r'good', caseSensitive: false), 'bueno');
  }
  if (lower.contains('test')) {
    return text.replaceAll(RegExp(r'test', caseSensitive: false), 'prueba');
  }
  
  // Default translation
  return '[EN→ES] $text';
}
