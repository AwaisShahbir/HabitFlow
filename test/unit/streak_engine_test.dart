import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/core/utils/app_date_utils.dart';
import 'package:habitflow/features/habits/domain/entities/habit.dart';
import 'package:habitflow/features/habits/domain/entities/habit_completion.dart';
import 'package:habitflow/features/habits/domain/services/streak_engine.dart';

void main() {
  group('StreakEngine Unit Tests', () {
    final habitStart = DateTime(2026, 10, 1); // Thursday
    
    final dailyHabit = Habit(
      id: 'habit-1',
      name: 'Drink Water',
      trackingType: HabitTrackingType.numeric,
      targetValue: 2000,
      unit: 'ml',
      scheduleType: HabitScheduleType.daily,
      startDate: habitStart,
      createdAt: habitStart,
      updatedAt: habitStart,
    );

    // Scheduled only on Mon (1), Wed (3), Fri (5)
    final mwfHabit = Habit(
      id: 'habit-2',
      name: 'Gym Workout',
      trackingType: HabitTrackingType.binary,
      scheduleType: HabitScheduleType.custom,
      scheduledDays: const [1, 3, 5],
      startDate: DateTime(2026, 10, 5), // Monday
      createdAt: DateTime(2026, 10, 5),
      updatedAt: DateTime(2026, 10, 5),
    );

    test('Consecutive completed days yield accurate current streak', () {
      final completions = <String, HabitCompletion>{
        '2026-10-01': const HabitCompletion(
          id: 'c1',
          habitId: 'habit-1',
          localDate: '2026-10-01',
          progressValue: 2000,
          isCompleted: true,
        ),
        '2026-10-02': const HabitCompletion(
          id: 'c2',
          habitId: 'habit-1',
          localDate: '2026-10-02',
          progressValue: 2000,
          isCompleted: true,
        ),
        '2026-10-03': const HabitCompletion(
          id: 'c3',
          habitId: 'habit-1',
          localDate: '2026-10-03',
          progressValue: 2000,
          isCompleted: true,
        ),
      };

      final streak = StreakEngine.calculateCurrentStreak(
        habit: dailyHabit,
        completionsMap: completions,
        referenceDate: DateTime(2026, 10, 3), // Saturday
      );

      expect(streak, equals(3));
    });

    test('Unscheduled days do not break a streak (MWF schedule)', () {
      // Mon Oct 5 (Done), Wed Oct 7 (Done). Reference date = Thu Oct 8 (unscheduled)
      final completions = <String, HabitCompletion>{
        '2026-10-05': const HabitCompletion(
          id: 'c1',
          habitId: 'habit-2',
          localDate: '2026-10-05',
          progressValue: 1,
          isCompleted: true,
        ),
        '2026-10-07': const HabitCompletion(
          id: 'c2',
          habitId: 'habit-2',
          localDate: '2026-10-07',
          progressValue: 1,
          isCompleted: true,
        ),
      };

      final streak = StreakEngine.calculateCurrentStreak(
        habit: mwfHabit,
        completionsMap: completions,
        referenceDate: DateTime(2026, 10, 8), // Thursday (unscheduled)
      );

      // Tuesday and Thursday are unscheduled and must not break or alter streak
      expect(streak, equals(2));
    });

    test('Today incomplete habit does not reset active streak before day ends', () {
      // Completed yesterday Oct 2, today Oct 3 is scheduled but incomplete
      final completions = <String, HabitCompletion>{
        '2026-10-02': const HabitCompletion(
          id: 'c1',
          habitId: 'habit-1',
          localDate: '2026-10-02',
          progressValue: 2000,
          isCompleted: true,
        ),
      };

      final streak = StreakEngine.calculateCurrentStreak(
        habit: dailyHabit,
        completionsMap: completions,
        referenceDate: DateTime(2026, 10, 3), // Today
      );

      // Current streak must remain 1 (from yesterday) rather than resetting to 0
      expect(streak, equals(1));
    });

    test('Completing habit today increments current streak', () {
      final completions = <String, HabitCompletion>{
        '2026-10-02': const HabitCompletion(
          id: 'c1',
          habitId: 'habit-1',
          localDate: '2026-10-02',
          progressValue: 2000,
          isCompleted: true,
        ),
        '2026-10-03': const HabitCompletion(
          id: 'c2',
          habitId: 'habit-1',
          localDate: '2026-10-03',
          progressValue: 2000,
          isCompleted: true,
        ),
      };

      final streak = StreakEngine.calculateCurrentStreak(
        habit: dailyHabit,
        completionsMap: completions,
        referenceDate: DateTime(2026, 10, 3),
      );

      expect(streak, equals(2));
    });

    test('A missed past scheduled day interrupts current streak', () {
      // Completed Oct 1, missed Oct 2, Oct 3 is reference date
      final completions = <String, HabitCompletion>{
        '2026-10-01': const HabitCompletion(
          id: 'c1',
          habitId: 'habit-1',
          localDate: '2026-10-01',
          progressValue: 2000,
          isCompleted: true,
        ),
      };

      final streak = StreakEngine.calculateCurrentStreak(
        habit: dailyHabit,
        completionsMap: completions,
        referenceDate: DateTime(2026, 10, 3), // Oct 2 was missed
      );

      expect(streak, equals(0));
    });

    test('Best streak tracks all-time historical peak', () {
      // Sequence: Oct 1, 2, 3 (Done) -> Streak of 3
      // Oct 4 (Missed)
      // Oct 5, 6 (Done) -> Streak of 2
      final completions = <String, HabitCompletion>{
        '2026-10-01': const HabitCompletion(id: '1', habitId: 'h1', localDate: '2026-10-01', progressValue: 1, isCompleted: true),
        '2026-10-02': const HabitCompletion(id: '2', habitId: 'h1', localDate: '2026-10-02', progressValue: 1, isCompleted: true),
        '2026-10-03': const HabitCompletion(id: '3', habitId: 'h1', localDate: '2026-10-03', progressValue: 1, isCompleted: true),
        '2026-10-05': const HabitCompletion(id: '4', habitId: 'h1', localDate: '2026-10-05', progressValue: 1, isCompleted: true),
        '2026-10-06': const HabitCompletion(id: '5', habitId: 'h1', localDate: '2026-10-06', progressValue: 1, isCompleted: true),
      };

      final best = StreakEngine.calculateBestStreak(
        habit: dailyHabit,
        completionsMap: completions,
        referenceDate: DateTime(2026, 10, 6),
      );

      final current = StreakEngine.calculateCurrentStreak(
        habit: dailyHabit,
        completionsMap: completions,
        referenceDate: DateTime(2026, 10, 6),
      );

      expect(best, equals(3));
      expect(current, equals(2));
    });

    test('Completion rate calculation handles partial dates and avoids NaN', () {
      // 5 scheduled occurrences, 3 completed -> 60%
      final completions = <String, HabitCompletion>{
        '2026-10-01': const HabitCompletion(id: '1', habitId: 'h1', localDate: '2026-10-01', progressValue: 1, isCompleted: true),
        '2026-10-02': const HabitCompletion(id: '2', habitId: 'h1', localDate: '2026-10-02', progressValue: 1, isCompleted: true),
        '2026-10-03': const HabitCompletion(id: '3', habitId: 'h1', localDate: '2026-10-03', progressValue: 1, isCompleted: true),
      };

      final rate = StreakEngine.calculateCompletionRate(
        habit: dailyHabit,
        completionsMap: completions,
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 5),
        referenceDate: DateTime(2026, 10, 5),
      );

      expect(rate, closeTo(60.0, 0.01));

      // Range before start date -> 0 eligible -> returns null (not NaN)
      final zeroEligibleRate = StreakEngine.calculateCompletionRate(
        habit: dailyHabit,
        completionsMap: completions,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 10),
        referenceDate: DateTime(2026, 10, 5),
      );

      expect(zeroEligibleRate, isNull);
    });
  });
}
