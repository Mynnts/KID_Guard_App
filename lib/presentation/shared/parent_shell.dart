import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../parent/parent_home_screen.dart';
import '../parent/parent_activity_screen.dart';
import '../parent/parent_settings_screen.dart';
import '../../core/utils/responsive_helper.dart';

/// Main shell for parent screens with bottom navigation
class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _selectedIndex = 0;

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    // Exit app but keep background services running
    await SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = ResponsiveHelper.of(context);

    final screens = const [
      ParentHomeScreen(),
      ParentActivityScreen(),
      ParentSettingsScreen(),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            elevation: 0,
            height: r.hp(70),
            backgroundColor: colorScheme.surface,
            indicatorColor: colorScheme.primaryContainer,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  size: r.iconSize(24),
                  color: Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  size: r.iconSize(24),
                  color: colorScheme.primary,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.insights_outlined,
                  size: r.iconSize(24),
                  color: Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.insights_rounded,
                  size: r.iconSize(24),
                  color: colorScheme.primary,
                ),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.settings_outlined,
                  size: r.iconSize(24),
                  color: Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.settings_rounded,
                  size: r.iconSize(24),
                  color: colorScheme.primary,
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
