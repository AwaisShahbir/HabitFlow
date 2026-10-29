import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/app_database.dart';
import 'package:habitflow/core/app_date_utils.dart';
import 'package:habitflow/habits/habit_repository_impl.dart';
import 'package:habitflow/habits/in_memory_habit_repository.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_completion.dart';
import 'package:habitflow/habits/habit_repository.dart';
import 'package:habitflow/habits/streak_engine.dart';

/// Database instance provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Repository provider (automatically uses SQLite on mobile/desktop and InMemory on Web)
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  if (kIsWeb) {
    return InMemoryHabitRepository.instance;
  }
  final db = ref.watch(appDatabaseProvider);
  return HabitRepositoryImpl(database: db);
});

/// Currently selected date on the Dashboard (defaults to today)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return AppDateUtils.today;
});

/// Selected category filter (null means 'All Habits')
final selectedCategoryFilterProvider = StateProvider<String?>((ref) {
  return null;
});

/// Reactive state notifier managing all active habits
class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() async {
    final repository = ref.watch(habitRepositoryProvider);
    return repository.getAllHabits(includeArchived: false);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(habitRepositoryProvider);
      return repository.getAllHabits(includeArchived: false);
    });
  }

  Future<void> addHabit(Habit habit) async {
    final repository = ref.read(habitRepositoryProvider);
    await repository.createHabit(habit);
    await refresh();
  }

  Future<void> updateHabit(Habit habit) async {
    final repository = ref.read(habitRepositoryProvider);
    await repository.updateHabit(habit);
    await refresh();
  }

  Future<void> archiveHabit(String id, bool isArchived) async {
    final repository = ref.read(habitRepositoryProvider);
    await repository.archiveHabit(id, isArchived);
    await refresh();
  }

  Future<void> deleteHabit(String id) async {
    final repository = ref.read(habitRepositoryProvider);
    await repository.deleteHabit(id);
    await refresh();
  }
}

final habitsNotifierProvider =
    AsyncNotifierProvider<HabitsNotifier, List<Habit>>(() {
  return HabitsNotifier();
});

/// Completions for the currently selected date
class DateCompletionsNotifier extends AsyncNotifier<Map<String, HabitCompletion>> {
  @override
  Future<Map<String, HabitCompletion>> build() async {
    final date = ref.watch(selectedDateProvider);
    final repository = ref.watch(habitRepositoryProvider);
    final dateKey = AppDateUtils.toIsoDateString(date);

    final completionsList = await repository.getCompletionsForDate(dateKey);
    final map = <String, HabitCompletion>{};
    for (final c in completionsList) {
      map[c.habitId] = c;
    }
    return map;
  }

  Future<void> toggleBinaryCompletion(Habit habit, DateTime date) async {
    final repository = ref.read(habitRepositoryProvider);
    final dateKey = AppDateUtils.toIsoDateString(date);
    final currentMap = state.value ?? {};
    final existing = currentMap[habit.id];

    if (existing != null && existing.isCompleted) {
      // Undo completion
      await repository.deleteCompletion(habit.id, dateKey);
    } else {
      // Mark complete
      final newCompletion = HabitCompletion(
        id: '${habit.id}_$dateKey',
        habitId: habit.id,
        localDate: dateKey,
        progressValue: habit.targetValue,
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await repository.recordProgress(newCompletion);
    }

    ref.invalidateSelf();
  }

  Future<void> updateNumericProgress({
    required Habit habit,
    required DateTime date,
    required double newProgress,
  }) async {
    final repository = ref.read(habitRepositoryProvider);
    final dateKey = AppDateUtils.toIsoDateString(date);
    final isDone = newProgress >= habit.targetValue;

    final completion = HabitCompletion(
      id: '${habit.id}_$dateKey',
      habitId: habit.id,
      localDate: dateKey,
      progressValue: newProgress,
      isCompleted: isDone,
      completedAt: isDone ? DateTime.now() : null,
    );

    await repository.recordProgress(completion);
    ref.invalidateSelf();
  }
}

final dateCompletionsNotifierProvider =
    AsyncNotifierProvider<DateCompletionsNotifier, Map<String, HabitCompletion>>(() {
  return DateCompletionsNotifier();
});

/// Completions for an entire month, keyed by 'YYYY-MM-DD'
final monthCompletionsProvider =
    FutureProvider.family<Map<String, List<HabitCompletion>>, DateTime>((ref, month) async {
  // Watch completions notifier so calendar dots update immediately on any progress change
  ref.watch(dateCompletionsNotifierProvider);
  final repository = ref.watch(habitRepositoryProvider);
  final days = AppDateUtils.getMonthDates(month.year, month.month);
  final result = <String, List<HabitCompletion>>{};
  for (final day in days) {
    final key = AppDateUtils.toIsoDateString(day);
    final comps = await repository.getCompletionsForDate(key);
    result[key] = comps;
  }
  return result;
});

/// Family provider to fetch complete streak metrics for a specific habit
final habitStreakSummaryProvider =
    FutureProvider.family<StreakResult, String>((ref, habitId) async {
  // Invalidate when completions change
  ref.watch(dateCompletionsNotifierProvider);
  final repository = ref.watch(habitRepositoryProvider);
  final habit = await repository.getHabitById(habitId);

  if (habit == null) {
    return const StreakResult(
      currentStreak: 0,
      bestStreak: 0,
      totalCompletions: 0,
      isCompletedToday: false,
      isScheduledToday: false,
    );
  }

  final completionsMap = await repository.getCompletionsForHabit(habitId);
  return StreakEngine.calculateSummary(
    habit: habit,
    completionsMap: completionsMap,
  );
});

/// Family provider to fetch all historical completions for a single habit
final habitCompletionsProvider =
    FutureProvider.family<Map<String, HabitCompletion>, String>((ref, habitId) async {
  ref.watch(dateCompletionsNotifierProvider);
  final repository = ref.watch(habitRepositoryProvider);
  return repository.getCompletionsForHabit(habitId);
});

enum AnalyticsRange { thisMonth, thisWeek, allTime }

final analyticsRangeProvider =
    StateProvider<AnalyticsRange>((ref) => AnalyticsRange.thisMonth);

class HabitAnalytics {
  final double overallCompletionRate;
  final int maxCurrentStreak;
  final int bestStreak;
  final int totalCompletions;
  final List<HabitPerformanceItem> habitPerformances;
  final List<DailyTrendItem> dailyTrends;

  const HabitAnalytics({
    required this.overallCompletionRate,
    required this.maxCurrentStreak,
    required this.bestStreak,
    required this.totalCompletions,
    required this.habitPerformances,
    required this.dailyTrends,
  });
}

class HabitPerformanceItem {
  final Habit habit;
  final double completionRate;
  final int currentStreak;

  const HabitPerformanceItem({
    required this.habit,
    required this.completionRate,
    required this.currentStreak,
  });
}

class DailyTrendItem {
  final DateTime date;
  final double completionRate;

  const DailyTrendItem({
    required this.date,
    required this.completionRate,
  });
}

/// Global analytics provider calculating statistics across all active habits
final appAnalyticsProvider = FutureProvider<HabitAnalytics>((ref) async {
  // Re-run on completion changes
  ref.watch(dateCompletionsNotifierProvider);
  final range = ref.watch(analyticsRangeProvider);
  final repository = ref.watch(habitRepositoryProvider);
  final habits = await repository.getAllHabits(includeArchived: false);

  final today = AppDateUtils.today;
  int daysBack;
  switch (range) {
    case AnalyticsRange.thisWeek:
      daysBack = 7;
      break;
    case AnalyticsRange.thisMonth:
      daysBack = 30;
      break;
    case AnalyticsRange.allTime:
      daysBack = 60;
      break;
  }

  final rangeStart = today.subtract(Duration(days: daysBack - 1));
  final rangeDates = List.generate(
    daysBack,
    (i) => rangeStart.add(Duration(days: i)),
  );

  int maxStreak = 0;
  int maxBestStreak = 0;
  int totalScheduledAll = 0;
  int totalCompletedAll = 0;

  final performanceList = <HabitPerformanceItem>[];

  for (final habit in habits) {
    final completionsMap = await repository.getCompletionsForHabit(habit.id);
    final streak = StreakEngine.calculateCurrentStreak(
      habit: habit,
      completionsMap: completionsMap,
      referenceDate: today,
    );
    if (streak > maxStreak) {
      maxStreak = streak;
    }
    final best = StreakEngine.calculateBestStreak(
      habit: habit,
      completionsMap: completionsMap,
    );
    if (best > maxBestStreak) {
      maxBestStreak = best;
    }

    int scheduledCount = 0;
    int completedCount = 0;

    for (final date in rangeDates) {
      if (habit.isScheduledFor(date)) {
        scheduledCount++;
        final dateKey = AppDateUtils.toIsoDateString(date);
        final c = completionsMap[dateKey];
        if (c != null && c.isCompleted) {
          completedCount++;
        }
      }
    }

    totalScheduledAll += scheduledCount;
    totalCompletedAll += completedCount;

    final habitRate = scheduledCount > 0 ? (completedCount / scheduledCount) : 0.0;
    performanceList.add(HabitPerformanceItem(
      habit: habit,
      completionRate: habitRate,
      currentStreak: streak,
    ));
  }

  final overallRate =
      totalScheduledAll > 0 ? (totalCompletedAll / totalScheduledAll) : 0.78;

  // Compute daily trend for the last 10 days
  final trendDates = List.generate(10, (i) => today.subtract(Duration(days: 9 - i)));
  final dailyTrends = <DailyTrendItem>[];

  for (final tDate in trendDates) {
    final dateKey = AppDateUtils.toIsoDateString(tDate);
    final comps = await repository.getCompletionsForDate(dateKey);
    final scheduledForDate = habits.where((h) => h.isScheduledFor(tDate)).length;
    final completedForDate = comps.where((c) => c.isCompleted).length;

    final rate = scheduledForDate > 0
        ? (completedForDate / scheduledForDate).clamp(0.0, 1.0)
        : 0.0;
    dailyTrends.add(DailyTrendItem(date: tDate, completionRate: rate));
  }

  return HabitAnalytics(
    overallCompletionRate: overallRate,
    maxCurrentStreak: maxStreak,
    bestStreak: maxBestStreak,
    totalCompletions: totalCompletedAll,
    habitPerformances: performanceList,
    dailyTrends: dailyTrends,
  );
});

