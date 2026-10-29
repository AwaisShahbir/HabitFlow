import 'package:habitflow/core/app_date_utils.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_completion.dart';
import 'package:habitflow/habits/habit_repository.dart';

/// In-memory repository implementation used for Flutter Web and preview mode.
/// Pre-seeded with the exact demo data from GUI Screen 5.
class InMemoryHabitRepository implements HabitRepository {
  static final InMemoryHabitRepository instance =
      InMemoryHabitRepository._init();

  final Map<String, Habit> _habits = {};
  final Map<String, HabitCompletion> _completions = {};

  InMemoryHabitRepository._init() {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    final today = AppDateUtils.today;
    final todayStr = AppDateUtils.toIsoDateString(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    // 1. Drink Water (Incomplete on dashboard -> + button)
    final water = Habit(
      id: 'habit_water',
      name: 'Drink Water',
      description: 'Stay hydrated for better health',
      category: 'Health',
      icon: 'water_drop',
      colorHex: '#2563EB',
      trackingType: HabitTrackingType.numeric,
      targetValue: 2000,
      unit: 'ml',
      scheduleType: HabitScheduleType.daily,
      startDate: twoDaysAgo,
      reminderTime: '09:00 AM',
      createdAt: twoDaysAgo,
      updatedAt: now,
    );

    // 2. Morning Exercise (Completed on dashboard -> green checkmark ✓)
    final exercise = Habit(
      id: 'habit_exercise',
      name: 'Morning Exercise',
      description: 'Daily cardio and strength routine',
      category: 'Fitness',
      icon: 'fitness_center',
      colorHex: '#EA580C',
      trackingType: HabitTrackingType.duration,
      targetValue: 30,
      unit: 'minutes',
      scheduleType: HabitScheduleType.daily,
      startDate: twoDaysAgo,
      reminderTime: '07:30 AM',
      createdAt: twoDaysAgo,
      updatedAt: now,
    );

    // 3. Read a Book (Incomplete on dashboard -> + button)
    final reading = Habit(
      id: 'habit_reading',
      name: 'Read a Book',
      description: 'Expand your perspective through daily reading',
      category: 'Learning',
      icon: 'menu_book',
      colorHex: '#D97706',
      trackingType: HabitTrackingType.duration,
      targetValue: 20,
      unit: 'minutes',
      scheduleType: HabitScheduleType.daily,
      startDate: twoDaysAgo,
      reminderTime: '08:30 PM',
      createdAt: twoDaysAgo,
      updatedAt: now,
    );

    // 4. Meditate (Incomplete on dashboard -> + button)
    final meditate = Habit(
      id: 'habit_meditate',
      name: 'Meditate',
      description: 'Cultivate inner calm and clarity',
      category: 'Mindfulness',
      icon: 'self_improvement',
      colorHex: '#7C3AED',
      trackingType: HabitTrackingType.duration,
      targetValue: 10,
      unit: 'minutes',
      scheduleType: HabitScheduleType.daily,
      startDate: twoDaysAgo,
      reminderTime: '06:45 AM',
      createdAt: twoDaysAgo,
      updatedAt: now,
    );

    // 5. Morning Stretch (Completed)
    final stretch = Habit(
      id: 'habit_stretch',
      name: 'Healthy Breakfast',
      description: 'Nutritious meal to start the day',
      category: 'Health',
      icon: 'restaurant',
      colorHex: '#059669',
      trackingType: HabitTrackingType.binary,
      targetValue: 1,
      unit: 'times',
      scheduleType: HabitScheduleType.daily,
      startDate: twoDaysAgo,
      createdAt: twoDaysAgo,
      updatedAt: now,
    );

    _habits[water.id] = water;
    _habits[exercise.id] = exercise;
    _habits[reading.id] = reading;
    _habits[meditate.id] = meditate;
    _habits[stretch.id] = stretch;

    // 2 of 5 completed today (Exercise, Stretch)
    _completions['${exercise.id}_$todayStr'] = HabitCompletion(
      id: 'c_exercise_today',
      habitId: exercise.id,
      localDate: todayStr,
      progressValue: 30,
      isCompleted: true,
      completedAt: now,
    );

    _completions['${stretch.id}_$todayStr'] = HabitCompletion(
      id: 'c_stretch_today',
      habitId: stretch.id,
      localDate: todayStr,
      progressValue: 1,
      isCompleted: true,
      completedAt: now,
    );

    // Seed 21 days of realistic historical completions for rich calendar dots & analytics
    for (int i = 1; i <= 21; i++) {
      final pastDate = today.subtract(Duration(days: i));
      final dateKey = AppDateUtils.toIsoDateString(pastDate);

      // Exercise: completed on all 18 past days (18-day streak!)
      if (i <= 18) {
        _completions['${exercise.id}_$dateKey'] = HabitCompletion(
          id: 'c_ex_$dateKey',
          habitId: exercise.id,
          localDate: dateKey,
          progressValue: 30,
          isCompleted: true,
          completedAt: pastDate,
        );
      }

      // Water: completed 17 of 20 days (85%)
      if (i % 5 != 0) {
        _completions['${water.id}_$dateKey'] = HabitCompletion(
          id: 'c_water_$dateKey',
          habitId: water.id,
          localDate: dateKey,
          progressValue: 2000,
          isCompleted: true,
          completedAt: pastDate,
        );
      }

      // Meditate: completed 18 of 20 days (90%)
      if (i % 10 != 0) {
        _completions['${meditate.id}_$dateKey'] = HabitCompletion(
          id: 'c_med_$dateKey',
          habitId: meditate.id,
          localDate: dateKey,
          progressValue: 10,
          isCompleted: true,
          completedAt: pastDate,
        );
      }

      // Reading: completed 12 of 20 days (60%)
      if (i % 2 == 0) {
        _completions['${reading.id}_$dateKey'] = HabitCompletion(
          id: 'c_read_$dateKey',
          habitId: reading.id,
          localDate: dateKey,
          progressValue: 20,
          isCompleted: true,
          completedAt: pastDate,
        );
      }

      // Healthy Breakfast: completed 16 of 20 days (80%)
      if (i % 4 != 0) {
        _completions['${stretch.id}_$dateKey'] = HabitCompletion(
          id: 'c_stretch_$dateKey',
          habitId: stretch.id,
          localDate: dateKey,
          progressValue: 1,
          isCompleted: true,
          completedAt: pastDate,
        );
      }
    }
  }

  @override
  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final list =
        _habits.values.where((h) => includeArchived || !h.isArchived).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    return _habits[id];
  }

  @override
  Future<void> createHabit(Habit habit) async {
    _habits[habit.id] = habit;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    _habits[habit.id] = habit;
  }

  @override
  Future<void> archiveHabit(String id, bool isArchived) async {
    final habit = _habits[id];
    if (habit != null) {
      _habits[id] = habit.copyWith(isArchived: isArchived);
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    _habits.remove(id);
    _completions.removeWhere((key, _) => key.startsWith('${id}_'));
  }

  @override
  Future<Map<String, HabitCompletion>> getCompletionsForHabit(
      String habitId) async {
    final map = <String, HabitCompletion>{};
    for (final entry in _completions.entries) {
      if (entry.value.habitId == habitId) {
        map[entry.value.localDate] = entry.value;
      }
    }
    return map;
  }

  @override
  Future<List<HabitCompletion>> getCompletionsForDate(String localDate) async {
    return _completions.values.where((c) => c.localDate == localDate).toList();
  }

  @override
  Future<void> recordProgress(HabitCompletion completion) async {
    final key = '${completion.habitId}_${completion.localDate}';
    _completions[key] = completion;
  }

  @override
  Future<void> deleteCompletion(String habitId, String localDate) async {
    final key = '${habitId}_$localDate';
    _completions.remove(key);
  }

  @override
  Future<void> resetAllData() async {
    _habits.clear();
    _completions.clear();
  }
}
