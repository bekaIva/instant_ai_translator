import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_settings_service.dart';

class GeminiAIService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Process text using Gemini AI with the given system instruction
  static Future<String> processText(String text, String systemInstruction) async {
    try {
      // Load AI settings
      final settings = await AISettingsService.loadSettings();
      if (settings == null || settings.provider != 'google' || settings.apiKey.isEmpty || settings.model.isEmpty) {
        throw Exception('Gemini AI not configured. Please configure your API key and model in Settings.');
      }

      // Ensure model has the full path format
      final fullModelName = AISettingsService.getFullModelName(settings.model);

      // Prepare the request payload with proper system instruction
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '$systemInstruction\n\nUser input: $text\n\nResponse:'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2, // Low temperature for more consistent, focused results
          'topK': 40,
          'topP': 0.8,
          'maxOutputTokens': 2048,
          'stopSequences': [], // No special stop sequences needed
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      // Make the API call
      final response = await http.post(
        Uri.parse('$_baseUrl/$fullModelName:generateContent?key=${settings.apiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Extract the generated text from the response
        if (jsonResponse['candidates'] != null && 
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0]['content'] != null &&
            jsonResponse['candidates'][0]['content']['parts'] != null &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final generatedText = jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;
          return generatedText.trim();
        } else {
          throw Exception('Invalid response format from Gemini API');
        }
      } else {
        // Handle API errors
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        throw Exception('Gemini API error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Failed to process text with Gemini AI: $e');
      }
    }
  }

  /// Test the Gemini AI connection
  static Future<bool> testConnection() async {
    try {
      final settings = await AISettingsService.loadSettings();
      if (settings == null || settings.provider != 'google' || settings.apiKey.isEmpty || settings.model.isEmpty) {
        return false;
      }

      return await AISettingsService.testGeminiConnection(settings.apiKey, settings.model);
    } catch (e) {
      print('Gemini AI connection test failed: $e');
      return false;
    }
  }

  /// Get API usage information
  static Future<Map<String, dynamic>> getApiInfo() async {
    final settings = await AISettingsService.loadSettings();
    
    return {
      'service': 'Google Gemini AI',
      'model': settings?.model ?? 'Not configured',
      'apiKeyConfigured': settings?.apiKey.isNotEmpty ?? false,
      'baseUrl': _baseUrl,
      'configured': settings != null && settings.provider == 'google' && settings.apiKey.isNotEmpty,
    };
  }
}
