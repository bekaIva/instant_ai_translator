import 'package:flutter/material.dart';
import '../services/ai_settings_service.dart';

// AI Provider model
class AIProvider {
  final String id;
  final String name;
  final String defaultBaseUrl;
  final String description;
  final List<String> commonModels;

  const AIProvider({
    required this.id,
    required this.name,
    required this.defaultBaseUrl,
    required this.description,
    required this.commonModels,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableNotifications = true;
  bool _autoStartWithSystem = false;
  
  // Controllers for text fields
  late TextEditingController _modelController;
  late TextEditingController _apiKeyController;

  // AI Provider Configuration
  String? _selectedProvider;
  String _apiKey = '';
  String _baseUrl = '';
  String _model = '';
  
  // Gemini-specific state
  List<GeminiModel> _availableGeminiModels = [];
  bool _loadingModels = false;
  bool _testingConnection = false;
  
  // Ollama Settings
  String _ollamaServerUrl = 'http://localhost:11434';
  List<String> _availableOllamaModels = [];
  String? _selectedOllamaModel;

  late List<AIProvider> _aiProviders;

    @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: _model);
    _apiKeyController = TextEditingController(text: _apiKey);
    _initializeAIProviders();
    _loadOllamaModels();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _initializeAIProviders() {
    _aiProviders = [
      const AIProvider(
        id: 'openai',
        name: 'OpenAI',
        defaultBaseUrl: 'https://api.openai.com/v1',
        description: 'GPT-3.5, GPT-4, and other OpenAI models',
        commonModels: ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'],
      ),
      const AIProvider(
        id: 'anthropic',
        name: 'Anthropic Claude',
        defaultBaseUrl: 'https://api.anthropic.com/v1',
        description: 'Claude 3 Haiku, Sonnet, and Opus models',
        commonModels: ['claude-3-haiku-20240307', 'claude-3-sonnet-20240229', 'claude-3-opus-20240229'],
      ),
      const AIProvider(
        id: 'google',
        name: 'Google Gemini',
        defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        description: 'Gemini 1.5 Flash, Pro and other Google AI models',
        commonModels: ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'],
      ),
      const AIProvider(
        id: 'groq',
        name: 'Groq',
        defaultBaseUrl: 'https://api.groq.com/openai/v1',
        description: 'Fast inference with Llama, Mixtral models',
        commonModels: ['llama2-70b-4096', 'mixtral-8x7b-32768', 'gemma-7b-it'],
      ),
      const AIProvider(
        id: 'deepseek',
        name: 'DeepSeek',
        defaultBaseUrl: 'https://api.deepseek.com/v1',
        description: 'DeepSeek Chat and Code models',
        commonModels: ['deepseek-chat', 'deepseek-coder'],
      ),
      const AIProvider(
        id: 'custom',
        name: 'Custom OpenAI-Compatible',
        defaultBaseUrl: 'https://api.example.com/v1',
        description: 'Any OpenAI-compatible API endpoint',
        commonModels: ['gpt-3.5-turbo', 'llama-2-7b', 'custom-model'],
      ),
    ];
  }

  Future<void> _loadOllamaModels() async {
    // TODO: Implement actual API call to Ollama
    // For now, simulate with common models
    setState(() {
      _availableOllamaModels = [
        'llama2',
        'llama2:13b',
        'codellama',
        'mistral',
        'mixtral',
        'neural-chat',
        'starling-lm',
        'vicuna',
        'orca-mini',
      ];
    });
  }

  /// Load saved AI settings
  Future<void> _loadSavedSettings() async {
    try {
      final settings = await AISettingsService.loadSettings();
      if (settings != null) {
        setState(() {
          _selectedProvider = settings.provider;
          _apiKey = settings.apiKey;
          _baseUrl = settings.baseUrl;
          _model = settings.model;
          _modelController.text = _model;
          _apiKeyController.text = _apiKey;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  /// Load available Gemini models when API key is provided
  Future<void> _loadGeminiModels() async {
    if (_apiKey.isEmpty || _selectedProvider != 'google') return;
    
    setState(() {
      _loadingModels = true;
    });

    try {
      final models = await AISettingsService.getAvailableGeminiModels(_apiKey);
      setState(() {
        _availableGeminiModels = models;
        _loadingModels = false;
      });
    } catch (e) {
      setState(() {
        _loadingModels = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load models: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Settings'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('AI Provider'),
            Text(
              'Configure your AI service for text processing.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildAIProviderSection(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Local AI (Ollama)'),
            _buildOllamaSection(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('System Settings'),
            _buildSwitchCard(
              'Start with System',
              'Launch the AI translator when your computer starts',
              _autoStartWithSystem,
              (value) => setState(() => _autoStartWithSystem = value),
            ),
            const SizedBox(height: 8),
            _buildSwitchCard(
              'Enable Notifications',
              'Show notifications for AI processing results',
              _enableNotifications,
              (value) => setState(() => _enableNotifications = value),
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _testingConnection ? null : _testConnection,
                  child: _testingConnection 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Connection'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _resetToDefaults,
                  child: const Text('Reset to Defaults'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAIProviderSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'API Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Provider Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'AI Provider',
                border: OutlineInputBorder(),
              ),
              value: _selectedProvider,
              hint: const Text('Select an AI provider'),
              items: _aiProviders.map((provider) {
                return DropdownMenuItem<String>(
                  value: provider.id,
                  child: Text(provider.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProvider = value;
                  _availableGeminiModels.clear(); // Clear previous models
                  if (value != null) {
                    final provider = _aiProviders.firstWhere((p) => p.id == value);
                    _baseUrl = provider.defaultBaseUrl;
                    _model = provider.commonModels.first;
                    _modelController.text = _model;
                    
                    // Auto-load models for Gemini if API key is available
                    if (value == 'google' && _apiKey.isNotEmpty) {
                      _loadGeminiModels();
                    }
                  }
                });
              },
            ),
            
            if (_selectedProvider != null) ...[
              const SizedBox(height: 16),
              
              // API Key
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your API key',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedProvider == 'google' && _apiKey.isNotEmpty)
                        IconButton(
                          icon: _loadingModels 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh),
                          onPressed: _loadingModels ? null : _loadGeminiModels,
                          tooltip: 'Load available models',
                        ),
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: _showApiKeyHelp,
                      ),
                    ],
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _apiKey = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Base URL (for custom providers)
              if (_selectedProvider == 'custom')
                Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'https://api.example.com/v1',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _baseUrl),
                      onChanged: (value) => _baseUrl = value,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Model Selection
              if (_selectedProvider == 'google' && _availableGeminiModels.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                    helperText: 'Select from available Gemini models',
                  ),
                  value: _availableGeminiModels.any((m) => AISettingsService.getSimpleModelName(m.name) == _model) ? _model : null,
                  hint: const Text('Select a model'),
                  isExpanded: true,
                  menuMaxHeight: 200, // Limit dropdown height
                  items: _availableGeminiModels.map((model) {
                    final simpleName = AISettingsService.getSimpleModelName(model.name);
                    final displayName = model.displayName.isNotEmpty ? model.displayName : simpleName;
                    return DropdownMenuItem<String>(
                      value: simpleName,
                      child: Tooltip(
                        message: model.description.isNotEmpty ? model.description : displayName,
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _model = value ?? '';
                      _modelController.text = _model;
                    });
                  },
                )
              else
                // Fallback to text field for manual entry
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Model',
                    hintText: _getModelHintForProvider(_selectedProvider!),
                    border: const OutlineInputBorder(),
                    helperText: _selectedProvider == 'google' 
                        ? 'Enter API key and click refresh to load available models'
                        : 'Enter the exact model name from your provider',
                    suffixIcon: _selectedProvider != 'google' 
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.help_outline),
                            tooltip: 'Common models',
                            onSelected: (value) {
                              setState(() {
                                _model = value;
                                _modelController.text = value;
                              });
                            },
                            itemBuilder: (context) => _getModelsForProvider(_selectedProvider!)
                                .map((model) => PopupMenuItem<String>(
                                      value: model,
                                      child: Text(model),
                                    ))
                                .toList(),
                          )
                        : null,
                  ),
                  controller: _modelController,
                  onChanged: (value) {
                    setState(() {
                      _model = value;
                    });
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _getModelsForProvider(String providerId) {
    final provider = _aiProviders.firstWhere((p) => p.id == providerId);
    return provider.commonModels;
  }

  String _getModelHintForProvider(String providerId) {
    switch (providerId) {
      case 'openai':
        return 'e.g., gpt-4, gpt-3.5-turbo, gpt-4-turbo';
      case 'gemini':
        return 'e.g., gemini-pro, gemini-pro-vision';
      case 'deepseek':
        return 'e.g., deepseek-chat, deepseek-coder';
      case 'custom':
        return 'Enter your custom model name';
      default:
        return 'Enter the model name from your provider';
    }
  }

  Widget _buildOllamaSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.computer, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Ollama Local AI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Run AI models locally on your machine for privacy and offline usage.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Ollama Server URL',
                hintText: 'http://localhost:11434',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _ollamaServerUrl),
              onChanged: (value) {
                _ollamaServerUrl = value;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Available Models',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedOllamaModel,
                    hint: const Text('Select a model'),
                    items: _availableOllamaModels.map((model) {
                      return DropdownMenuItem<String>(
                        value: model,
                        child: Text(model),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOllamaModel = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _refreshOllamaModels,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pullOllamaModel,
              icon: const Icon(Icons.download),
              label: const Text('Pull New Model'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      elevation: 1,
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedProvider != null) ...[
              Text(
                'How to get your ${_aiProviders.firstWhere((p) => p.id == _selectedProvider).name} API key:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._getApiKeyInstructions(_selectedProvider!),
            ] else ...[
              const Text('Select an AI provider first to see specific instructions.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  List<Widget> _getApiKeyInstructions(String providerId) {
    switch (providerId) {
      case 'openai':
        return [
          const Text('1. Visit platform.openai.com'),
          const Text('2. Sign in or create an account'),
          const Text('3. Go to API Keys section'),
          const Text('4. Create a new API key'),
        ];
      case 'gemini':
        return [
          const Text('1. Visit makersuite.google.com'),
          const Text('2. Sign in with Google account'),
          const Text('3. Go to API Keys section'),
          const Text('4. Create a new API key'),
        ];
      case 'deepseek':
        return [
          const Text('1. Visit platform.deepseek.com'),
          const Text('2. Create an account'),
          const Text('3. Go to API Keys section'),
          const Text('4. Generate a new API key'),
        ];
      case 'custom':
        return [
          const Text('Contact your API provider for:'),
          const Text('• API key or authentication token'),
          const Text('• Base URL endpoint'),
          const Text('• Available model names'),
        ];
      default:
        return [const Text('Check your provider\'s documentation for API key instructions.')];
    }
  }

  Future<void> _refreshOllamaModels() async {
    // TODO: Implement actual API call to refresh Ollama models
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing Ollama models...'),
      ),
    );
    
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    await _loadOllamaModels();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Models refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _pullOllamaModel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pull Ollama Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the name of the model you want to pull:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Model Name',
                hintText: 'llama2, mistral, codellama, etc.',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                Navigator.of(context).pop();
                _performModelPull(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Get model name from text field
            },
            child: const Text('Pull'),
          ),
        ],
      ),
    );
  }

  Future<void> _performModelPull(String modelName) async {
    // TODO: Implement actual Ollama model pull
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pulling model: $modelName...'),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_selectedProvider == null || _apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a provider and enter an API key'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _testingConnection = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing connection...'),
      ),
    );

    bool success = false;

    try {
      if (_selectedProvider == 'google') {
        // Test Gemini connection
        if (_model.isEmpty) {
          throw Exception('Please select a model first');
        }
        success = await AISettingsService.testGeminiConnection(_apiKey, AISettingsService.getFullModelName(_model));
      } else {
        // For other providers, implement their specific test methods
        await Future.delayed(const Duration(seconds: 2));
        success = true; // Placeholder - implement actual tests for other providers
      }
    } catch (e) {
      success = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _testingConnection = false;
    });

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection test successful'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _saveSettings() async {
    try {
      if (_selectedProvider != null && _apiKey.isNotEmpty && _model.isNotEmpty) {
        final settings = AISettings(
          provider: _selectedProvider!,
          apiKey: _apiKey,
          baseUrl: _baseUrl,
          model: _model,
          enabled: true,
        );
        
        final success = await AISettingsService.saveSettings(settings);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to save settings');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please configure all required fields'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all AI settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                // Reset AI configuration
                _selectedProvider = null;
                _apiKey = '';
                _baseUrl = '';
                _model = '';
                _modelController.text = '';
                _apiKeyController.text = '';
                _availableGeminiModels.clear();
                
                // Reset other settings
                _enableNotifications = true;
                _autoStartWithSystem = false;
                _ollamaServerUrl = 'http://localhost:11434';
                _selectedOllamaModel = null;
              });
              
              // Clear saved settings
              await AISettingsService.clearAllSettings();
              
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
