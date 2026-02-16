import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar_widget.dart';

/// Mixin to add bottom navigation bar to any screen
/// Usage: class MyScreen extends StatefulWidget with BottomNavMixin
mixin BottomNavMixin<T extends StatefulWidget> on State<T> {
  int currentNavIndex = 2; // Default to Home

  void setNavIndex(int index) {
    setState(() => currentNavIndex = index);
  }

  Widget get bottomNavBar => AppBottomNavigationBar(
        currentIndex: currentNavIndex,
        onIndexChanged: setNavIndex,
      );

  /// Helper to determine current nav index based on route
  void updateNavIndexFromRoute(String route) {
    switch (route) {
      case '/matching':
        setNavIndex(0); // Match
        break;
      case '/conversations':
        setNavIndex(1); // Chat
        break;
      case '/':
        setNavIndex(2); // Home
        break;
      case '/profile':
        setNavIndex(3); // Profile
        break;
      case '/settings':
        setNavIndex(4); // Settings
        break;
    }
  }
}
