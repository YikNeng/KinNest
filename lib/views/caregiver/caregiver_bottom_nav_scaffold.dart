import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/bottom_nav_viewmodel.dart';

/// Bottom navigation scaffold for Caregiver users

class CaregiverBottomNavScaffold extends StatelessWidget {
  final Widget child; // Current page content passed by GoRouter

  const CaregiverBottomNavScaffold({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BottomNavViewModel(),
      child: _CaregiverBottomNavScaffoldBody(child: child),
    );
  }
}

class _CaregiverBottomNavScaffoldBody extends StatelessWidget {
  final Widget child;

  const _CaregiverBottomNavScaffoldBody({Key? key, required this.child})
    : super(key: key);

  // Define caregiver navigation items
  static const List<_NavItem> _navItems = [
    _NavItem(
      route: '/caregiver/home',
      icon: Icons.house_outlined,
      activeIcon: Icons.house,
      label: 'Home',
    ),
    _NavItem(
      route: '/caregiver/groups',
      icon: Icons.group_outlined,
      activeIcon: Icons.group,
      label: 'Groups',
    ),
    _NavItem(
      route: '/caregiver/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<BottomNavViewModel>(context);

    // Sync current route with tab index
    _syncTabIndex(context, viewModel);

    return Scaffold(
      backgroundColor: Colors.white,
      body: child, // Display current page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: viewModel.currentIndex,
        onTap: (index) => _onTabTapped(context, index, viewModel),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[500],
        selectedFontSize: 16,
        unselectedFontSize: 16,
        iconSize: 32,
        elevation: 8,
        items: _navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon, size: 32),
            activeIcon: Icon(item.activeIcon, size: 32),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  /// Sync tab index with current route
  void _syncTabIndex(BuildContext context, BottomNavViewModel viewModel) {
    final String location = GoRouterState.of(context).uri.path;

    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) {
        if (viewModel.currentIndex != i) {
          // Update tab index without triggering navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.setIndex(i);
          });
        }
        break;
      }
    }
  }

  /// Handle tab tap
  void _onTabTapped(
    BuildContext context,
    int index,
    BottomNavViewModel viewModel,
  ) {
    if (viewModel.currentIndex != index) {
      viewModel.setIndex(index);
      context.go(_navItems[index].route);
    }
  }
}

/// Navigation item data class
class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
