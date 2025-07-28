import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ContextMenuConfig {
  final String id;
  final String label;
  final String operation;
  final String description;
  final bool enabled;
  final String icon;
  final int sortOrder;

  const ContextMenuConfig({
    required this.id,
    required this.label,
    required this.operation,
    required this.description,
    required this.enabled,
    required this.icon,
    required this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'operation': operation,
      'description': description,
      'enabled': enabled,
      'icon': icon,
      'sortOrder': sortOrder,
    };
  }

  factory ContextMenuConfig.fromJson(Map<String, dynamic> json) {
    return ContextMenuConfig(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      operation: json['operation'] ?? '',
      description: json['description'] ?? '',
      enabled: json['enabled'] ?? false,
      icon: json['icon'] ?? '🔧',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  ContextMenuConfig copyWith({
    String? id,
    String? label,
    String? operation,
    String? description,
    bool? enabled,
    String? icon,
    int? sortOrder,
  }) {
    return ContextMenuConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      operation: operation ?? this.operation,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class ContextMenuConfigService {
  static const String _configKey = 'context_menu_configs';
  static const String _versionKey = 'config_version';
  static const int _currentVersion = 1;

  // Default menu configurations
  static final List<ContextMenuConfig> _defaultConfigs = [
    ContextMenuConfig(
      id: 'translate',
      label: '🌐 Translate to English',
      operation: 'You are a professional translator. Translate the text to English while maintaining the original meaning, tone, and style. If the text is already in English, return it unchanged. Return only the translated text, no explanations or comments.',
      description: 'Translate text to another language',
      enabled: true,
      icon: '🌐',
      sortOrder: 1,
    ),
    ContextMenuConfig(
      id: 'improve',
      label: '✨ Improve Text',
      operation: 'You are a professional editor. Improve the text by fixing grammar errors, enhancing clarity, and improving readability while maintaining the original meaning and tone. Make it more polished and professional. Return only the improved text.',
      description: 'Improve grammar and style',
      enabled: true,
      icon: '✨',
      sortOrder: 2,
    ),
    ContextMenuConfig(
      id: 'summarize',
      label: '📝 Summarize',
      operation: 'You are a professional summarizer. Create a concise and accurate summary that captures the main points and key information while significantly reducing the length. Maintain the essential meaning and important details. Return only the summary.',
      description: 'Create a concise summary',
      enabled: true,
      icon: '📝',
      sortOrder: 3,
    ),
    ContextMenuConfig(
      id: 'explain',
      label: '💡 Explain',
      operation: 'You are an expert teacher. Explain the text in simple, clear terms. Break down complex concepts, define technical terms, and provide context to make it easily understandable. Use examples if helpful. Return only the explanation.',
      description: 'Explain complex concepts',
      enabled: false,
      icon: '💡',
      sortOrder: 4,
    ),
    ContextMenuConfig(
      id: 'rewrite',
      label: '🔄 Rewrite',
      operation: 'You are a professional writer. Rewrite the text using different words and sentence structures while preserving the original meaning. Make it fresh and engaging while maintaining the same tone and intent. Return only the rewritten text.',
      description: 'Rewrite in different style',
      enabled: false,
      icon: '🔄',
      sortOrder: 5,
    ),
    ContextMenuConfig(
      id: 'expand',
      label: '📈 Expand',
      operation: 'You are a professional content writer. Expand the text by adding more detail, context, and relevant information. Elaborate on key points, provide examples, and make the content more comprehensive while maintaining the original tone and style. Return only the expanded text.',
      description: 'Add more detail and context',
      enabled: false,
      icon: '📈',
      sortOrder: 6,
    ),
  ];

  // Load configurations from shared preferences
  static Future<List<ContextMenuConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we need to initialize with defaults
    final version = prefs.getInt(_versionKey) ?? 0;
    if (version < _currentVersion) {
      await _initializeDefaults(prefs);
    }

    final configsJson = prefs.getString(_configKey);
    if (configsJson == null || configsJson.isEmpty) {
      return List.from(_defaultConfigs);
    }

    try {
      final List<dynamic> configsList = jsonDecode(configsJson);
      final configs = configsList
          .map((json) => ContextMenuConfig.fromJson(json))
          .toList();
      
      // Sort by sortOrder
      configs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return configs;
    } catch (e) {
      print('Error loading configs: $e');
      return List.from(_defaultConfigs);
    }
  }

  // Save configurations to shared preferences
  static Future<bool> saveConfigs(List<ContextMenuConfig> configs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = jsonEncode(configs.map((c) => c.toJson()).toList());
      return await prefs.setString(_configKey, configsJson);
    } catch (e) {
      print('Error saving configs: $e');
      return false;
    }
  }

  // Get enabled configurations only
  static Future<List<ContextMenuConfig>> getEnabledConfigs() async {
    final configs = await loadConfigs();
    return configs.where((config) => config.enabled).toList();
  }

  // Add a new configuration
  static Future<bool> addConfig(ContextMenuConfig config) async {
    final configs = await loadConfigs();
    
    // Check for duplicate ID
    if (configs.any((c) => c.id == config.id)) {
      return false;
    }
    
    configs.add(config);
    return await saveConfigs(configs);
  }

  // Update an existing configuration
  static Future<bool> updateConfig(String id, ContextMenuConfig updatedConfig) async {
    final configs = await loadConfigs();
    final index = configs.indexWhere((c) => c.id == id);
    
    if (index == -1) {
      return false;
    }
    
    configs[index] = updatedConfig;
    return await saveConfigs(configs);
  }

  // Delete a configuration
  static Future<bool> deleteConfig(String id) async {
    final configs = await loadConfigs();
    final initialLength = configs.length;
    configs.removeWhere((c) => c.id == id);
    
    if (configs.length == initialLength) {
      return false; // Nothing was removed
    }
    
    return await saveConfigs(configs);
  }

  // Toggle enabled state of a configuration
  static Future<bool> toggleConfig(String id, bool enabled) async {
    final configs = await loadConfigs();
    final index = configs.indexWhere((c) => c.id == id);
    
    if (index == -1) {
      return false;
    }
    
    configs[index] = configs[index].copyWith(enabled: enabled);
    return await saveConfigs(configs);
  }

  // Reset to default configurations
  static Future<bool> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    return await _initializeDefaults(prefs);
  }

  // Reorder configurations
  static Future<bool> reorderConfigs(List<ContextMenuConfig> reorderedConfigs) async {
    // Update sort orders
    for (int i = 0; i < reorderedConfigs.length; i++) {
      reorderedConfigs[i] = reorderedConfigs[i].copyWith(sortOrder: i + 1);
    }
    return await saveConfigs(reorderedConfigs);
  }

  // Initialize with default configurations
  static Future<bool> _initializeDefaults(SharedPreferences prefs) async {
    try {
      final configsJson = jsonEncode(_defaultConfigs.map((c) => c.toJson()).toList());
      await prefs.setString(_configKey, configsJson);
      await prefs.setInt(_versionKey, _currentVersion);
      return true;
    } catch (e) {
      print('Error initializing defaults: $e');
      return false;
    }
  }

  // Get configuration by ID
  static Future<ContextMenuConfig?> getConfigById(String id) async {
    final configs = await loadConfigs();
    try {
      return configs.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Export configurations as JSON string
  static Future<String> exportConfigs() async {
    final configs = await loadConfigs();
    return jsonEncode({
      'version': _currentVersion,
      'configs': configs.map((c) => c.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    });
  }

  // Import configurations from JSON string
  static Future<bool> importConfigs(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      final List<dynamic> configsList = data['configs'];
      final configs = configsList
          .map((json) => ContextMenuConfig.fromJson(json))
          .toList();
      
      return await saveConfigs(configs);
    } catch (e) {
      print('Error importing configs: $e');
      return false;
    }
  }

  // Get statistics
  static Future<Map<String, int>> getStats() async {
    final configs = await loadConfigs();
    return {
      'total': configs.length,
      'enabled': configs.where((c) => c.enabled).length,
      'disabled': configs.where((c) => !c.enabled).length,
    };
  }
}
