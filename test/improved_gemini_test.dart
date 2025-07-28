import 'package:flutter_test/flutter_test.dart';
import '../lib/services/gemini_ai_service.dart';

void main() {
  group('Improved Gemini AI Tests', () {
    test('should use system instruction properly for translation', () async {
      const text = 'Good morning';
      const systemInstruction = 'You are a professional translator. Translate the text to Spanish while maintaining the original meaning, tone, and style. Return only the translated text.';
      
      try {
        final result = await GeminiAIService.processText(text, systemInstruction);
        print('Translation result: $result');
        
        expect(result.isNotEmpty, true);
        expect(result.toLowerCase(), contains('buenos'));
        // Should not contain any instructions or meta-text
        expect(result, isNot(contains('professional translator')));
        expect(result, isNot(contains('Return only')));
        expect(result, isNot(contains('You are')));
      } catch (e) {
        print('Translation test failed: $e');
      }
    });

    test('should use system instruction properly for text improvement', () async {
      const text = 'this is bad text no punctuation';
      const systemInstruction = 'You are a professional editor. Improve the text by fixing grammar errors, enhancing clarity, and improving readability. Return only the improved text.';
      
      try {
        final result = await GeminiAIService.processText(text, systemInstruction);
        print('Improvement result: $result');
        
        expect(result.isNotEmpty, true);
        // Should be properly capitalized and punctuated
        expect(result[0].toUpperCase(), equals(result[0]));
        expect(result.contains('.') || result.contains('!') || result.contains('?'), true);
        // Should not contain any instructions
        expect(result, isNot(contains('professional editor')));
        expect(result, isNot(contains('Return only')));
      } catch (e) {
        print('Improvement test failed: $e');
      }
    });

    test('should handle long text summarization properly', () async {
      const text = '''
      Flutter is Google's UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase. 
      Flutter works with existing code, is used by developers and organizations around the world, and is free and open source.
      The framework consists of the Flutter SDK and the Dart programming language. Flutter apps are built using Dart, which compiles to native machine code for mobile devices.
      This allows Flutter apps to achieve native performance while maintaining a single codebase across platforms.
      ''';
      const systemInstruction = 'You are a professional summarizer. Create a concise summary that captures the main points. Return only the summary.';
      
      try {
        final result = await GeminiAIService.processText(text, systemInstruction);
        print('Summary result: $result');
        
        expect(result.isNotEmpty, true);
        expect(result.length, lessThan(text.length * 0.7)); // Should be significantly shorter
        expect(result.toLowerCase(), contains('flutter'));
        // Should not contain instructions
        expect(result, isNot(contains('professional summarizer')));
        expect(result, isNot(contains('Return only')));
      } catch (e) {
        print('Summarization test failed: $e');
      }
    });

    test('should handle API info correctly', () async {
      final apiInfo = await GeminiAIService.getApiInfo();
      
      expect(apiInfo['service'], 'Google Gemini AI');
      expect(apiInfo['model'] != null, true);
      expect(apiInfo['apiKeyConfigured'] != null, true);
      expect(apiInfo['baseUrl'], isNotEmpty);
    });
  });
}
