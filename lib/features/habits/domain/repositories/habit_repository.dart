import '../entities/habit.dart';
import '../entities/habit_completion.dart';

abstract class HabitRepository {
  /// Fetches all habits, optionally including archived habits.
  Future<List<Habit>> getAllHabits({bool includeArchived = false});

  /// Fetches a single habit by unique identifier.
  Future<Habit?> getHabitById(String id);

  /// Persists a new habit after validation.
  Future<void> createHabit(Habit habit);

  /// Updates an existing habit. Historical completions are preserved.
  Future<void> updateHabit(Habit habit);

  /// Archives or unarchives a habit.
  Future<void> archiveHabit(String id, bool isArchived);

  /// Permanently removes a habit and its completions.
  Future<void> deleteHabit(String id);

  /// Retrieves completions for a habit keyed by ISO date ('YYYY-MM-DD').
  Future<Map<String, HabitCompletion>> getCompletionsForHabit(String habitId);

  /// Retrieves all habit completions recorded for a specific calendar date.
  Future<List<HabitCompletion>> getCompletionsForDate(String localDate);

  /// Upserts completion progress for a habit on a given date.
  Future<void> recordProgress(HabitCompletion completion);

  /// Removes completion record for a habit on a given date (undo completion).
  Future<void> deleteCompletion(String habitId, String localDate);

  /// Erases all habits and completion records from database.
  Future<void> resetAllData();
}
