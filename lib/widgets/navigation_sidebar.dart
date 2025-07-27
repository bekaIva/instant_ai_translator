import 'package:flutter/material.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onIndexChanged,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Status'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_outlined),
          selectedIcon: Icon(Icons.menu),
          label: Text('Context Menus'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('Activity'),
        ),
      ],
    );
  }
}
