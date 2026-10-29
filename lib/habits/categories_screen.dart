import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/core/app_colors.dart';
import 'package:habitflow/habits/habit_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  static const List<Map<String, dynamic>> predefinedCategories = [
    {
      'name': 'All Habits',
      'icon': Icons.apps_rounded,
      'bgLight': Color(0xFF15803D),
      'bgDark': Color(0xFF166534),
      'iconBg': Colors.white24,
      'iconColor': Colors.white,
      'isSolid': true,
    },
    {
      'name': 'Health',
      'icon': Icons.favorite_rounded,
      'bgLight': Color(0xFFFFF1F2),
      'bgDark': Color(0xFF3B1219),
      'iconBg': Color(0xFFFFE4E6),
      'iconColor': Color(0xFFE11D48),
      'isSolid': false,
    },
    {
      'name': 'Fitness',
      'icon': Icons.fitness_center_rounded,
      'bgLight': Color(0xFFFEF3C7),
      'bgDark': Color(0xFF382305),
      'iconBg': Color(0xFFFDE68A),
      'iconColor': Color(0xFFD97706),
      'isSolid': false,
    },
    {
      'name': 'Learning',
      'icon': Icons.menu_book_rounded,
      'bgLight': Color(0xFFE0F2FE),
      'bgDark': Color(0xFF0C2A44),
      'iconBg': Color(0xFFBAE6FD),
      'iconColor': Color(0xFF0284C7),
      'isSolid': false,
    },
    {
      'name': 'Mindfulness',
      'icon': Icons.self_improvement_rounded,
      'bgLight': Color(0xFFF3E8FF),
      'bgDark': Color(0xFF28113F),
      'iconBg': Color(0xFFE9D5FF),
      'iconColor': Color(0xFF9333EA),
      'isSolid': false,
    },
    {
      'name': 'Productivity',
      'icon': Icons.bolt_rounded,
      'bgLight': Color(0xFFFEF9C3),
      'bgDark': Color(0xFF332F06),
      'iconBg': Color(0xFFFEF08A),
      'iconColor': Color(0xFFCA8A04),
      'isSolid': false,
    },
    {
      'name': 'Personal',
      'icon': Icons.star_rounded,
      'bgLight': Color(0xFFDCFCE7),
      'bgDark': Color(0xFF0F311C),
      'iconBg': Color(0xFFBBF7D0),
      'iconColor': Color(0xFF16A34A),
      'isSolid': false,
    },
    {
      'name': 'Other',
      'icon': Icons.grid_view_rounded,
      'bgLight': Color(0xFFF1F5F9),
      'bgDark': Color(0xFF1E293B),
      'iconBg': Color(0xFFE2E8F0),
      'iconColor': Color(0xFF64748B),
      'isSolid': false,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final selectedFilter = ref.watch(selectedCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category management: default categories active.')),
              );
            },
            child: const Text(
              'Manage',
              style: TextStyle(
                color: Color(0xFF15803D),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (habits) {
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: predefinedCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final cat = predefinedCategories[index];
                final name = cat['name'] as String;
                final icon = cat['icon'] as IconData;
                final isSolid = cat['isSolid'] as bool;

                final Color cardBg = isSolid
                    ? (isDark ? cat['bgDark'] as Color : cat['bgLight'] as Color)
                    : (isDark ? cat['bgDark'] as Color : cat['bgLight'] as Color);

                final Color iconBg = cat['iconBg'] as Color;
                final Color iconColor = cat['iconColor'] as Color;

                final count = name == 'All Habits'
                    ? habits.length
                    : habits.where((h) => h.category == name).length;

                final isCurrentFilter =
                    (name == 'All Habits' && selectedFilter == null) || (selectedFilter == name);

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        name == 'All Habits' ? null : name;
                    context.pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: isCurrentFilter && !isSolid
                          ? Border.all(color: const Color(0xFF15803D), width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isSolid
                              ? const Color(0xFF15803D).withOpacity(0.25)
                              : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon bubble
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: iconColor, size: 24),
                        ),

                        // Title & Habit Count
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSolid
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count ${count == 1 ? 'habit' : 'habits'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSolid
                                    ? Colors.white70
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
