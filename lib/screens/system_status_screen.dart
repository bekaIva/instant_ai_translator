import 'package:flutter/material.dart';

class SystemStatusScreen extends StatefulWidget {
  const SystemStatusScreen({super.key});

  @override
  State<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends State<SystemStatusScreen> {
  bool _systemIntegrationActive = false;
  bool _contextMenusRegistered = false;
  String _desktopEnvironment = 'GNOME';
  int _processedTextsToday = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Status'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(
              'System Integration',
              _systemIntegrationActive ? 'Active' : 'Inactive',
              _systemIntegrationActive ? Icons.check_circle : Icons.error,
              _systemIntegrationActive ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              'Context Menus',
              _contextMenusRegistered ? 'Registered' : 'Not Registered',
              _contextMenusRegistered ? Icons.menu : Icons.menu_open,
              _contextMenusRegistered ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildInfoCard('Desktop Environment', _desktopEnvironment),
            const SizedBox(height: 16),
            _buildInfoCard('Texts Processed Today', _processedTextsToday.toString()),
            const SizedBox(height: 32),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleSystemIntegration,
                  icon: Icon(_systemIntegrationActive ? Icons.stop : Icons.play_arrow),
                  label: Text(_systemIntegrationActive ? 'Stop Integration' : 'Start Integration'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _refreshStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Status'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String status, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
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

  Widget _buildInfoCard(String title, String value) {
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
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSystemIntegration() {
    setState(() {
      _systemIntegrationActive = !_systemIntegrationActive;
      if (_systemIntegrationActive) {
        _contextMenusRegistered = true;
      } else {
        _contextMenusRegistered = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _systemIntegrationActive 
            ? 'System integration started successfully' 
            : 'System integration stopped',
        ),
        backgroundColor: _systemIntegrationActive ? Colors.green : Colors.orange,
      ),
    );
  }

  void _refreshStatus() {
    // Simulate refreshing status
    setState(() {
      // In real implementation, this would check actual system status
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
