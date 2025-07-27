import 'package:flutter/material.dart';
import '../models/context_menu_item.dart';

class ContextMenuManagerScreen extends StatefulWidget {
  const ContextMenuManagerScreen({super.key});

  @override
  State<ContextMenuManagerScreen> createState() => _ContextMenuManagerScreenState();
}

class _ContextMenuManagerScreenState extends State<ContextMenuManagerScreen> {
  List<ContextMenuItem> _menuItems = [
    ContextMenuItem(
      id: '1',
      title: 'Translate',
      operation: 'translate',
      aiInstruction: 'Translate the following text to English. Maintain the original tone and meaning.',
      icon: Icons.translate,
      enabled: true,
      position: 0,
    ),
    ContextMenuItem(
      id: '2',
      title: 'Fix Grammar',
      operation: 'fix_grammar',
      aiInstruction: 'Fix any grammatical errors, spelling mistakes, and improve sentence structure while preserving the original meaning and tone.',
      icon: Icons.spellcheck,
      enabled: true,
      position: 1,
    ),
    ContextMenuItem(
      id: '3',
      title: 'Enhance',
      operation: 'enhance',
      aiInstruction: 'Improve the clarity, readability, and professional tone of the text while keeping the core message intact.',
      icon: Icons.auto_fix_high,
      enabled: true,
      position: 2,
    ),
    ContextMenuItem(
      id: '4',
      title: 'Summarize',
      operation: 'summarize',
      aiInstruction: 'Create a concise summary of the main points in the text, maintaining key information and context.',
      icon: Icons.summarize,
      enabled: false,
      position: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Context Menu Manager'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _addNewMenuItem,
            icon: const Icon(Icons.add),
            tooltip: 'Add New Menu Item',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure which operations appear in right-click context menus across all applications.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return _buildMenuItemCard(item, index);
                },
                onReorder: _reorderItems,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(ContextMenuItem item, int index) {
    return Card(
      key: ValueKey(item.id),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: item.enabled 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: item.enabled 
              ? null 
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operation: ${item.operation}',
              style: TextStyle(
                color: item.enabled 
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI Instruction: ${item.aiInstruction}',
              style: TextStyle(
                color: item.enabled 
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: item.enabled,
              onChanged: (value) => _toggleMenuItem(item.id, value),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplicate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _menuItems.removeAt(oldIndex);
      _menuItems.insert(newIndex, item);
      
      // Update positions
      for (int i = 0; i < _menuItems.length; i++) {
        _menuItems[i] = _menuItems[i].copyWith(position: i);
      }
    });
    
    _saveMenuConfiguration();
  }

  void _toggleMenuItem(String id, bool enabled) {
    setState(() {
      final index = _menuItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _menuItems[index] = _menuItems[index].copyWith(enabled: enabled);
      }
    });
    
    _saveMenuConfiguration();
  }

  void _handleMenuAction(String action, ContextMenuItem item) {
    switch (action) {
      case 'edit':
        _editMenuItem(item);
        break;
      case 'duplicate':
        _duplicateMenuItem(item);
        break;
      case 'delete':
        _deleteMenuItem(item);
        break;
    }
  }

  void _editMenuItem(ContextMenuItem item) {
    _showMenuItemDialog(item);
  }

  void _duplicateMenuItem(ContextMenuItem item) {
    setState(() {
      final newItem = item.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${item.title} Copy',
        position: _menuItems.length,
      );
      _menuItems.add(newItem);
    });
    _saveMenuConfiguration();
  }

  void _deleteMenuItem(ContextMenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _menuItems.removeWhere((menuItem) => menuItem.id == item.id);
              });
              _saveMenuConfiguration();
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addNewMenuItem() {
    _showMenuItemDialog(null);
  }

  void _showMenuItemDialog(ContextMenuItem? item) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final operationController = TextEditingController(text: item?.operation ?? '');
    final instructionController = TextEditingController(text: item?.aiInstruction ?? '');
    IconData selectedIcon = item?.icon ?? Icons.text_fields;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Menu Item' : 'Edit Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Menu Title',
                  hintText: 'e.g., Translate, Fix Grammar',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: operationController,
                decoration: const InputDecoration(
                  labelText: 'Operation',
                  hintText: 'e.g., translate, fix_grammar',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instructionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'AI Instruction',
                  hintText: 'Tell the AI what to do with the selected text...',
                  helperText: 'This instruction will be sent to the AI service to process the selected text.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(selectedIcon),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // TODO: Show icon picker dialog
                    },
                    child: const Text('Change Icon'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();
              final operation = operationController.text.trim();
              final instruction = instructionController.text.trim();
              
              if (title.isNotEmpty && operation.isNotEmpty && instruction.isNotEmpty) {
                setState(() {
                  if (item == null) {
                    // Add new item
                    final newItem = ContextMenuItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      operation: operation,
                      aiInstruction: instruction,
                      icon: selectedIcon,
                      enabled: true,
                      position: _menuItems.length,
                    );
                    _menuItems.add(newItem);
                  } else {
                    // Edit existing item
                    final index = _menuItems.indexWhere((menuItem) => menuItem.id == item.id);
                    if (index != -1) {
                      _menuItems[index] = _menuItems[index].copyWith(
                        title: title,
                        operation: operation,
                        aiInstruction: instruction,
                        icon: selectedIcon,
                      );
                    }
                  }
                });
                _saveMenuConfiguration();
                Navigator.of(context).pop();
              }
            },
            child: Text(item == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _saveMenuConfiguration() {
    // TODO: Save menu configuration to storage
    // This will be implemented when we add state management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu configuration saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
