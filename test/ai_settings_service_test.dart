import 'package:flutter_test/flutter_test.dart';
import '../lib/services/ai_settings_service.dart';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Settings Service Tests', () {
    test('should create and save AI settings', () async {
      const testSettings = AISettings(
        provider: 'google',
        apiKey: 'test_api_key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        model: 'gemini-1.5-flash',
        enabled: true,
      );

      // Test saving
      final saveResult = await AISettingsService.saveSettings(testSettings);
      expect(saveResult, true);

      // Test loading
      final loadedSettings = await AISettingsService.loadSettings();
      expect(loadedSettings, isNotNull);
      expect(loadedSettings!.provider, testSettings.provider);
      expect(loadedSettings.apiKey, testSettings.apiKey);
      expect(loadedSettings.model, testSettings.model);
      expect(loadedSettings.enabled, testSettings.enabled);
    });

    test('should handle model name formatting', () {
      // Test simple name conversion
      expect(AISettingsService.getSimpleModelName('models/gemini-1.5-flash'), 'gemini-1.5-flash');
      expect(AISettingsService.getSimpleModelName('gemini-1.5-flash'), 'gemini-1.5-flash');

      // Test full name conversion
      expect(AISettingsService.getFullModelName('gemini-1.5-flash'), 'models/gemini-1.5-flash');
      expect(AISettingsService.getFullModelName('models/gemini-1.5-flash'), 'models/gemini-1.5-flash');
    });

    test('should provide default models when API fails', () async {
      // This should return default models when given an invalid API key
      final models = await AISettingsService.getAvailableGeminiModels('invalid_key');
      
      // Should fallback to default models
      expect(models.isNotEmpty, true);
      expect(models.any((m) => m.name.contains('gemini')), true);
    });

    test('should clear settings correctly', () async {
      // First save some settings
      const testSettings = AISettings(
        provider: 'google',
        apiKey: 'test_key',
        baseUrl: 'test_url',
        model: 'test_model',
      );
      
      await AISettingsService.saveSettings(testSettings);
      
      // Verify settings exist
      final settingsBeforeClear = await AISettingsService.loadSettings();
      expect(settingsBeforeClear, isNotNull);
      
      // Clear settings
      final clearResult = await AISettingsService.clearAllSettings();
      expect(clearResult, true);
      
      // Verify settings are cleared
      final settingsAfterClear = await AISettingsService.loadSettings();
      expect(settingsAfterClear, isNull);
    });
  });
}
