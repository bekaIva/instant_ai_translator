import 'package:flutter/material.dart';

class ActivityMonitorScreen extends StatefulWidget {
  const ActivityMonitorScreen({super.key});

  @override
  State<ActivityMonitorScreen> createState() => _ActivityMonitorScreenState();
}

class _ActivityMonitorScreenState extends State<ActivityMonitorScreen> {
  final List<ProcessingActivity> _activities = [
    ProcessingActivity(
      id: '1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      operation: 'translate',
      originalText: 'Hello, how are you doing today?',
      processedText: 'Hola, ¿cómo estás hoy?',
      sourceApp: 'VS Code',
      processingTime: 1.2,
    ),
    ProcessingActivity(
      id: '2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      operation: 'fix_grammar',
      originalText: 'This sentence have some error in grammer.',
      processedText: 'This sentence has some errors in grammar.',
      sourceApp: 'Notepad',
      processingTime: 0.8,
    ),
    ProcessingActivity(
      id: '3',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      operation: 'enhance',
      originalText: 'Make this better.',
      processedText: 'Please improve the quality and clarity of this content.',
      sourceApp: 'Gmail',
      processingTime: 1.5,
    ),
  ];

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _activities.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        return _buildActivityCard(_activities[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today',
            '${_activities.length}',
            Icons.today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avg. Time',
            '${_calculateAverageTime().toStringAsFixed(1)}s',
            Icons.timer,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Most Used',
            _getMostUsedOperation(),
            Icons.trending_up,
            Colors.orange,
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
        leading: _getOperationIcon(activity.operation),
        title: Text(_getOperationDisplayName(activity.operation)),
        subtitle: Text(
          '${activity.sourceApp} • ${_formatTimestamp(activity.timestamp)} • ${activity.processingTime}s',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  'Processed Text:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activity.processedText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(activity.processedText),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Result'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    const SizedBox(width: 8),
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

  Widget _getOperationIcon(String operation) {
    IconData icon;
    Color color;
    
    switch (operation) {
      case 'translate':
        icon = Icons.translate;
        color = Colors.blue;
        break;
      case 'fix_grammar':
        icon = Icons.spellcheck;
        color = Colors.green;
        break;
      case 'enhance':
        icon = Icons.auto_fix_high;
        color = Colors.purple;
        break;
      case 'summarize':
        icon = Icons.summarize;
        color = Colors.orange;
        break;
      default:
        icon = Icons.text_fields;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color);
  }

  String _getOperationDisplayName(String operation) {
    switch (operation) {
      case 'translate':
        return 'Translate';
      case 'fix_grammar':
        return 'Fix Grammar';
      case 'enhance':
        return 'Enhance';
      case 'summarize':
        return 'Summarize';
      default:
        return operation;
    }
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

  double _calculateAverageTime() {
    if (_activities.isEmpty) return 0.0;
    final total = _activities.fold<double>(0.0, (sum, activity) => sum + activity.processingTime);
    return total / _activities.length;
  }

  String _getMostUsedOperation() {
    if (_activities.isEmpty) return 'None';
    
    final operationCounts = <String, int>{};
    for (final activity in _activities) {
      operationCounts[activity.operation] = (operationCounts[activity.operation] ?? 0) + 1;
    }
    
    final mostUsed = operationCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return _getOperationDisplayName(mostUsed.key);
  }

  void _copyToClipboard(String text) {
    // TODO: Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _reprocessText(ProcessingActivity activity) {
    // TODO: Implement reprocessing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reprocessing text...'),
        duration: Duration(seconds: 2),
      ),
    );
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
            onPressed: () {
              setState(() {
                _activities.clear();
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History cleared'),
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProcessingActivity {
  final String id;
  final DateTime timestamp;
  final String operation;
  final String originalText;
  final String processedText;
  final String sourceApp;
  final double processingTime;

  const ProcessingActivity({
    required this.id,
    required this.timestamp,
    required this.operation,
    required this.originalText,
    required this.processedText,
    required this.sourceApp,
    required this.processingTime,
  });
}
