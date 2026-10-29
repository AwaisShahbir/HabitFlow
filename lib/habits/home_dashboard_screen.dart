import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:habitflow/core/app_colors.dart';
import 'package:habitflow/core/app_date_utils.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_providers.dart';
import 'package:habitflow/habits/widgets/habit_category_badge.dart';
import 'package:habitflow/habits/widgets/home_hero_progress.dart';
import 'package:habitflow/habits/widgets/plant_data.dart';
import 'package:habitflow/habits/widgets/progress_bottom_sheet.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening,';
    } else {
      return 'Good Night,';
    }
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '👋';
    } else if (hour >= 12 && hour < 17) {
      return '☀️';
    } else if (hour >= 17 && hour < 22) {
      return '✨';
    } else {
      return '🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final completionsAsync = ref.watch(dateCompletionsNotifierProvider);

    final weekDates = AppDateUtils.getWeekDates(selectedDate);

    return Scaffold(
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 6, right: 4),
        child: SizedBox(
          width: 58,
          height: 58,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF15803D),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            onPressed: () => context.push('/habit/new'),
            child: const Icon(Icons.add, size: 30),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF0F172A),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE8F8EE),
                    Color(0xFFF3FAF4),
                    Colors.white,
                  ],
                  stops: [0.0, 0.35, 1.0],
                ),
        ),
        child: SafeArea(
          bottom: false,
          child: habitsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
            error: (err, stack) => Center(
              child: Text('Error loading habits: $err'),
            ),
            data: (allHabits) {
              final completionsMap = completionsAsync.value ?? {};
              final selectedCategory = ref.watch(selectedCategoryFilterProvider);

              final scheduledForDate = allHabits.where((h) => h.isScheduledFor(selectedDate)).toList();
              final scheduledHabits = selectedCategory == null
                  ? scheduledForDate
                  : scheduledForDate.where((h) => h.category == selectedCategory).toList();

              final totalScheduled = scheduledForDate.length;
              final completedCount = scheduledForDate.where((h) {
                final c = completionsMap[h.id];
                return c != null && c.isCompleted;
              }).length;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Top Greeting & Avatar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Alex',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('👋', style: TextStyle(fontSize: 24)),
                                ],
                              ),
                            ],
                          ),
                          // Avatar
                          GestureDetector(
                            onTap: () => context.push('/categories'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.memory(
                                  kAvatarBytes,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(
                                      Icons.face_rounded,
                                      color: Color(0xFF15803D),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Hero Progress Section with Botanical Leaves
                  SliverToBoxAdapter(
                    child: HomeHeroProgress(
                      completedCount: completedCount,
                      totalCount: totalScheduled,
                      dateWeekday: DateFormat('EEE').format(selectedDate),
                      dateDayMonthYear: DateFormat('d MMM yyyy').format(selectedDate),
                    ),
                  ),

                  // 3. Horizontal Open Weekday Strip (matching GUI Screen 5)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: weekDates.map((date) {
                          final isSelected = AppDateUtils.isSameDay(date, selectedDate);
                          final dayName = DateFormat('E').format(date);
                          final dayNum = date.day.toString();

                          return GestureDetector(
                            onTap: () {
                              ref.read(selectedDateProvider.notifier).state = date;
                            },
                            child: Column(
                              children: [
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF15803D)
                                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                isSelected
                                    ? Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF15803D),
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF15803D).withOpacity(0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          dayNum,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        width: 38,
                                        height: 38,
                                        child: Center(
                                          child: Text(
                                            dayNum,
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Active Category Filter Indicator
                  if (selectedCategory != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list_rounded,
                                    size: 16,
                                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Category: $selectedCategory',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(selectedCategoryFilterProvider.notifier).state = null;
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 4. Section Title ("Today's Habits" + "3/5 completed")
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppDateUtils.isToday(selectedDate)
                                ? "Today's Habits"
                                : "${DateFormat('EEEE').format(selectedDate)}'s Habits",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '$completedCount/$totalScheduled completed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Habit Cards matching Screen 5
                  if (scheduledHabits.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: Color(0xFF15803D),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No habits scheduled today',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap the + button to add a habit',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final habit = scheduledHabits[index];
                            final completion = completionsMap[habit.id];
                            final isDone = completion != null && completion.isCompleted;
                            final currentProgress = completion?.progressValue ?? 0.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildExactHabitCard(
                                context,
                                habit: habit,
                                isDone: isDone,
                                currentProgress: currentProgress,
                                selectedDate: selectedDate,
                                isDark: isDark,
                              ),
                            );
                          },
                          childCount: scheduledHabits.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExactHabitCard(
    BuildContext context, {
    required Habit habit,
    required bool isDone,
    required double currentProgress,
    required DateTime selectedDate,
    required bool isDark,
  }) {
    String subtitleText;
    if (habit.trackingType == HabitTrackingType.binary) {
      subtitleText = habit.category;
    } else {
      final unit = habit.unit ?? '';
      if (currentProgress > 0) {
        subtitleText = '${_formatNumber(currentProgress)} / ${_formatNumber(habit.targetValue)} $unit';
      } else {
        subtitleText = '${_formatNumber(habit.targetValue)} $unit';
      }
    }

    return InkWell(
      onTap: () {
        context.push('/habit/${habit.id}');
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF1F5F1),
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
            // Left: Pastel 3D-styled Icon Bubble
            HabitCategoryBadge(category: habit.category, size: 48),
            const SizedBox(width: 14),

            // Center: Title & Subtitle
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
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Right: Interactive Action Button (White with + OR Emerald with ✓)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (habit.trackingType == HabitTrackingType.binary) {
                  ref
                      .read(dateCompletionsNotifierProvider.notifier)
                      .toggleBinaryCompletion(habit, selectedDate);
                } else {
                  _openProgressModal(context, habit, currentProgress, selectedDate);
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
    );
  }

  Future<void> _openProgressModal(
    BuildContext context,
    Habit habit,
    double currentProgress,
    DateTime selectedDate,
  ) async {
    final newProgress = await ProgressBottomSheet.show(
      context,
      habit: habit,
      currentProgress: currentProgress,
      dateSubtitle: AppDateUtils.isToday(selectedDate)
          ? 'Today, ${DateFormat('d MMM yyyy').format(selectedDate)}'
          : DateFormat('EEEE, d MMM yyyy').format(selectedDate),
    );

    if (newProgress != null) {
      await ref.read(dateCompletionsNotifierProvider.notifier).updateNumericProgress(
            habit: habit,
            date: selectedDate,
            newProgress: newProgress,
          );
    }
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return NumberFormat.decimalPattern().format(val.toInt());
    }
    return val.toStringAsFixed(1);
  }
}
