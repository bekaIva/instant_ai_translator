import 'package:flutter/material.dart';
import '../services/native_integration_service.dart';
import '../native/system_integration_safe.dart';

class Phase3DemoScreen extends StatefulWidget {
  const Phase3DemoScreen({super.key});

  @override
  State<Phase3DemoScreen> createState() => _Phase3DemoScreenState();
}

class _Phase3DemoScreenState extends State<Phase3DemoScreen> {
  final _nativeService = NativeIntegrationService();
  final List<String> _statusMessages = [];
  final List<MenuActionEvent> _menuActions = [];
  SelectionInfo? _currentSelection;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNativeIntegration();
  }

  Future<void> _initializeNativeIntegration() async {
    // Listen to status updates
    _nativeService.onStatusChanged.listen((status) {
      setState(() {
        _statusMessages.add('${DateTime.now().toString().substring(11, 19)}: $status');
        // Keep only last 10 messages
        if (_statusMessages.length > 10) {
          _statusMessages.removeAt(0);
        }
      });
    });

    // Listen to selection changes
    _nativeService.onSelectionChanged.listen((selection) {
      setState(() {
        _currentSelection = selection;
      });
    });

    // Listen to menu actions
    _nativeService.onMenuAction.listen((event) {
      setState(() {
        _menuActions.add(event);
        // Keep only last 5 actions
        if (_menuActions.length > 5) {
          _menuActions.removeAt(0);
        }
      });
    });

    // Initialize the service
    bool initialized = await _nativeService.initialize();
    setState(() {
      _isInitialized = initialized;
    });
  }

  @override
  void dispose() {
    _nativeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 3: AI Integration Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(_isInitialized ? 'Native System Ready' : 'System Not Ready'),
                      ],
                    ),
                    if (_isInitialized) ...[
                      const SizedBox(height: 8),
                      Text('Desktop: ${_nativeService.getDesktopEnvironment()}'),
                      const SizedBox(height: 8),
                      const Text(
                        '🎯 Instructions:\n'
                        '1. Select text in any application\n'
                        '2. Press Ctrl+Shift+M\n'
                        '3. Click "🌐 AI Translate"\n'
                        '4. Watch text get replaced!',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
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
                    Text(
                      'Current Selection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_currentSelection != null) ...[
                      Text('Text: "${_currentSelection!.text}"'),
                      Text('Position: (${_currentSelection!.x}, ${_currentSelection!.y})'),
                      Text('App: ${_currentSelection!.appName}'),
                    ] else ...[
                      const Text('No text selected', style: TextStyle(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recent Menu Actions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent AI Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: _menuActions.isEmpty
                          ? const Text('No actions yet', style: TextStyle(color: Colors.grey))
                          : ListView.builder(
                              itemCount: _menuActions.length,
                              itemBuilder: (context, index) {
                                final action = _menuActions[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '${action.menuId}: "${action.selection.text}"',
                                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
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

            // Status Log Card
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Log',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _statusMessages.isEmpty
                              ? const Text(
                                  'System initializing...',
                                  style: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
                                )
                              : ListView.builder(
                                  itemCount: _statusMessages.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 1),
                                      child: Text(
                                        _statusMessages[index],
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Test Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isInitialized ? () {
                    final selection = _nativeService.getCurrentSelection();
                    if (selection != null) {
                      setState(() {
                        _currentSelection = selection;
                      });
                    }
                  } : null,
                  child: const Text('Refresh Selection'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isInitialized ? () async {
                    await _nativeService.registerSingleMenuItem();
                  } : null,
                  child: const Text('Re-register Menu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
