import 'package:flutter/material.dart';
import 'screens/production_main_screen.dart';
import 'screens/context_menu_manager_screen_v2.dart';
import 'screens/activity_monitor_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/navigation_sidebar.dart';

void main() {
  runApp(const InstantTranslatorApp());
}

class InstantTranslatorApp extends StatelessWidget {
  const InstantTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instant AI Translator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Blue theme for translator
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProductionMainScreen(),
    const ContextMenuManagerScreenV2(),
    const ActivityMonitorScreen(),
    const SettingsScreen(),
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
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

