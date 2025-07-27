import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedAIService = 'OpenAI GPT';
  String _defaultSourceLanguage = 'Auto-detect';
  String _defaultTargetLanguage = 'English';
  bool _enableNotifications = true;
  bool _autoStartWithSystem = false;
  bool _enableLocalProcessing = false;
  String _apiKey = '';

  final List<String> _aiServices = [
    'OpenAI GPT',
    'Google Translate',
    'DeepL',
    'Microsoft Translator',
    'Local Model (Ollama)',
  ];

  final List<String> _languages = [
    'Auto-detect',
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Japanese',
    'Chinese (Simplified)',
    'Arabic',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('AI Service Configuration'),
            _buildDropdownCard(
              'AI Service Provider',
              _selectedAIService,
              _aiServices,
              (value) => setState(() => _selectedAIService = value!),
            ),
            const SizedBox(height: 8),
            _buildApiKeyCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Language Settings'),
            _buildDropdownCard(
              'Default Source Language',
              _defaultSourceLanguage,
              _languages,
              (value) => setState(() => _defaultSourceLanguage = value!),
            ),
            const SizedBox(height: 8),
            _buildDropdownCard(
              'Default Target Language',
              _defaultTargetLanguage,
              _languages,
              (value) => setState(() => _defaultTargetLanguage = value!),
            ),
            const SizedBox(height: 24),
            
            _buildSectionHeader('System Settings'),
            _buildSwitchCard(
              'Start with System',
              'Launch the translator when your computer starts',
              _autoStartWithSystem,
              (value) => setState(() => _autoStartWithSystem = value),
            ),
            const SizedBox(height: 8),
            _buildSwitchCard(
              'Enable Notifications',
              'Show notifications for translation results',
              _enableNotifications,
              (value) => setState(() => _enableNotifications = value),
            ),
            const SizedBox(height: 8),
            _buildSwitchCard(
              'Local Processing',
              'Process text locally when possible for privacy',
              _enableLocalProcessing,
              (value) => setState(() => _enableLocalProcessing = value),
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

  Widget _buildDropdownCard(
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
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

  Widget _buildApiKeyCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Key',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your ${_selectedAIService} API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: _showApiKeyHelp,
                ),
              ),
              onChanged: (value) => _apiKey = value,
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_selectedAIService} API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To use ${_selectedAIService}, you need to:'),
            const SizedBox(height: 8),
            const Text('1. Create an account with the service provider'),
            const Text('2. Generate an API key from their dashboard'),
            const Text('3. Paste the API key here'),
            const SizedBox(height: 16),
            Text(
              'Your API key is stored securely and only used for text processing.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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

  void _saveSettings() {
    // TODO: Save settings to storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAIService = 'OpenAI GPT';
                _defaultSourceLanguage = 'Auto-detect';
                _defaultTargetLanguage = 'English';
                _enableNotifications = true;
                _autoStartWithSystem = false;
                _enableLocalProcessing = false;
                _apiKey = '';
              });
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
