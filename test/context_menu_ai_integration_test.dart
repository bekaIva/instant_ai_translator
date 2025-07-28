import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/services/gemini_ai_service.dart';
import '../lib/services/context_menu_config_service.dart';

void main() {
  group('Context Menu AI Integration Tests', () {
    late List<ContextMenuConfig> configs;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock shared preferences for testing
      const MethodChannel('plugins.flutter.io/shared_preferences')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      });
      
      configs = await ContextMenuConfigService.loadConfigs();
    });

    test('should process text with translate operation from config', () async {
      const text = 'Hello, how are you today?';
      final translateConfig = configs.firstWhere((c) => c.id == 'translate');
      
      try {
        final result = await GeminiAIService.processText(text, translateConfig.operation);
        print('Translate result: $result');
        
        expect(result.isNotEmpty, true);
        expect(result, isNot(contains('You are a professional translator')));
        expect(result, isNot(contains('Return only')));
      } catch (e) {
        print('Translate test failed: $e');
      }
    });

    test('should process text with improve operation from config', () async {
      const text = 'this text has bad grammar and no punctuation it needs improvement';
      final improveConfig = configs.firstWhere((c) => c.id == 'improve');
      
      try {
        final result = await GeminiAIService.processText(text, improveConfig.operation);
        print('Improve result: $result');
        
        expect(result.isNotEmpty, true);
        expect(result, isNot(contains('You are a professional editor')));
        expect(result, isNot(contains('Return only')));
        // Should have improved grammar/punctuation
        expect(result.contains('.') || result.contains('!') || result.contains('?'), true);
      } catch (e) {
        print('Improve test failed: $e');
      }
    });

    test('should process text with summarize operation from config', () async {
      const text = 'Artificial intelligence is a branch of computer science that aims to create intelligent machines that work and react like humans. Some of the activities computers with artificial intelligence are designed for include: speech recognition, learning, planning, and problem solving. AI has been the subject of much hype in recent years, but it also has practical applications in many industries including healthcare, finance, transportation, and entertainment.';
      final summarizeConfig = configs.firstWhere((c) => c.id == 'summarize');
      
      try {
        final result = await GeminiAIService.processText(text, summarizeConfig.operation);
        print('Summarize result: $result');
        
        expect(result.isNotEmpty, true);
        expect(result.length, lessThan(text.length));
        expect(result, isNot(contains('You are a professional summarizer')));
        expect(result, isNot(contains('Return only')));
      } catch (e) {
        print('Summarize test failed: $e');
      }
    });

    test('should handle system instruction properly', () async {
      final configs = await ContextMenuConfigService.loadConfigs();
      
      for (final config in configs) {
        expect(config.operation.startsWith('You are a professional'), true);
        expect(config.operation.contains('Return only'), true);
        expect(config.operation, isNot(contains('the following text')));
      }
    });
  });
}
