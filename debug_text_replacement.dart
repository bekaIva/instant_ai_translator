#!/usr/bin/env dart

import 'dart:io';
import 'lib/native/system_integration_safe.dart';

void main() async {
  print('🔧 DEBUG: Text Replacement Test');
  print('================================\n');

  final systemIntegration = SystemIntegration();
  
  print('📋 Checking system compatibility...');
  if (!systemIntegration.isSystemCompatible()) {
    print('❌ System not compatible');
    exit(1);
  }
  print('✅ System compatible');
  
  print('🚀 Initializing system...');
  bool initialized = await systemIntegration.initialize(enableCallbacks: false);
  if (!initialized) {
    print('❌ Failed to initialize');
    exit(1);
  }
  print('✅ System initialized');
  
  print('\n🎯 STEP-BY-STEP DEBUGGING:');
  print('1. Open a text editor (gedit, kate, mousepad, etc.)');
  print('2. Type: "Hello world test"');
  print('3. SELECT the text');
  print('4. Press ENTER here to test replacement');
  
  stdin.readLineSync();
  
  print('\n🔍 Step 1: Getting current selection...');
  final selection = systemIntegration.getCurrentSelection();
  
  if (selection == null) {
    print('❌ No selection found!');
    print('   Make sure you have selected text in an editor');
    exit(1);
  }
  
  print('✅ Selection found:');
  print('   Text: "${selection.text}"');
  print('   Length: ${selection.length}');
  print('   Position: (${selection.x}, ${selection.y})');
  print('   App: ${selection.appName}');
  
  if (selection.text.trim().isEmpty) {
    print('❌ Selected text is empty!');
    exit(1);
  }
  
  print('\n🔍 Step 2: Processing text...');
  String processedText = _processText(selection.text);
  print('   Original: "${selection.text}"');
  print('   Processed: "$processedText"');
  
  print('\n🔍 Step 3: Attempting text replacement...');
  print('   This will try to replace the selected text...');
  
  // Add a small delay to ensure the selection is stable
  await Future.delayed(Duration(milliseconds: 500));
  
  bool replaced = systemIntegration.replaceSelection(processedText);
  
  if (replaced) {
    print('✅ replaceSelection() returned true');
    print('📍 Check your editor - text should have changed from:');
    print('   "${selection.text}" → "$processedText"');
  } else {
    print('❌ replaceSelection() returned false');
    
    // Get last error
    String? error = systemIntegration.getLastError();
    if (error != null) {
      print('   Error: $error');
    }
  }
  
  print('\n🔍 Step 4: Verify replacement...');
  print('   Check your text editor now.');
  print('   Did the text change? (y/n)');
  
  String? response = stdin.readLineSync();
  if (response?.toLowerCase() == 'y') {
    print('🎉 SUCCESS! Text replacement is working!');
  } else {
    print('❌ Text replacement failed.');
    print('   This could be due to:');
    print('   1. The editor doesn\'t support programmatic text replacement');
    print('   2. X11 clipboard/selection issues');
    print('   3. Timing issues with the selection');
    print('   4. Permission/security restrictions');
  }
  
  systemIntegration.cleanup();
}

String _processText(String text) {
  // Simple translation simulation
  String result = text;
  result = result.replaceAll(RegExp(r'\bhello\b', caseSensitive: false), 'Hola');
  result = result.replaceAll(RegExp(r'\bworld\b', caseSensitive: false), 'mundo');
  result = result.replaceAll(RegExp(r'\btest\b', caseSensitive: false), 'prueba');
  
  return result != text ? result : '[TRANSLATED] $text';
}
