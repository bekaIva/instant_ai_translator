import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../services/production_context_menu_service.dart';
import '../services/context_menu_config_service.dart';

class ProductionMainScreen extends StatefulWidget {
  const ProductionMainScreen({Key? key}) : super(key: key);

  @override
  State<ProductionMainScreen> createState() => _ProductionMainScreenState();
}

class _ProductionMainScreenState extends State<ProductionMainScreen> {
  final ProductionContextMenuService _menuService = ProductionContextMenuService();
  
  String _systemStatus = 'Initializing...';
  List<ContextMenuAction> _recentActions = [];
  List<String> _logs = [];
  List<ContextMenuConfig> _activeConfigs = [];
  
  // Stream subscriptions to manage properly
  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<ContextMenuAction>? _actionSubscription;
  StreamSubscription<String>? _logSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    // Get the current status immediately to avoid showing "Initializing..." when already ready
    setState(() {
      _systemStatus = _menuService.currentStatus;
      // Load existing persistent data
      _recentActions = List.from(_menuService.actions);
      _logs = List.from(_menuService.logs);
    });
    
    // Cancel existing subscriptions to avoid duplicates
    await _statusSubscription?.cancel();
    await _actionSubscription?.cancel();
    await _logSubscription?.cancel();
    
    // Set up stream listeners only once
    _statusSubscription = _menuService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _systemStatus = status;
        });
      }
    });

    _actionSubscription = _menuService.actionStream.listen((action) {
      if (mounted) {
        setState(() {
          _recentActions.insert(0, action);
          if (_recentActions.length > 20) {
            _recentActions.removeLast();
          }
        });
      }
    });

    _logSubscription = _menuService.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.insert(0, log);
          if (_logs.length > 100) {
            _logs.removeLast();
          }
        });
      }
    });

    // Only initialize if not already initialized
    if (!_menuService.isInitialized) {
      await _menuService.initialize();
    }
    
    await _loadActiveConfigs();
  }

  Future<void> _loadActiveConfigs() async {
    final configs = await ContextMenuConfigService.getEnabledConfigs();
    setState(() {
      _activeConfigs = configs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final systemStatus = _menuService.getStatus();
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 700;
    final isAndroid = Platform.isAndroid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant AI Translator'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _menuService.reloadConfigurations();
              _loadActiveConfigs();
            },
            tooltip: 'Reload Configurations',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.indigo.shade700, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI-Powered Text Processing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompact ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAndroid
                          ? 'Select text in any app and tap "Instant AI Translator" from the selection menu.'
                          : 'Select text in any application and press Ctrl+Shift+M to access AI-powered text processing tools.',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    isAndroid
                        ? Row(
                            children: [
                              Icon(Icons.touch_app, color: Colors.indigo.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Android: Use the selection menu',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(Icons.keyboard, color: Colors.indigo.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hotkey: Ctrl+Shift+M',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade600,
                                  ),
                                ),
                              ),
                            ],
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
                          systemStatus['initialized'] ? Icons.check_circle : Icons.error,
                          color: systemStatus['initialized'] ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'System Status',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow(context, 'Service Status', _systemStatus),
                    _buildStatusRow(context, 'System Compatible', systemStatus['systemCompatible'] ? 'Yes' : 'No'),
                    _buildStatusRow(context, 'Desktop Environment', systemStatus['desktopEnvironment'] ?? 'Unknown'),
                    _buildStatusRow(context, 'Active Menus', '${systemStatus['activeMenus'] ?? 0}'),
                    _buildStatusRow(context, 'Monitoring', systemStatus['monitoring'] ? 'Active' : 'Inactive'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active Menu Items Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active Menu Items',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_activeConfigs.isEmpty)
                      const Text(
                        'No active menu items configured',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activeConfigs.map((config) => Chip(
                          avatar: Text(config.icon),
                          label: Text(config.label),
                          backgroundColor: Colors.blue.shade50,
                        )).toList(),
                      ),
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
                        Expanded(
                          child: Text(
                            'Recent Actions',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_recentActions.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              // Clear both local state and service data
                              await _clearRecentActions();
                            },
                            child: const Text('Clear'),
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
                        height: isCompact ? 160 : 200,
                        child: ListView.builder(
                          itemCount: _recentActions.length,
                          itemBuilder: (context, index) {
                            final action = _recentActions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: action.success 
                                      ? Colors.green.shade100 
                                      : Colors.red.shade100,
                                  child: Icon(
                                    action.success ? Icons.check : Icons.error,
                                    color: action.success ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  '${action.menuId.toUpperCase()} Action',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Input: "${action.originalText}"',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Output: "${action.processedText}"',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: action.success ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                    Text(
                                      _formatTimestamp(action.timestamp),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
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
                        Expanded(
                          child: Text(
                            'System Logs',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_logs.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              // Clear both local state and service data
                              await _clearLogs();
                            },
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: isCompact ? 160 : 200,
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
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1),
                                  child: Text(
                                    _logs[index],
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
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

  Widget _buildStatusRow(BuildContext context, String label, String value) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 480;

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
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

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<void> _clearRecentActions() async {
    // Clear both local state and service persistent data
    _menuService.clearActions();
    setState(() {
      _recentActions.clear();
    });
  }

  Future<void> _clearLogs() async {
    // Clear both local state and service persistent data
    _menuService.clearLogs();
    setState(() {
      _logs.clear();
    });
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent memory leaks
    _statusSubscription?.cancel();
    _actionSubscription?.cancel();
    _logSubscription?.cancel();
    
    // Don't dispose the singleton service as it's used by multiple screens
    // _menuService.dispose(); // Removed to prevent stream closure issues
    super.dispose();
  }
}
