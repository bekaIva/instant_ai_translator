import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiAIService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  static const String _apiKey = 'AIzaSyBsN3KkjjNqDWNvuR6mFUUSZsfQbOclGx0';

  /// Process text using Gemini AI with the given system instruction
  static Future<String> processText(String text, String systemInstruction) async {
    try {
      // Prepare the request payload
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '$systemInstruction\n\nText to process:\n$text'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1, // Low temperature for more consistent results
          'topK': 1,
          'topP': 0.8,
          'maxOutputTokens': 2048,
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
        Uri.parse('$_baseUrl?key=$_apiKey'),
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
      await processText('Hello', 'Respond with "Connection successful" if you receive this message.');
      return true;
    } catch (e) {
      print('Gemini AI connection test failed: $e');
      return false;
    }
  }

  /// Get API usage information (simplified)
  static Map<String, dynamic> getApiInfo() {
    return {
      'service': 'Google Gemini AI',
      'model': 'gemini-1.5-flash-latest',
      'apiKeyConfigured': _apiKey.isNotEmpty,
      'baseUrl': _baseUrl,
    };
  }
}
