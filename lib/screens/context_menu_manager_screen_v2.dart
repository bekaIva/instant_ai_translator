import 'package:flutter/material.dart';
import 'dart:async';
import '../services/context_menu_config_service.dart';
import '../services/production_context_menu_service.dart';

class ContextMenuManagerScreenV2 extends StatefulWidget {
  const ContextMenuManagerScreenV2({Key? key}) : super(key: key);

  @override
  State<ContextMenuManagerScreenV2> createState() => _ContextMenuManagerScreenV2State();
}

class _ContextMenuManagerScreenV2State extends State<ContextMenuManagerScreenV2> {
  final ProductionContextMenuService _menuService = ProductionContextMenuService();
  List<ContextMenuConfig> _configs = [];
  bool _isLoading = true;
  String _status = 'Loading...';
  
  // Stream subscription management
  StreamSubscription<String>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
    _initializeService();
  }

  Future<void> _initializeService() async {
    // Get current status immediately
    setState(() {
      _status = _menuService.currentStatus;
    });
    
    // Cancel existing subscription
    await _statusSubscription?.cancel();
    
    // Listen to status updates
    _statusSubscription = _menuService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });

    // Only initialize if not already initialized
    if (!_menuService.isInitialized) {
      await _menuService.initialize();
    }
  }

  Future<void> _loadConfigurations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await ContextMenuConfigService.loadConfigs();
      setState(() {
        _configs = configs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load configurations: $e');
    }
  }

  Future<void> _toggleConfig(String id, bool enabled) async {
    final success = await ContextMenuConfigService.toggleConfig(id, enabled);
    if (success) {
      await _loadConfigurations();
      await _menuService.reloadConfigurations();
      _showSuccess('Configuration ${enabled ? 'enabled' : 'disabled'}');
    } else {
      _showError('Failed to update configuration');
    }
  }

  Future<void> _deleteConfig(String id) async {
    final confirmed = await _showConfirmDialog(
      'Delete Configuration',
      'Are you sure you want to delete this menu item?',
    );

    if (confirmed) {
      final success = await ContextMenuConfigService.deleteConfig(id);
      if (success) {
        await _loadConfigurations();
        await _menuService.reloadConfigurations();
        _showSuccess('Configuration deleted');
      } else {
        _showError('Failed to delete configuration');
      }
    }
  }

  Future<void> _addNewConfig() async {
    final result = await Navigator.of(context).push<ContextMenuConfig>(
      MaterialPageRoute(
        builder: (context) => const _ConfigEditDialog(),
      ),
    );

    if (result != null) {
      final success = await ContextMenuConfigService.addConfig(result);
      if (success) {
        await _loadConfigurations();
        await _menuService.reloadConfigurations();
        _showSuccess('Configuration added');
      } else {
        _showError('Failed to add configuration (ID may already exist)');
      }
    }
  }

  Future<void> _editConfig(ContextMenuConfig config) async {
    final result = await Navigator.of(context).push<ContextMenuConfig>(
      MaterialPageRoute(
        builder: (context) => _ConfigEditDialog(existingConfig: config),
      ),
    );

    if (result != null) {
      final success = await ContextMenuConfigService.updateConfig(config.id, result);
      if (success) {
        await _loadConfigurations();
        await _menuService.reloadConfigurations();
        _showSuccess('Configuration updated');
      } else {
        _showError('Failed to update configuration');
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await _showConfirmDialog(
      'Reset to Defaults',
      'This will replace all current configurations with the default ones. This action cannot be undone.',
    );

    if (confirmed) {
      final success = await ContextMenuConfigService.resetToDefaults();
      if (success) {
        await _loadConfigurations();
        await _menuService.reloadConfigurations();
        _showSuccess('Reset to defaults completed');
      } else {
        _showError('Failed to reset to defaults');
      }
    }
  }

  Future<void> _testMenuAction(ContextMenuConfig config) async {
    try {
      await _menuService.testMenuAction(config.id);
      _showInfo('Test action completed for: ${config.label}\nCheck the Main screen for results.');
    } catch (e) {
      _showError('Test action failed for ${config.label}: $e');
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _configs.isNotEmpty ? {
      'total': _configs.length,
      'enabled': _configs.where((c) => c.enabled).length,
      'disabled': _configs.where((c) => !c.enabled).length,
    } : <String, int>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Context Menu Manager'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewConfig,
            tooltip: 'Add New Menu Item',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetToDefaults();
                  break;
                case 'reload':
                  _loadConfigurations();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reload'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status and Stats Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'System Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow('Service Status', _status),
                        if (stats.isNotEmpty) ...[
                          _buildStatusRow('Total Menus', '${stats['total']}'),
                          _buildStatusRow('Enabled', '${stats['enabled']}'),
                          _buildStatusRow('Disabled', '${stats['disabled']}'),
                        ],
                      ],
                    ),
                  ),
                ),

                // Menu Configurations List
                Expanded(
                  child: _configs.isEmpty
                      ? const Center(
                          child: Text(
                            'No menu configurations found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _configs.length,
                          itemBuilder: (context, index) {
                            final config = _configs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: config.enabled 
                                      ? Colors.green.shade100 
                                      : Colors.grey.shade200,
                                  child: Text(
                                    config.icon,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                title: Text(
                                  config.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: config.enabled ? null : Colors.grey,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(config.description),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              config.operation,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade700,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Order: ${config.sortOrder}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact = MediaQuery.sizeOf(context).width < 400;

                                    if (isCompact) {
                                      // Collapse actions into a single overflow menu on phones
                                      return PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'test':
                                              _testMenuAction(config);
                                              break;
                                            case 'toggle':
                                              _toggleConfig(config.id, !config.enabled);
                                              break;
                                            case 'edit':
                                              _editConfig(config);
                                              break;
                                            case 'delete':
                                              _deleteConfig(config.id);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (config.enabled)
                                            const PopupMenuItem(
                                              value: 'test',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.play_arrow, color: Colors.green),
                                                  SizedBox(width: 8),
                                                  Text('Test'),
                                                ],
                                              ),
                                            ),
                                          PopupMenuItem(
                                            value: 'toggle',
                                            child: Row(
                                              children: [
                                                Icon(config.enabled ? Icons.toggle_on : Icons.toggle_off),
                                                const SizedBox(width: 8),
                                                Text(config.enabled ? 'Disable' : 'Enable'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    // Wide layout keeps explicit controls
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (config.enabled)
                                          IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            onPressed: () => _testMenuAction(config),
                                            tooltip: 'Test with Sample Text',
                                            color: Colors.green,
                                          ),
                                        Switch(
                                          value: config.enabled,
                                          onChanged: (value) => _toggleConfig(config.id, value),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            switch (value) {
                                              case 'edit':
                                                _editConfig(config);
                                                break;
                                              case 'delete':
                                                _deleteConfig(config.id);
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancel stream subscription
    _statusSubscription?.cancel();
    
    // Don't dispose the singleton service
    // _menuService.dispose(); // Removed to prevent conflicts
    super.dispose();
  }
}

class _ConfigEditDialog extends StatefulWidget {
  final ContextMenuConfig? existingConfig;

  const _ConfigEditDialog({this.existingConfig});

  @override
  State<_ConfigEditDialog> createState() => _ConfigEditDialogState();
}

class _ConfigEditDialogState extends State<_ConfigEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _labelController;
  late final TextEditingController _operationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _iconController;
  late final TextEditingController _sortOrderController;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final config = widget.existingConfig;
    
    _idController = TextEditingController(text: config?.id ?? '');
    _labelController = TextEditingController(text: config?.label ?? '');
    _operationController = TextEditingController(text: config?.operation ?? '');
    _descriptionController = TextEditingController(text: config?.description ?? '');
    _iconController = TextEditingController(text: config?.icon ?? '🔧');
    _sortOrderController = TextEditingController(text: '${config?.sortOrder ?? 0}');
    _enabled = config?.enabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingConfig != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID',
                  hintText: 'unique_identifier',
                  border: OutlineInputBorder(),
                ),
                enabled: !isEditing, // Don't allow ID changes when editing
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ID is required';
                  }
                  if (!RegExp(r'^[a-z_]+$').hasMatch(value)) {
                    return 'ID must contain only lowercase letters and underscores';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: '🌐 Translate',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Label is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _operationController,
                decoration: const InputDecoration(
                  labelText: 'AI System Instruction',
                  hintText: 'You are a professional translator. Translate the text...',
                  border: OutlineInputBorder(),
                  helperText: 'This instruction will be sent to the AI along with the user\'s selected text',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'AI instruction is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Translate text to another language',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _iconController,
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        hintText: '🌐',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Icon is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _sortOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Sort Order',
                        hintText: '1',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sort order is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Must be a number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enabled'),
                subtitle: const Text('Menu item will be shown in context menu'),
                value: _enabled,
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveConfig() {
    if (_formKey.currentState!.validate()) {
      final config = ContextMenuConfig(
        id: _idController.text,
        label: _labelController.text,
        operation: _operationController.text,
        description: _descriptionController.text,
        enabled: _enabled,
        icon: _iconController.text,
        sortOrder: int.parse(_sortOrderController.text),
      );

      Navigator.of(context).pop(config);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _labelController.dispose();
    _operationController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }
}
