import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/production_main_screen.dart';
import 'screens/context_menu_manager_screen_v2.dart';
import 'screens/activity_monitor_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/navigation_sidebar.dart';
import 'services/gemini_ai_service.dart';

/// Register Android Process Text bridge:
/// - Android side uses a FlutterEngine to call this channel with:
///   method: "processText", args: { "text": String, "operation": String }
/// - We run the same processing path as Linux: GeminiAIService.processText
Future<void> _registerAndroidProcessChannel() async {
  // Ensure bindings so plugins (like shared_preferences) can initialize if needed
  WidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('instant_ai/process');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'processText') {
      final Map<dynamic, dynamic> raw = call.arguments as Map<dynamic, dynamic>? ?? {};
      final text = (raw['text'] as String?) ?? '';
      final operation = (raw['operation'] as String?) ?? '';
      // Use the same processing logic used elsewhere
      final result = await GeminiAIService.processText(text, operation);
      return result;
    }
    throw PlatformException(code: 'UNIMPLEMENTED', message: 'Method not implemented: ${call.method}');
  });
}

/// Background entrypoint for Android headless engine.
/// This avoids launching the Flutter UI when ProcessTextActivity needs AI processing.
@pragma('vm:entry-point')
void processMain() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget channel registration; engine stays alive long enough for a single call.
  _registerAndroidProcessChannel();
}

void main() async {
  await _registerAndroidProcessChannel();
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

  final List<Widget> _screens = const [
    ProductionMainScreen(),
    ContextMenuManagerScreenV2(),
    ActivityMonitorScreen(),
    SettingsScreen(),
  ];

  // Labels and icons for compact (mobile) bottom navigation
  static const _navItems = <({String label, IconData icon})>[
    (label: 'Home', icon: Icons.home_outlined),
    (label: 'Menus', icon: Icons.tune_outlined),
    (label: 'Activity', icon: Icons.history_outlined),
    (label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 700; // Adaptive breakpoint for phones/tablets

    if (isCompact) {
      // Mobile-friendly layout: AppBar + PageView + BottomNavigationBar
      return Scaffold(
        appBar: AppBar(
          title: const Text('Instant AI Translator'),
          centerTitle: true,
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: [
            for (final item in _navItems)
              NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
          ],
        ),
      );
    }

    // Desktop/tablet wide layout (original)
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
