import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/habits/add_habit_screen.dart';
import 'package:habitflow/habits/categories_screen.dart';
import 'package:habitflow/habits/habit_details_screen.dart';
import 'package:habitflow/habits/home_dashboard_screen.dart';
import 'package:habitflow/history/history_calendar_screen.dart';
import 'package:habitflow/onboarding/onboarding_screen.dart';
import 'package:habitflow/onboarding/splash_screen.dart';
import 'package:habitflow/settings/settings_screen.dart';
import 'package:habitflow/statistics/statistics_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/main/home',
            builder: (context, state) => const HomeDashboardScreen(),
          ),
          GoRoute(
            path: '/main/history',
            builder: (context, state) => const HistoryCalendarScreen(),
          ),
          GoRoute(
            path: '/main/stats',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/main/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/habit/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddHabitScreen(),
      ),
      GoRoute(
        path: '/habit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final habitId = state.pathParameters['id'] ?? '';
          return HabitDetailsScreen(habitId: habitId);
        },
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
    ],
  );
}

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({Key? key, required this.child}) : super(key: key);

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/main/home')) return 0;
    if (location.startsWith('/main/history')) return 1;
    if (location.startsWith('/main/stats')) return 2;
    if (location.startsWith('/main/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/main/home');
        break;
      case 1:
        context.go('/main/history');
        break;
      case 2:
        context.go('/main/stats');
        break;
      case 3:
        context.go('/main/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E9E5),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.calendar_today_rounded,
                  label: 'History',
                  isSelected: selectedIndex == 1,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  isSelected: selectedIndex == 2,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: selectedIndex == 3,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeColor = const Color(0xFF16A34A);
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? activeColor.withOpacity(0.2) : const Color(0xFFDCFCE7))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

