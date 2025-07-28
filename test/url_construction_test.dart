import 'package:flutter_test/flutter_test.dart';
import '../lib/services/ai_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('URL Construction Tests', () {
    test('should construct correct API URLs', () {
      // Test model name formatting
      const modelName = 'gemini-1.5-flash';
      const fullModelName = 'models/gemini-1.5-flash';
      
      expect(AISettingsService.getFullModelName(modelName), fullModelName);
      expect(AISettingsService.getSimpleModelName(fullModelName), modelName);
      
      // Test URL construction
      const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
      const expectedUrl = '$baseUrl/models/gemini-1.5-flash:generateContent';
      
      // This simulates how the URL is constructed in GeminiAIService
      final constructedUrl = '$baseUrl/${AISettingsService.getFullModelName(modelName)}:generateContent';
      
      expect(constructedUrl, expectedUrl);
      print('✅ Correct URL: $constructedUrl');
    });

    test('should handle models that already have prefix', () {
      const modelWithPrefix = 'models/gemini-1.5-pro';
      const modelWithoutPrefix = 'gemini-1.5-pro';
      
      // Both should result in the same full model name
      expect(AISettingsService.getFullModelName(modelWithPrefix), 'models/gemini-1.5-pro');
      expect(AISettingsService.getFullModelName(modelWithoutPrefix), 'models/gemini-1.5-pro');
      
      // Both should result in the same simple model name
      expect(AISettingsService.getSimpleModelName(modelWithPrefix), 'gemini-1.5-pro');
      expect(AISettingsService.getSimpleModelName(modelWithoutPrefix), 'gemini-1.5-pro');
    });
  });
}
