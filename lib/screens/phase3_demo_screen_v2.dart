import 'package:flutter/material.dart';
import '../services/native_integration_service_v2.dart';
import '../native/system_integration_safe.dart';

class Phase3DemoScreenV2 extends StatefulWidget {
  const Phase3DemoScreenV2({Key? key}) : super(key: key);

  @override
  State<Phase3DemoScreenV2> createState() => _Phase3DemoScreenV2State();
}

class _Phase3DemoScreenV2State extends State<Phase3DemoScreenV2> {
  final NativeIntegrationService _nativeService = NativeIntegrationService();
  
  String _systemStatus = 'Not initialized';
  SelectionInfo? _currentSelection;
  List<MenuAction> _recentActions = [];
  List<String> _logs = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeNativeIntegration();
  }

  Future<void> _initializeNativeIntegration() async {
    // Listen to streams
    _nativeService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _systemStatus = status;
        });
      }
    });

    _nativeService.selectionStream.listen((selection) {
      if (mounted) {
        setState(() {
          _currentSelection = selection;
        });
      }
    });

    _nativeService.menuActionStream.listen((action) {
      if (mounted) {
        setState(() {
          _recentActions.insert(0, action);
          if (_recentActions.length > 10) {
            _recentActions.removeLast();
          }
        });
      }
    });

    _nativeService.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.insert(0, log);
          if (_logs.length > 50) {
            _logs.removeLast();
          }
        });
      }
    });

    // Initialize the service
    await _nativeService.initialize();
  }

  Future<void> _processCurrentSelection(String operation) async {
    if (_currentSelection == null || _currentSelection!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text selected')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      bool success = await _nativeService.processAndReplace(
        _currentSelection!.text,
        operation,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully processed text with $operation'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to process text'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemInfo = _nativeService.getSystemInfo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 3: AI Integration Demo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to Use',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Open any text editor (gedit, kate, mousepad, etc.)\n'
                      '2. Type some text: "Hello world this is a test"\n'
                      '3. Select the text you want to process\n'
                      '4. Either:\n'
                      '   • Press Ctrl+Shift+M and click a menu item, OR\n'
                      '   • Use the buttons below to process the selected text\n'
                      '5. Watch the text get replaced in your editor!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // System Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          systemInfo['compatible'] ? Icons.check_circle : Icons.error,
                          color: systemInfo['compatible'] ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'System Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow('Status', _systemStatus),
                    _buildStatusRow('Desktop', systemInfo['desktop'] ?? 'Unknown'),
                    _buildStatusRow('Compatible', systemInfo['compatible'] ? 'Yes' : 'No'),
                    _buildStatusRow('Monitoring', systemInfo['monitoring'] ? 'Active' : 'Inactive'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.select_all, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Selection',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_currentSelection == null || _currentSelection!.text.isEmpty)
                      const Text(
                        'No text selected',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      )
                    else ...[
                      _buildStatusRow('Text', '"${_currentSelection!.text}"'),
                      _buildStatusRow('Length', '${_currentSelection!.length} characters'),
                      _buildStatusRow('Position', '(${_currentSelection!.x}, ${_currentSelection!.y})'),
                      _buildStatusRow('App', _currentSelection!.appName),
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      const Text(
                        'Process Selected Text:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : () => _processCurrentSelection('translate'),
                            icon: const Icon(Icons.translate),
                            label: const Text('🌐 Translate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : () => _processCurrentSelection('improve'),
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('✨ Improve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : () => _processCurrentSelection('summarize'),
                            icon: const Icon(Icons.summarize),
                            label: const Text('📝 Summarize'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Processing...'),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recent Actions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Recent Actions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_recentActions.isEmpty)
                      const Text(
                        'No actions performed yet',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _recentActions.length,
                          itemBuilder: (context, index) {
                            final action = _recentActions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  action.success ? Icons.check_circle : Icons.error,
                                  color: action.success ? Colors.green : Colors.red,
                                ),
                                title: Text('${action.menuId.toUpperCase()} Action'),
                                subtitle: Text(
                                  '"${action.originalText}" → "${action.processedText}"',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                dense: true,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // System Logs Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.terminal, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'System Logs',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No logs yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                return Text(
                                  _logs[index],
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nativeService.dispose();
    super.dispose();
  }
}
