import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:habitflow/core/app_colors.dart';
import 'package:habitflow/core/app_date_utils.dart';
import 'package:habitflow/habits/habit_providers.dart';
import 'package:habitflow/habits/widgets/habit_category_badge.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  void _showRangePicker(BuildContext context, WidgetRef ref, AnalyticsRange current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Time Period',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                ListTile(
                  title: const Text('This Week', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: current == AnalyticsRange.thisWeek
                      ? const Icon(Icons.check, color: Color(0xFF15803D))
                      : null,
                  onTap: () {
                    ref.read(analyticsRangeProvider.notifier).state = AnalyticsRange.thisWeek;
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('This Month', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: current == AnalyticsRange.thisMonth
                      ? const Icon(Icons.check, color: Color(0xFF15803D))
                      : null,
                  onTap: () {
                    ref.read(analyticsRangeProvider.notifier).state = AnalyticsRange.thisMonth;
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('All Time', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: current == AnalyticsRange.allTime
                      ? const Icon(Icons.check, color: Color(0xFF15803D))
                      : null,
                  onTap: () {
                    ref.read(analyticsRangeProvider.notifier).state = AnalyticsRange.allTime;
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final range = ref.watch(analyticsRangeProvider);
    final analyticsAsync = ref.watch(appAnalyticsProvider);

    String rangeLabel;
    switch (range) {
      case AnalyticsRange.thisWeek:
        rangeLabel = 'This Week';
        break;
      case AnalyticsRange.thisMonth:
        rangeLabel = 'This Month';
        break;
      case AnalyticsRange.allTime:
        rangeLabel = 'All Time';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          GestureDetector(
            onTap: () => _showRangePicker(context, ref, range),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(
                    rangeLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF15803D)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: analyticsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (analytics) {
            final ratePercent = (analytics.overallCompletionRate * 100).round();

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. Overview Metric Cards Grid (2x2)
                Row(
                  children: [
                    // Completion Rate
                    Expanded(
                      child: _buildMetricCard(
                        isDark: isDark,
                        icon: Icons.donut_large_rounded,
                        iconColor: const Color(0xFF16A34A),
                        iconBg: const Color(0xFFDCFCE7),
                        value: '$ratePercent%',
                        label: 'Completion Rate',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Current Streak
                    Expanded(
                      child: _buildMetricCard(
                        isDark: isDark,
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBg: const Color(0xFFFEF3C7),
                        value: '${analytics.maxCurrentStreak}',
                        label: 'Current Streak',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Best Streak
                    Expanded(
                      child: _buildMetricCard(
                        isDark: isDark,
                        icon: Icons.emoji_events_rounded,
                        iconColor: const Color(0xFF9333EA),
                        iconBg: const Color(0xFFF3E8FF),
                        value: '${analytics.bestStreak}',
                        label: 'Best Streak',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Active Habits
                    Expanded(
                      child: _buildMetricCard(
                        isDark: isDark,
                        icon: Icons.track_changes_rounded,
                        iconColor: const Color(0xFF2563EB),
                        iconBg: const Color(0xFFDBEAFE),
                        value: '${analytics.habitPerformances.length}',
                        label: 'Active Habits',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Completion Trend Section (Screen 12)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completion Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$ratePercent% avg',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Graph Card with X-Axis Dates & Empty-state Styling
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF1F5F1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.035),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Y-Axis Markers (100, 50, 0) aligned with bars
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '100',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  '50',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32), // Space for X-axis labels
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Trend Columns (Bar + Date + Day)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: analytics.dailyTrends.map((trend) {
                            return _buildBarColumn(trend, isDark);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Habit Performance Header
                Text(
                  'Habit Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),

                // Habit Performance Rows
                ...analytics.habitPerformances.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildPerformanceRow(context, item: item, isDark: isDark),
                  );
                }).toList(),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF1F5F1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarColumn(DailyTrendItem trend, bool isDark) {
    final isToday = AppDateUtils.isToday(trend.date);
    final hasProgress = trend.completionRate > 0;
    final double safeRate = hasProgress ? trend.completionRate.clamp(0.12, 1.0) : 0.05;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Bar Container
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barHeight = constraints.maxHeight * safeRate;

                return Container(
                  width: 14,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: hasProgress
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF4ADE80),
                              Color(0xFF15803D),
                            ],
                          )
                        : null,
                    color: hasProgress
                        ? null
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: hasProgress
                        ? [
                            BoxShadow(
                              color: const Color(0xFF15803D).withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Day Number Label (e.g. 29)
        Text(
          DateFormat('d').format(trend.date),
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(height: 2),
        // Weekday Initial Label (e.g. T or Th)
        Text(
          DateFormat('E').format(trend.date).substring(0, 1),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRow(
    BuildContext context, {
    required HabitPerformanceItem item,
    required bool isDark,
  }) {
    final habit = item.habit;
    final percent = (item.completionRate * 100).round();

    return InkWell(
      onTap: () => context.push('/habit/${habit.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF1F5F1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            HabitCategoryBadge(category: habit.category, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        habit.name.isNotEmpty
                            ? '${habit.name[0].toUpperCase()}${habit.name.substring(1)}'
                            : habit.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Horizontal Animated Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.completionRate,
                      minHeight: 6,
                      backgroundColor:
                          isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
