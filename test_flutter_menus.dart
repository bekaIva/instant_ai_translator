#!/usr/bin/env dart

import 'dart:io';
import 'lib/native/system_integration.dart';

void main() async {
  print('🧪 Testing Flutter Menu Registration');
  print('=====================================\n');

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
  });
  
  systemIntegration.setOnMenuAction((menuId, selection) {
    print('🎯 Menu action: $menuId for text: "${selection.text}"');
    
    // Simulate AI processing
    String result;
    switch (menuId) {
      case 'translate':
        result = '[TRANSLATED] ${selection.text}';
        break;
      case 'improve':
        result = '[IMPROVED] ${selection.text}';
        break;
      case 'summarize':
        result = '[SUMMARY] ${selection.text}';
        break;
      default:
        result = '[PROCESSED] ${selection.text}';
    }
    
    print('🤖 AI Result: $result');
    
    // Replace the text
    bool replaced = systemIntegration.replaceSelection(result);
    print('📝 Text replacement: ${replaced ? "SUCCESS" : "FAILED"}');
  });
  
  print('\n📋 Registering custom menu items from Flutter...');
  
  // Register custom menu items
  final menuItems = [
    MenuItemInfo(
      id: 'translate',
      label: '🌐 Translate to English',
      operation: 'translate',
      aiInstruction: 'Translate this text to English',
      enabled: true,
    ),
    MenuItemInfo(
      id: 'improve',
      label: '✨ Improve Writing',
      operation: 'improve',
      aiInstruction: 'Improve the grammar and clarity of this text',
      enabled: true,
    ),
    MenuItemInfo(
      id: 'summarize',
      label: '📝 Summarize',
      operation: 'summarize',
      aiInstruction: 'Create a concise summary of this text',
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
  
  print('\n🎯 System ready! Test the context menu:');
  print('   1. Select text in any application');
  print('   2. Press Ctrl+Shift+M to show context menu');
  print('   3. You should see the 3 Flutter-registered menu items');
  print('   4. Press Ctrl+C to exit\n');
  
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
