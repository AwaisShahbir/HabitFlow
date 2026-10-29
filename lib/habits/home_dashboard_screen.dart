import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/habit_order_service.dart';
import 'package:habitflow/core/sound_service.dart';
import 'package:habitflow/core/app_settings_provider.dart';
import 'package:habitflow/core/user_profile_provider.dart';
import 'package:habitflow/habits/widgets/confetti_overlay.dart';
import 'package:habitflow/habits/widgets/profile_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:habitflow/core/app_colors.dart';
import 'package:habitflow/core/app_date_utils.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_providers.dart';
import 'package:habitflow/habits/widgets/habit_category_badge.dart';
import 'package:habitflow/habits/widgets/home_hero_progress.dart';
import 'package:habitflow/habits/widgets/progress_bottom_sheet.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  final ConfettiOverlayController _confettiController = ConfettiOverlayController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isReordering = false;

  @override
  void dispose() {
    _confettiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
    final userProfile = ref.watch(userProfileProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final completionsAsync = ref.watch(dateCompletionsNotifierProvider);

    final startWeekOn = ref.watch(startWeekOnProvider);
    final weekDates = AppDateUtils.getWeekDates(selectedDate, startOnMonday: startWeekOn == 'Monday');

    return Scaffold(
      floatingActionButton: _isReordering
          ? null
          : Container(
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
      body: ConfettiOverlay(
        controller: _confettiController,
        child: Container(
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

                // Apply custom order
                final sortedAll = ref.watch(habitOrderProvider.notifier).sortHabits(allHabits);

                final scheduledForDate = sortedAll.where((h) => h.isScheduledFor(selectedDate)).toList();
                final categoryFiltered = selectedCategory == null
                    ? scheduledForDate
                    : scheduledForDate.where((h) => h.category == selectedCategory).toList();

                // Live search query filter
                final scheduledHabits = _searchQuery.isEmpty
                    ? categoryFiltered
                    : categoryFiltered.where((h) {
                        final q = _searchQuery.toLowerCase();
                        final inName = h.name.toLowerCase().contains(q);
                        final inCategory = h.category.toLowerCase().contains(q);
                        final inDesc = h.description != null && h.description!.toLowerCase().contains(q);
                        return inName || inCategory || inDesc;
                      }).toList();

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
                                      userProfile.name,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 24)),
                                  ],
                                ),
                              ],
                            ),
                            // Header Action: Categories & Profile Avatar
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.grid_view_rounded,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    size: 24,
                                  ),
                                  tooltip: 'Habit Categories',
                                  onPressed: () => context.push('/categories'),
                                ),
                                const SizedBox(width: 4),
                                UserAvatarWidget(
                                  size: 46,
                                  onTap: () => ProfileBottomSheet.show(context),
                                ),
                              ],
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

                    // 4. Interactive Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search habits by name, category...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
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

                    // 5. Section Header ("Today's Habits" + Reorder Icon + Count)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
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
                                const SizedBox(width: 6),
                                if (scheduledHabits.length > 1 && _searchQuery.isEmpty)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isReordering = !_isReordering;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _isReordering
                                            ? const Color(0xFFDCFCE7)
                                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isReordering ? Icons.check_circle_rounded : Icons.swap_vert_rounded,
                                            size: 16,
                                            color: _isReordering
                                                ? const Color(0xFF15803D)
                                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isReordering ? 'Done' : 'Reorder',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _isReordering
                                                  ? const Color(0xFF15803D)
                                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
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

                    if (_isReordering)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF15803D)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Drag cards by their handles to rearrange your daily routine.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // 6. Habit Cards matching Screen 5 OR Reorderable List
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
                                  child: Icon(
                                    _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.eco_rounded,
                                    color: const Color(0xFF15803D),
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No habits match "$_searchQuery"'
                                      : 'No habits scheduled today',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Try a different keyword or category'
                                      : 'Tap the + button to add a habit',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                    child: const Text('Clear Search'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (_isReordering)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverReorderableList(
                          itemCount: scheduledHabits.length,
                          onReorder: (oldIndex, newIndex) {
                            ref.read(habitOrderProvider.notifier).reorder(oldIndex, newIndex, scheduledHabits);
                          },
                          itemBuilder: (context, index) {
                            final habit = scheduledHabits[index];
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey(habit.id),
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildReorderableHabitCard(
                                  context,
                                  habit: habit,
                                  isDark: isDark,
                                  index: index,
                                ),
                              ),
                            );
                          },
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
                                  completedCount: completedCount,
                                  totalScheduled: totalScheduled,
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
      ),
    );
  }

  Widget _buildReorderableHabitCard(
    BuildContext context, {
    required Habit habit,
    required bool isDark,
    required int index,
  }) {
    return Container(
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
          HabitCategoryBadge(category: habit.category, size: 48),
          const SizedBox(width: 14),
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
                  habit.category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.drag_handle_rounded,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                size: 22,
              ),
            ),
          ),
        ],
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
    required int completedCount,
    required int totalScheduled,
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

            // Right: Interactive Action Button (White with + OR Emerald with check)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                if (habit.trackingType == HabitTrackingType.binary) {
                  final willComplete = !isDone;
                  // Play satisfying click audio & haptics
                  if (willComplete) {
                    ref.read(soundEffectsProvider.notifier).playCompletion();
                  } else {
                    HapticFeedback.lightImpact();
                  }

                  await ref
                      .read(dateCompletionsNotifierProvider.notifier)
                      .toggleBinaryCompletion(habit, selectedDate);

                  // 100% Day Completion Celebration
                  if (willComplete && (completedCount + 1 >= totalScheduled) && totalScheduled > 0 && context.mounted) {
                    _confettiController.play();
                    ref.read(soundEffectsProvider.notifier).playCelebrate();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF15803D),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        content: const Row(
                          children: [
                            Text('🎉', style: TextStyle(fontSize: 22)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'All habits completed for today! Awesome job!',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } else {
                  _openProgressModal(context, habit, currentProgress, selectedDate, completedCount, totalScheduled);
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
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    )
                  : Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add_rounded,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                        size: 22,
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
    int completedCount,
    int totalScheduled,
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
      final wasDone = currentProgress >= habit.targetValue;
      final nowDone = newProgress >= habit.targetValue;

      if (!wasDone && nowDone) {
        ref.read(soundEffectsProvider.notifier).playCompletion();
      } else {
        HapticFeedback.lightImpact();
      }

      await ref.read(dateCompletionsNotifierProvider.notifier).updateNumericProgress(
            habit: habit,
            date: selectedDate,
            newProgress: newProgress,
          );

      // 100% Day Completion Celebration
      if (!wasDone && nowDone && (completedCount + 1 >= totalScheduled) && totalScheduled > 0 && context.mounted) {
        _confettiController.play();
        ref.read(soundEffectsProvider.notifier).playCelebrate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Row(
              children: [
                Text('🎉', style: TextStyle(fontSize: 22)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All habits completed for today! Awesome job!',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return NumberFormat.decimalPattern().format(val.toInt());
    }
    return val.toStringAsFixed(1);
  }
}
