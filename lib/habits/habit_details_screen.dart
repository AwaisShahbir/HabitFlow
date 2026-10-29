import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:habitflow/core/notification_service.dart';
import 'package:habitflow/core/app_colors.dart';
import 'package:habitflow/core/app_date_utils.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_completion.dart';
import 'package:habitflow/habits/habit_providers.dart';
import 'package:habitflow/habits/widgets/habit_category_badge.dart';
import 'package:habitflow/habits/widgets/progress_bottom_sheet.dart';
import 'add_habit_screen.dart';

class HabitDetailsScreen extends ConsumerWidget {
  final String habitId;

  const HabitDetailsScreen({Key? key, required this.habitId}) : super(key: key);

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
          'Are you sure you want to delete "${habit.name}"? All completions and history will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await NotificationService().cancelHabitReminder(habit.id);
              await ref.read(habitsNotifierProvider.notifier).deleteHabit(habit.id);
              ref.invalidate(dateCompletionsNotifierProvider);
              ref.invalidate(appAnalyticsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${habit.name}" successfully')),
                );
                context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(BuildContext context, WidgetRef ref, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Habit'),
        content: Text(
          'Archiving "${habit.name}" will stop scheduling new occurrences while keeping all past history and statistics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(habitsNotifierProvider.notifier).archiveHabit(habit.id, true);
              ref.invalidate(dateCompletionsNotifierProvider);
              ref.invalidate(appAnalyticsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Archived "${habit.name}"')),
                );
                context.pop();
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  String _formatSchedule(Habit habit) {
    switch (habit.scheduleType) {
      case HabitScheduleType.daily:
        return 'Every day';
      case HabitScheduleType.weekdays:
        return 'Weekdays (Mon - Fri)';
      case HabitScheduleType.custom:
        const days = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
        return habit.scheduledDays.map((d) => days[d] ?? '').join(', ');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final streakSummaryAsync = ref.watch(habitStreakSummaryProvider(habitId));
    final habitCompletionsAsync = ref.watch(habitCompletionsProvider(habitId));

    return habitsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (habits) {
        final habit = habits.firstWhere(
          (h) => h.id == habitId,
          orElse: () => Habit(
            id: habitId,
            name: 'Habit Not Found',
            category: 'Other',
            startDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final streakData = streakSummaryAsync.value;
        final completionsMap = habitCompletionsAsync.value ?? {};
        final currentStreak = streakData?.currentStreak ?? 0;
        final bestStreak = streakData?.bestStreak ?? (currentStreak > 0 ? currentStreak : 0);
        final totalDone = streakData?.totalCompletions ?? 0;

        // Calculate real historical completion rate for this habit
        int scheduledCount = 0;
        int completedCount = 0;
        final now = DateTime.now();
        for (int i = 0; i < 30; i++) {
          final d = DateTime(now.year, now.month, now.day - i);
          if (d.isBefore(DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day))) break;
          if (habit.isScheduledFor(d)) {
            scheduledCount++;
            final k = AppDateUtils.toIsoDateString(d);
            if (completionsMap[k]?.isCompleted == true) {
              completedCount++;
            }
          }
        }
        final completionRatePercent = scheduledCount > 0
            ? ((completedCount / scheduledCount) * 100).round()
            : (totalDone > 0 ? 100 : 0);

        final weekDates = AppDateUtils.getWeekDates(DateTime.now());
        final todayStr = AppDateUtils.toIsoDateString(now);
        final todayCompletion = completionsMap[todayStr];
        final isCompletedToday = todayCompletion?.isCompleted ?? false;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // 1. Curved Emerald Green Header (Screen 9)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF16A34A),
                              Color(0xFF14532D),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Top Bar Navigation & Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white, size: 20),
                                  onPressed: () => context.pop(),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.white, size: 22),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddHabitScreen(habitToEdit: habit),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.archive_outlined,
                                          color: Colors.white, size: 22),
                                      onPressed: () => _showArchiveDialog(context, ref, habit),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Color(0xFFFCA5A5), size: 22),
                                      onPressed: () => _showDeleteDialog(context, ref, habit),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Centered 3D Category Icon Badge
                            HabitCategoryBadge(category: habit.category, size: 68),
                            const SizedBox(height: 12),

                            // Habit Name
                            Text(
                              habit.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Category Label
                            Text(
                              habit.category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. 3 Metrics Cards (Current Streak, Best Streak, Completion)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                value: '$currentStreak',
                                label: 'Current Streak',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                value: '$bestStreak',
                                label: 'Best Streak',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                value: '$completionRatePercent%',
                                label: 'Completion',
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Detail Specification Cards (Screen 9)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF1F5F1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.025),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildConfigRow(
                              icon: Icons.track_changes_rounded,
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF15803D),
                              title: 'Target',
                              value:
                                  '${habit.targetValue.toInt()} ${habit.unit ?? (habit.trackingType == HabitTrackingType.binary ? 'completed' : '')}',
                              isDark: isDark,
                            ),
                            const Divider(height: 1),
                            _buildConfigRow(
                              icon: Icons.calendar_today_rounded,
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFD97706),
                              title: 'Schedule',
                              value: _formatSchedule(habit),
                              isDark: isDark,
                            ),
                            const Divider(height: 1),
                            _buildConfigRow(
                              icon: Icons.notifications_active_rounded,
                              iconBg: const Color(0xFFDBEAFE),
                              iconColor: const Color(0xFF2563EB),
                              title: 'Reminder',
                              value: habit.reminderTime ?? '09:00 AM',
                              isDark: isDark,
                            ),
                            const Divider(height: 1),
                            _buildConfigRow(
                              icon: Icons.category_rounded,
                              iconBg: const Color(0xFFF3E8FF),
                              iconColor: const Color(0xFF9333EA),
                              title: 'Category',
                              value: habit.category,
                              isDark: isDark,
                            ),
                            if (habit.description != null && habit.description!.isNotEmpty) ...[
                              const Divider(height: 1),
                              _buildConfigRow(
                                icon: Icons.notes_rounded,
                                iconBg: const Color(0xFFF1F5F9),
                                iconColor: const Color(0xFF64748B),
                                title: 'Notes',
                                value: habit.description!,
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. Progress This Week (Screen 9)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Progress This Week',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF1F5F1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: weekDates.map((date) {
                            final dateKey = AppDateUtils.toIsoDateString(date);
                            final comp = completionsMap[dateKey];
                            final isScheduled = habit.isScheduledFor(date);
                            final isPastOrToday = !AppDateUtils.isFuture(date);
                            final isDone = comp != null && comp.isCompleted;

                            double fillRate;
                            Color barColor;

                            if (isDone) {
                              fillRate = 1.0;
                              barColor = const Color(0xFF15803D);
                            } else if (comp != null && comp.progressValue > 0 && habit.trackingType == HabitTrackingType.numeric) {
                              fillRate = (comp.progressValue / habit.targetValue).clamp(0.25, 0.95);
                              barColor = const Color(0xFF22C55E);
                            } else if (isPastOrToday && isScheduled) {
                              fillRate = 0.22;
                              barColor = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
                            } else {
                              fillRate = 0.12;
                              barColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
                            }

                            final dayLabel = DateFormat('E').format(date);
                            final isTodayDate = AppDateUtils.isToday(date);

                            return Column(
                              children: [
                                Container(
                                  width: 16,
                                  height: 52 * fillRate,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dayLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isTodayDate ? FontWeight.w800 : FontWeight.w600,
                                    color: isTodayDate
                                        ? const Color(0xFF15803D)
                                        : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // 5. Large Bottom Action Button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompletedToday
                            ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                            : const Color(0xFF15803D),
                        foregroundColor: isCompletedToday
                            ? const Color(0xFF15803D)
                            : Colors.white,
                        elevation: isCompletedToday ? 0 : 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: isCompletedToday
                              ? const BorderSide(color: Color(0xFF86EFAC), width: 1.5)
                              : BorderSide.none,
                        ),
                      ),
                      icon: Icon(
                        isCompletedToday ? Icons.check_circle_rounded : Icons.check_rounded,
                        size: 22,
                      ),
                      label: Text(
                        habit.trackingType == HabitTrackingType.binary
                            ? (isCompletedToday ? 'Completed Today ✓' : 'Mark as Done')
                            : (isCompletedToday
                                ? 'Completed (${todayCompletion?.progressValue.toInt() ?? 0} / ${habit.targetValue.toInt()} ${habit.unit ?? ''})'
                                : 'Log Progress (${todayCompletion?.progressValue.toInt() ?? 0} / ${habit.targetValue.toInt()} ${habit.unit ?? ''})'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final today = DateTime.now();

                        if (habit.trackingType == HabitTrackingType.binary) {
                          await ref
                              .read(dateCompletionsNotifierProvider.notifier)
                              .toggleBinaryCompletion(habit, today);
                          ref.invalidate(habitStreakSummaryProvider(habitId));
                          ref.invalidate(habitCompletionsProvider(habitId));
                          ref.invalidate(appAnalyticsProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isCompletedToday
                                      ? 'Marked "${habit.name}" as incomplete'
                                      : 'Marked "${habit.name}" as completed! 🎉',
                                ),
                                backgroundColor: const Color(0xFF15803D),
                              ),
                            );
                          }
                        } else {
                          final comps = await ref
                              .read(habitRepositoryProvider)
                              .getCompletionsForDate(AppDateUtils.toIsoDateString(today));
                          final existing = comps.firstWhere(
                            (c) => c.habitId == habit.id,
                            orElse: () => HabitCompletion(
                              id: '',
                              habitId: habit.id,
                              localDate: '',
                              progressValue: 0,
                              isCompleted: false,
                            ),
                          );

                          final newProgress = await ProgressBottomSheet.show(
                            context,
                            habit: habit,
                            currentProgress: existing.progressValue,
                            dateSubtitle: 'Today, ${DateFormat('d MMM yyyy').format(today)}',
                          );

                          if (newProgress != null) {
                            await ref
                                .read(dateCompletionsNotifierProvider.notifier)
                                .updateNumericProgress(
                                  habit: habit,
                                  date: today,
                                  newProgress: newProgress,
                                );
                            ref.invalidate(habitStreakSummaryProvider(habitId));
                            ref.invalidate(habitCompletionsProvider(habitId));
                            ref.invalidate(appAnalyticsProvider);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Logged ${newProgress.toInt()} ${habit.unit ?? ''} for "${habit.name}"'),
                                  backgroundColor: const Color(0xFF15803D),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
