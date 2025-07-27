// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:instant_ai_translator/main.dart';

void main() {
  testWidgets('App starts with translator panel', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InstantTranslatorApp());

    // Verify that our app has the main components
    expect(find.text('AI Translator'), findsWidgets);
    expect(find.text('Translator'), findsOneWidget);
    expect(find.text('Enter text to translate...'), findsOneWidget);
  });

  testWidgets('Navigation sidebar works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InstantTranslatorApp());

    // Verify initial state
    expect(find.text('Translator'), findsOneWidget);
    
    // Tap on History
    await tester.tap(find.text('History'));
    await tester.pump();

    // Verify navigation worked
    expect(find.text('Translation History'), findsOneWidget);
    
    // Tap on Settings
    await tester.tap(find.text('Settings'));
    await tester.pump();

    // Verify navigation worked
    expect(find.text('Settings'), findsOneWidget);
  });
}
