import '../../../../core/utils/app_date_utils.dart';
import '../entities/habit.dart';
import '../entities/habit_completion.dart';

/// Detailed result of streak computation
class StreakResult {
  final int currentStreak;
  final int bestStreak;
  final int totalCompletions;
  final bool isCompletedToday;
  final bool isScheduledToday;

  const StreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompletions,
    required this.isCompletedToday,
    required this.isScheduledToday,
  });
}

/// Standalone, pure-Dart business logic engine for streak and completion calculations.
/// 
/// Documented Policy for Today's Incomplete Habit:
/// When a habit is scheduled for today but has not yet been marked completed,
/// it is considered "pending". The current streak remains active based on previously
/// completed scheduled days and is NOT reset to 0 until the day has passed (23:59:59)
/// without meeting the required target.
class StreakEngine {
  /// Calculates the current active streak for a [habit].
  ///
  /// [completionsMap] maps 'YYYY-MM-DD' strings to [HabitCompletion] objects.
  /// [referenceDate] defaults to today if null (useful for testing and historical replay).
  static int calculateCurrentStreak({
    required Habit habit,
    required Map<String, HabitCompletion> completionsMap,
    DateTime? referenceDate,
  }) {
    final refDate = AppDateUtils.normalize(referenceDate ?? DateTime.now());
    final habitStart = AppDateUtils.normalize(habit.startDate);

    if (refDate.isBefore(habitStart)) {
      return 0;
    }

    int streak = 0;
    final isScheduledToday = habit.isScheduledFor(refDate);
    final todayKey = AppDateUtils.toIsoDateString(refDate);
    final todayCompletion = completionsMap[todayKey];
    final completedToday = todayCompletion != null && todayCompletion.isCompleted;

    if (isScheduledToday && completedToday) {
      streak++;
    }

    // Step backwards starting from yesterday
    DateTime cursor = refDate.subtract(const Duration(days: 1));

    while (!cursor.isBefore(habitStart)) {
      if (habit.isScheduledFor(cursor)) {
        final dateKey = AppDateUtils.toIsoDateString(cursor);
        final completion = completionsMap[dateKey];
        if (completion != null && completion.isCompleted) {
          streak++;
        } else {
          // Missed scheduled day halts the streak sequence
          break;
        }
      }
      // Unscheduled days are skipped; they do not increment or break streaks
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Calculates the all-time longest (best) streak achieved by a [habit].
  static int calculateBestStreak({
    required Habit habit,
    required Map<String, HabitCompletion> completionsMap,
    DateTime? referenceDate,
  }) {
    final refDate = AppDateUtils.normalize(referenceDate ?? DateTime.now());
    final habitStart = AppDateUtils.normalize(habit.startDate);

    if (refDate.isBefore(habitStart)) {
      return 0;
    }

    int bestStreak = 0;
    int currentRun = 0;

    DateTime cursor = habitStart;

    while (!cursor.isAfter(refDate)) {
      if (habit.isScheduledFor(cursor)) {
        final isToday = AppDateUtils.isSameDay(cursor, refDate);
        final dateKey = AppDateUtils.toIsoDateString(cursor);
        final completion = completionsMap[dateKey];
        final isDone = completion != null && completion.isCompleted;

        if (isDone) {
          currentRun++;
          if (currentRun > bestStreak) {
            bestStreak = currentRun;
          }
        } else if (isToday) {
          // Incomplete today does not terminate the streak run before day ends
          // but doesn't increment the streak until completed.
        } else {
          // Missed past scheduled day resets the running streak
          currentRun = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return bestStreak;
  }

  /// Computes the complete [StreakResult] containing current, best, and overall metrics.
  static StreakResult calculateSummary({
    required Habit habit,
    required Map<String, HabitCompletion> completionsMap,
    DateTime? referenceDate,
  }) {
    final refDate = AppDateUtils.normalize(referenceDate ?? DateTime.now());
    final isScheduledToday = habit.isScheduledFor(refDate);
    final todayKey = AppDateUtils.toIsoDateString(refDate);
    final todayCompletion = completionsMap[todayKey];
    final isCompletedToday = todayCompletion != null && todayCompletion.isCompleted;

    final currentStreak = calculateCurrentStreak(
      habit: habit,
      completionsMap: completionsMap,
      referenceDate: refDate,
    );

    final bestStreak = calculateBestStreak(
      habit: habit,
      completionsMap: completionsMap,
      referenceDate: refDate,
    );

    int totalCompletions = 0;
    for (final completion in completionsMap.values) {
      if (completion.habitId == habit.id && completion.isCompleted) {
        totalCompletions++;
      }
    }

    return StreakResult(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalCompletions: totalCompletions,
      isCompletedToday: isCompletedToday,
      isScheduledToday: isScheduledToday,
    );
  }

  /// Calculates the completion rate (%) within a date range [startDate] to [endDate].
  ///
  /// Returns null if there are no eligible occurrences, preventing NaN errors.
  /// Formula: (completed eligible occurrences / total eligible occurrences) * 100
  static double? calculateCompletionRate({
    required Habit habit,
    required Map<String, HabitCompletion> completionsMap,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? referenceDate,
  }) {
    final refDate = AppDateUtils.normalize(referenceDate ?? DateTime.now());
    final start = AppDateUtils.normalize(startDate);
    final end = AppDateUtils.normalize(endDate);

    int totalEligible = 0;
    int completedEligible = 0;

    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      // Exclude future dates and dates before habit's creation
      if (!cursor.isAfter(refDate) && !cursor.isBefore(habit.startDate)) {
        if (habit.isScheduledFor(cursor)) {
          totalEligible++;
          final dateKey = AppDateUtils.toIsoDateString(cursor);
          final completion = completionsMap[dateKey];
          if (completion != null && completion.isCompleted) {
            completedEligible++;
          }
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (totalEligible == 0) {
      return null;
    }

    return (completedEligible / totalEligible) * 100.0;
  }
}
