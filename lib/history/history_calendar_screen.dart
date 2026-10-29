import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:habitflow/core/app_colors.dart';
import 'package:habitflow/core/app_date_utils.dart';
import 'package:habitflow/core/app_settings_provider.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_providers.dart';
import 'package:habitflow/habits/widgets/habit_category_badge.dart';
import 'package:habitflow/habits/widgets/progress_bottom_sheet.dart';

class HistoryCalendarScreen extends ConsumerStatefulWidget {
  const HistoryCalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryCalendarScreen> createState() => _HistoryCalendarScreenState();
}

class _HistoryCalendarScreenState extends ConsumerState<HistoryCalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = AppDateUtils.today;
    _currentMonth = DateTime(today.year, today.month);
    _selectedDay = today;
  }

  Future<void> _openProgressModal(
    BuildContext context,
    Habit habit,
    double currentProgress,
    DateTime date,
  ) async {
    final newProgress = await ProgressBottomSheet.show(
      context,
      habit: habit,
      currentProgress: currentProgress,
      dateSubtitle: AppDateUtils.isToday(date)
          ? 'Today, ${DateFormat('d MMM yyyy').format(date)}'
          : DateFormat('EEEE, d MMM yyyy').format(date),
    );

    if (newProgress != null) {
      await ref.read(dateCompletionsNotifierProvider.notifier).updateNumericProgress(
            habit: habit,
            date: date,
            newProgress: newProgress,
          );
      ref.invalidate(monthCompletionsProvider(_currentMonth));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final monthCompletionsAsync = ref.watch(monthCompletionsProvider(_currentMonth));
    final completionsMap = ref.watch(dateCompletionsNotifierProvider).value ?? {};

    final daysInMonth = AppDateUtils.getMonthDates(_currentMonth.year, _currentMonth.month);
    final firstDay = daysInMonth.first;
    final startWeekOn = ref.watch(startWeekOnProvider);
    final startOnMonday = startWeekOn == 'Monday';
    final paddingDays = startOnMonday
        ? firstDay.weekday - 1
        : firstDay.weekday % 7;
    final weekdayLabels = startOnMonday
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (allHabits) {
            final monthData = monthCompletionsAsync.value ?? {};

            // Calculate habits scheduled for the selected day
            final scheduledForDay =
                allHabits.where((h) => h.isScheduledFor(_selectedDay)).toList();

            final selectedDayKey = AppDateUtils.toIsoDateString(_selectedDay);
            final dayCompletions = monthData[selectedDayKey] ?? [];
            final dayCompletionsMap = {for (var c in dayCompletions) c.habitId: c};

            // If selected day is today, also merge with live dateCompletionsNotifier
            if (AppDateUtils.isSameDay(_selectedDay, AppDateUtils.today)) {
              dayCompletionsMap.addAll(completionsMap);
            }

            final dayCompletedCount = scheduledForDay.where((h) {
              final c = dayCompletionsMap[h.id];
              return c != null && c.isCompleted;
            }).length;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Month Header with Navigation (< December 2024 >)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 26),
                          onPressed: () {
                            setState(() {
                              _currentMonth =
                                  DateTime(_currentMonth.year, _currentMonth.month - 1);
                            });
                          },
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_currentMonth),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 26),
                          onPressed: () {
                            setState(() {
                              _currentMonth =
                                  DateTime(_currentMonth.year, _currentMonth.month + 1);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Weekday Column Labels (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: weekdayLabels
                          .map((d) => SizedBox(
                                width: 36,
                                child: Text(
                                  d,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // 3. Calendar Grid (7 columns matching Screen 11)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < paddingDays) {
                          return const SizedBox();
                        }

                        final dateIndex = index - paddingDays;
                        final date = daysInMonth[dateIndex];
                        final isSelected = AppDateUtils.isSameDay(date, _selectedDay);
                        final dateKey = AppDateUtils.toIsoDateString(date);

                        // Determine completion dot
                        final isPastOrToday = !AppDateUtils.isFuture(date);
                        final compsForDate = monthData[dateKey] ?? [];
                        final hasCompletion = compsForDate.any((c) => c.isCompleted);
                        final scheduledCount =
                            allHabits.where((h) => h.isScheduledFor(date)).length;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = date;
                            });
                            ref.read(selectedDateProvider.notifier).state = date;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF15803D)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF15803D).withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A)),
                                    fontWeight:
                                        isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (!isSelected && isPastOrToday && scheduledCount > 0) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasCompletion
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: paddingDays + daysInMonth.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, indent: 20, endIndent: 20),
                  ),
                ),

                // 4. Selected Day Header ("Mon, 16 Dec 2024" & "3/5 completed")
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEE, d MMM yyyy').format(_selectedDay),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '$dayCompletedCount/${scheduledForDay.length} completed',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Habit Cards for Selected Day (matching Screen 11)
                if (scheduledForDay.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Center(
                        child: Text(
                          'No habits scheduled for this date',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final habit = scheduledForDay[idx];
                          final completion = dayCompletionsMap[habit.id];
                          final isDone = completion != null && completion.isCompleted;
                          final currentProgress = completion?.progressValue ?? 0.0;

                          String subtitleText;
                          if (habit.trackingType == HabitTrackingType.binary) {
                            subtitleText = habit.category;
                          } else {
                            final unit = habit.unit ?? '';
                            subtitleText =
                                '${habit.targetValue.toInt()} $unit';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                context.push('/habit/${habit.id}');
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2D3B4E)
                                        : const Color(0xFFF1F5F1),
                                    width: 1,
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
                                  children: [
                                    // Left: 3D Category Icon
                                    HabitCategoryBadge(category: habit.category, size: 48),
                                    const SizedBox(width: 14),

                                    // Center: Habit Name & Target
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            habit.name.isNotEmpty
                                                ? '${habit.name[0].toUpperCase()}${habit.name.substring(1)}'
                                                : habit.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            subtitleText,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Right: Completion Button (Green Check or Plus)
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {
                                        if (habit.trackingType ==
                                            HabitTrackingType.binary) {
                                          await ref
                                              .read(dateCompletionsNotifierProvider.notifier)
                                              .toggleBinaryCompletion(
                                                  habit, _selectedDay);
                                          ref.invalidate(
                                              monthCompletionsProvider(_currentMonth));
                                          ref.invalidate(appAnalyticsProvider);
                                        } else {
                                          _openProgressModal(
                                              context, habit, currentProgress, _selectedDay);
                                        }
                                      },
                                      child: isDone
                                          ? Container(
                                              width: 38,
                                              height: 38,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF15803D),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            )
                                          : Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                                  width: 1.5,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.add,
                                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                                size: 20,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: scheduledForDay.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}
