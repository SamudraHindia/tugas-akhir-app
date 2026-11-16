import 'package:flutter/material.dart';

import '../screens/activity/activity_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/modul/modul_list_screen.dart';
import '../screens/profile/profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    if (index == _currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigateTab: _goToTab),
      const ModulListScreen(),
      const ActivityScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _goToTab,
          destinations: const [
            NavigationDestination(
              key: ValueKey('nav-beranda'),
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              key: ValueKey('nav-modul'),
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Modul',
            ),
            NavigationDestination(
              key: ValueKey('nav-aktivitas'),
              icon: Icon(Icons.timeline_outlined),
              selectedIcon: Icon(Icons.timeline_rounded),
              label: 'Aktivitas',
            ),
            NavigationDestination(
              key: ValueKey('nav-profil'),
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
