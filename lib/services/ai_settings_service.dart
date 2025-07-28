import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AISettings {
  final String provider;
  final String apiKey;
  final String baseUrl;
  final String model;
  final bool enabled;

  const AISettings({
    required this.provider,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'model': model,
      'enabled': enabled,
    };
  }

  factory AISettings.fromJson(Map<String, dynamic> json) {
    return AISettings(
      provider: json['provider'] ?? '',
      apiKey: json['apiKey'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      model: json['model'] ?? '',
      enabled: json['enabled'] ?? true,
    );
  }

  AISettings copyWith({
    String? provider,
    String? apiKey,
    String? baseUrl,
    String? model,
    bool? enabled,
  }) {
    return AISettings(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      enabled: enabled ?? this.enabled,
    );
  }
}

class GeminiModel {
  final String name;
  final String displayName;
  final String description;
  final int inputTokenLimit;
  final int outputTokenLimit;
  final List<String> supportedGenerationMethods;

  const GeminiModel({
    required this.name,
    required this.displayName,
    required this.description,
    required this.inputTokenLimit,
    required this.outputTokenLimit,
    required this.supportedGenerationMethods,
  });

  factory GeminiModel.fromJson(Map<String, dynamic> json) {
    return GeminiModel(
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      description: json['description'] ?? '',
      inputTokenLimit: json['inputTokenLimit'] ?? 0,
      outputTokenLimit: json['outputTokenLimit'] ?? 0,
      supportedGenerationMethods: List<String>.from(json['supportedGenerationMethods'] ?? []),
    );
  }
}

class AISettingsService {
  static const String _settingsKey = 'ai_settings';
  static const String _modelsKey = 'cached_models';
  static const String _lastModelFetchKey = 'last_model_fetch';
  
  // Cache models for 24 hours
  static const Duration _modelsCacheDuration = Duration(hours: 24);

  /// Load AI settings from storage
  static Future<AISettings?> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson == null) {
        return null;
      }
      
      final Map<String, dynamic> settings = jsonDecode(settingsJson);
      return AISettings.fromJson(settings);
    } catch (e) {
      print('Error loading AI settings: $e');
      return null;
    }
  }

  /// Save AI settings to storage
  static Future<bool> saveSettings(AISettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      return await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving AI settings: $e');
      return false;
    }
  }

  /// Get available Gemini models from Google API
  static Future<List<GeminiModel>> getAvailableGeminiModels(String apiKey) async {
    try {
      // Check cache first
      final cachedModels = await _getCachedModels();
      if (cachedModels.isNotEmpty && !await _shouldRefreshModels()) {
        return cachedModels;
      }

      // Fetch from API
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> modelsJson = data['models'] ?? [];
        
        final models = modelsJson
            .map((json) => GeminiModel.fromJson(json))
            .where((model) => 
                model.supportedGenerationMethods.contains('generateContent') &&
                model.name.contains('gemini'))
            .toList();

        // Cache the results
        await _cacheModels(models);
        
        return models;
      } else {
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Gemini models: $e');
      
      // Return cached models if available, or default models as fallback
      final cachedModels = await _getCachedModels();
      if (cachedModels.isNotEmpty) {
        return cachedModels;
      }
      
      // Fallback to known models
      return _getDefaultGeminiModels();
    }
  }

  /// Test API connection and validate API key
  static Future<bool> testGeminiConnection(String apiKey, String model) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Test connection. Respond with only: OK'
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 10,
          }
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  /// Get cached models from storage
  static Future<List<GeminiModel>> _getCachedModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modelsJson = prefs.getString(_modelsKey);
      
      if (modelsJson == null) {
        return [];
      }
      
      final List<dynamic> modelsList = jsonDecode(modelsJson);
      return modelsList.map((json) => GeminiModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading cached models: $e');
      return [];
    }
  }

  /// Cache models to storage
  static Future<void> _cacheModels(List<GeminiModel> models) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modelsJson = jsonEncode(models.map((m) => {
        'name': m.name,
        'displayName': m.displayName,
        'description': m.description,
        'inputTokenLimit': m.inputTokenLimit,
        'outputTokenLimit': m.outputTokenLimit,
        'supportedGenerationMethods': m.supportedGenerationMethods,
      }).toList());
      
      await prefs.setString(_modelsKey, modelsJson);
      await prefs.setInt(_lastModelFetchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching models: $e');
    }
  }

  /// Check if we should refresh models from API
  static Future<bool> _shouldRefreshModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_lastModelFetchKey);
      
      if (lastFetch == null) {
        return true;
      }
      
      final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
      final now = DateTime.now();
      
      return now.difference(lastFetchTime) > _modelsCacheDuration;
    } catch (e) {
      return true;
    }
  }

  /// Get default/fallback Gemini models
  static List<GeminiModel> _getDefaultGeminiModels() {
    return [
      const GeminiModel(
        name: 'models/gemini-1.5-flash',
        displayName: 'Gemini 1.5 Flash',
        description: 'Fast and efficient model for most tasks',
        inputTokenLimit: 1000000,
        outputTokenLimit: 8192,
        supportedGenerationMethods: ['generateContent'],
      ),
      const GeminiModel(
        name: 'models/gemini-1.5-pro',
        displayName: 'Gemini 1.5 Pro',
        description: 'Advanced model for complex reasoning tasks',
        inputTokenLimit: 2000000,
        outputTokenLimit: 8192,
        supportedGenerationMethods: ['generateContent'],
      ),
      const GeminiModel(
        name: 'models/gemini-pro',
        displayName: 'Gemini Pro',
        description: 'Powerful model for text generation',
        inputTokenLimit: 30720,
        outputTokenLimit: 2048,
        supportedGenerationMethods: ['generateContent'],
      ),
    ];
  }

  /// Clear all settings and cache
  static Future<bool> clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      await prefs.remove(_modelsKey);
      await prefs.remove(_lastModelFetchKey);
      return true;
    } catch (e) {
      print('Error clearing settings: $e');
      return false;
    }
  }

  /// Get simplified model name (remove "models/" prefix)
  static String getSimpleModelName(String fullModelName) {
    if (fullModelName.startsWith('models/')) {
      return fullModelName.substring(7);
    }
    return fullModelName;
  }

  /// Get full model name (add "models/" prefix if needed)
  static String getFullModelName(String modelName) {
    if (!modelName.startsWith('models/')) {
      return 'models/$modelName';
    }
    return modelName;
  }
}
