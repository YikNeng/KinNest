import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/bottom_nav_viewmodel.dart';

/// Bottom navigation scaffold for Elderly users
class ElderlyBottomNavScaffold extends StatelessWidget {
  final Widget child;

  const ElderlyBottomNavScaffold({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BottomNavViewModel(),
      child: _ElderlyBottomNavScaffoldBody(child: child),
    );
  }
}

class _ElderlyBottomNavScaffoldBody extends StatelessWidget {
  final Widget child;

  const _ElderlyBottomNavScaffoldBody({Key? key, required this.child})
    : super(key: key);

  // Define elderly navigation items
  static const List<_NavItem> _navItems = [
    _NavItem(
      route: '/elderly/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    _NavItem(
      route: '/elderly/reminders',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      label: 'Reminders',
    ),
    _NavItem(
      route: '/elderly/exercise',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Exercise',
    ),
    _NavItem(
      route: '/elderly/music',
      icon: Icons.music_note_outlined,
      activeIcon: Icons.music_note,
      label: 'Music',
    ),
    _NavItem(
      route: '/elderly/profile',
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
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: viewModel.currentIndex,
        onTap: (index) => _onTabTapped(context, index, viewModel),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[500],
        selectedFontSize: 14,
        unselectedFontSize: 14,
        iconSize: 28,
        elevation: 8,
        items: _navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon, size: 28),
            activeIcon: Icon(item.activeIcon, size: 28),
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
