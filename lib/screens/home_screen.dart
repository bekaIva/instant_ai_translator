import 'package:flutter/material.dart';
import '../widgets/navigation_sidebar.dart';
import 'context_menu_manager_screen.dart';
import 'settings_screen.dart';
import 'activity_monitor_screen.dart';
import 'system_status_screen.dart';
import 'phase3_demo_screen.dart';
import 'phase3_demo_screen_v2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SystemStatusScreen(),
    const ContextMenuManagerScreen(),
    const Phase3DemoScreen(),
    const Phase3DemoScreenV2(),
    const SettingsScreen(),
    const ActivityMonitorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            selectedIndex: _selectedIndex,
            onIndexChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
