import 'package:flutter/material.dart';
import 'dart:async';
import '../services/activity_service.dart';
import '../services/context_menu_config_service.dart';

class ActivityMonitorScreen extends StatefulWidget {
  const ActivityMonitorScreen({super.key});

  @override
  State<ActivityMonitorScreen> createState() => _ActivityMonitorScreenState();
}

class _ActivityMonitorScreenState extends State<ActivityMonitorScreen> {
  final ActivityService _activityService = ActivityService();
  List<ProcessingActivity> _activities = [];
  ActivityStats _stats = const ActivityStats(
    totalActivities: 0,
    todayActivities: 0,
    averageProcessingTime: 0.0,
    mostUsedOperation: 'None',
    successfulActivities: 0,
    failedActivities: 0,
    operationCounts: {},
    sourceAppCounts: {},
  );
  StreamSubscription<List<ProcessingActivity>>? _activitiesSubscription;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<ContextMenuConfig> _contextMenuConfigs = [];

  @override
  void initState() {
    super.initState();
    _initializeActivityService();
  }

  Future<void> _initializeActivityService() async {
    await _activityService.initialize();
    
    // Load context menu configurations
    _contextMenuConfigs = await ContextMenuConfigService.getEnabledConfigs();
    
    // Get current state immediately (in case the service was already initialized)
    if (mounted) {
      setState(() {
        _activities = _searchQuery.isEmpty 
            ? _activityService.activities 
            : _activityService.searchActivities(_searchQuery);
        _stats = _activityService.calculateStats();
      });
    }
    
    // Listen to activity updates
    _activitiesSubscription = _activityService.activitiesStream.listen((activities) {
      if (mounted) {
        setState(() {
          _activities = _searchQuery.isEmpty 
              ? activities 
              : _activityService.searchActivities(_searchQuery);
          _stats = _activityService.calculateStats();
        });
      }
    });
  }

  /// Get display name for operation using context menu configs
  String _getOperationDisplayName(String menuId) {
    final config = _contextMenuConfigs.where((c) => c.id == menuId).firstOrNull;
    return config?.label ?? menuId;
  }

  /// Get icon for operation using context menu configs
  Widget _getOperationIcon(String menuId) {
    final config = _contextMenuConfigs.where((c) => c.id == menuId).firstOrNull;
    
    if (config != null) {
      // Use the operation field to determine icon
      IconData icon;
      Color color;
      
      final operation = config.operation.toLowerCase();
      if (operation.contains('translate')) {
        icon = Icons.translate;
        color = Colors.blue;
      } else if (operation.contains('grammar') || operation.contains('spellcheck')) {
        icon = Icons.spellcheck;
        color = Colors.green;
      } else if (operation.contains('improve') || operation.contains('enhance')) {
        icon = Icons.auto_fix_high;
        color = Colors.purple;
      } else if (operation.contains('summarize')) {
        icon = Icons.summarize;
        color = Colors.orange;
      } else if (operation.contains('explain')) {
        icon = Icons.help_outline;
        color = Colors.cyan;
      } else if (operation.contains('rewrite')) {
        icon = Icons.edit;
        color = Colors.indigo;
      } else if (operation.contains('expand')) {
        icon = Icons.expand_more;
        color = Colors.teal;
      } else {
        icon = Icons.text_fields;
        color = Colors.grey;
      }
      
      return Icon(icon, color: color);
    }
    
        // Fallback icon
    return const Icon(Icons.text_fields, color: Colors.grey);
  }

  /// Get display name for the most used operation
  String _getMostUsedOperationDisplayName() {
    if (_stats.mostUsedOperation == 'None') {
      return 'None';
    }
    return _getOperationDisplayName(_stats.mostUsedOperation);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Monitor'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_activities.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  return _buildActivityCard(_activities[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search activities...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _activities = _activityService.activities;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
          _activities = query.isEmpty 
              ? _activityService.activities 
              : _activityService.searchActivities(query);
        });
      },
    );
  }

  Widget _buildStatsRow() {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 700;

    if (isCompact) {
      // Stack the cards vertically on phones for readability
      return Column(
        children: [
          _buildStatCard(
            'Today',
            '${_stats.todayActivities}',
            Icons.today,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Avg. Time',
            '${_stats.averageProcessingTime.toStringAsFixed(1)}s',
            Icons.timer,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Most Used',
            _getMostUsedOperationDisplayName(),
            Icons.trending_up,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Success Rate',
            _stats.totalActivities > 0
                ? '${((_stats.successfulActivities / _stats.totalActivities) * 100).toStringAsFixed(0)}%'
                : '0%',
            Icons.check_circle,
            Colors.green,
          ),
        ],
      );
    }

    // Wide layout (desktop/tablet): row of four cards
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today',
            '${_stats.todayActivities}',
            Icons.today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avg. Time',
            '${_stats.averageProcessingTime.toStringAsFixed(1)}s',
            Icons.timer,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Most Used',
            _getMostUsedOperationDisplayName(),
            Icons.trending_up,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Success Rate',
            _stats.totalActivities > 0
                ? '${((_stats.successfulActivities / _stats.totalActivities) * 100).toStringAsFixed(0)}%'
                : '0%',
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ProcessingActivity activity) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getOperationIcon(activity.operation),
            const SizedBox(width: 8),
            Icon(
              activity.success ? Icons.check_circle : Icons.error,
              color: activity.success ? Colors.green : Colors.red,
              size: 16,
            ),
          ],
        ),
        title: Text(_getOperationDisplayName(activity.operation)),
        subtitle: Text(
          '${activity.sourceApp} • ${_formatTimestamp(activity.timestamp)} • ${activity.processingTime.toStringAsFixed(1)}s${activity.sourceApp == 'Activity Monitor' ? ' • Reprocessed' : ''}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!activity.success && activity.error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error: ${activity.error}',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Original Text:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(activity.originalText),
                ),
                const SizedBox(height: 16),
                Text(
                  activity.success ? 'Processed Text:' : 'Failed Processing Result:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: activity.success 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activity.processedText,
                    style: TextStyle(
                      color: activity.success 
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (activity.success) ...[
                      ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(activity.processedText),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Result'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _reprocessText(activity),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reprocess'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Activity Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Text processing activities will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) async {
    await _activityService.copyToClipboard(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _reprocessText(ProcessingActivity activity) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Reprocessing text...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      await _activityService.reprocessActivity(activity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('Text reprocessed! Check the new activity above.')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Scroll to Top',
              textColor: Colors.white,
              onPressed: () {
                // You could add scroll functionality here if needed
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Reprocessing failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all activity history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _activityService.clearActivities();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History cleared'),
                  ),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
