import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TranslationPanel extends StatefulWidget {
  const TranslationPanel({super.key});

  @override
  State<TranslationPanel> createState() => _TranslationPanelState();
}

class _TranslationPanelState extends State<TranslationPanel> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  bool _isTranslating = false;
  String _sourceLanguage = 'Auto-detect';
  String _targetLanguage = 'English';

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _swapLanguages() {
    if (_sourceLanguage != 'Auto-detect') {
      setState(() {
        final temp = _sourceLanguage;
        _sourceLanguage = _targetLanguage;
        _targetLanguage = temp;
        
        // Swap text content too
        final tempText = _inputController.text;
        _inputController.text = _outputController.text;
        _outputController.text = tempText;
      });
    }
  }

  Future<void> _translateText() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    // Simulate translation delay
    await Future.delayed(const Duration(seconds: 1));

    // Placeholder translation logic
    setState(() {
      _outputController.text = 'Translated: ${_inputController.text}';
      _isTranslating = false;
    });
  }

  void _clearText() {
    _inputController.clear();
    _outputController.clear();
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translation copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Translator'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearText,
            tooltip: 'Clear all text',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language selection bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _LanguageDropdown(
                      value: _sourceLanguage,
                      onChanged: (value) {
                        setState(() {
                          _sourceLanguage = value!;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: _swapLanguages,
                    tooltip: 'Swap languages',
                  ),
                  Expanded(
                    child: _LanguageDropdown(
                      value: _targetLanguage,
                      onChanged: (value) {
                        setState(() {
                          _targetLanguage = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Translation panels
            Expanded(
              child: Row(
                children: [
                  // Input panel
                  Expanded(
                    child: _TranslationCard(
                      title: 'Source Text',
                      controller: _inputController,
                      hintText: 'Enter text to translate...',
                      isReadOnly: false,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.content_paste),
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _inputController.text = data!.text!;
                            }
                          },
                          tooltip: 'Paste',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Translation button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isTranslating ? null : _translateText,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: const CircleBorder(),
                        ),
                        child: _isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward, size: 24),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Output panel
                  Expanded(
                    child: _TranslationCard(
                      title: 'Translation',
                      controller: _outputController,
                      hintText: 'Translation will appear here...',
                      isReadOnly: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.content_copy),
                          onPressed: _copyOutput,
                          tooltip: 'Copy',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _LanguageDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const languages = [
      'Auto-detect',
      'English',
      'Spanish',
      'French',
      'German',
      'Italian',
      'Portuguese',
      'Russian',
      'Chinese',
      'Japanese',
      'Korean',
      'Arabic',
    ];

    return DropdownButton<String>(
      value: value,
      onChanged: onChanged,
      isExpanded: true,
      underline: const SizedBox(),
      items: languages.map((String language) {
        return DropdownMenuItem<String>(
          value: language,
          child: Text(language),
        );
      }).toList(),
    );
  }
}

class _TranslationCard extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hintText;
  final bool isReadOnly;
  final List<Widget> actions;

  const _TranslationCard({
    required this.title,
    required this.controller,
    required this.hintText,
    required this.isReadOnly,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          
          // Text field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: controller,
                readOnly: isReadOnly,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
