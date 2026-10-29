import 'package:sqflite/sqflite.dart';
import 'package:habitflow/core/app_database.dart';
import 'package:habitflow/core/database_constants.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_completion.dart';
import 'package:habitflow/habits/habit_completion_model.dart';
import 'package:habitflow/habits/habit_model.dart';
import 'package:habitflow/habits/habit_repository.dart';

class HabitRepositoryImpl implements HabitRepository {
  final AppDatabase database;

  HabitRepositoryImpl({required this.database});

  @override
  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final db = await database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.tableHabits,
      where: includeArchived ? null : '${DatabaseConstants.colHabitIsArchived} = 0',
      orderBy: '${DatabaseConstants.colHabitCreatedAt} DESC',
    );

    return maps.map((m) => HabitModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    final db = await database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.tableHabits,
      where: '${DatabaseConstants.colHabitId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return HabitModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<void> createHabit(Habit habit) async {
    final db = await database.database;
    final model = HabitModel.fromEntity(habit);
    await db.insert(
      DatabaseConstants.tableHabits,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  @override
  Future<void> upsertHabit(Habit habit) async {
    final db = await database.database;
    final model = HabitModel.fromEntity(habit);
    await db.insert(
      DatabaseConstants.tableHabits,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final db = await database.database;
    final model = HabitModel.fromEntity(habit);
    await db.update(
      DatabaseConstants.tableHabits,
      model.toMap(),
      where: '${DatabaseConstants.colHabitId} = ?',
      whereArgs: [habit.id],
    );
  }

  @override
  Future<void> archiveHabit(String id, bool isArchived) async {
    final db = await database.database;
    await db.update(
      DatabaseConstants.tableHabits,
      {
        DatabaseConstants.colHabitIsArchived: isArchived ? 1 : 0,
        DatabaseConstants.colHabitUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DatabaseConstants.colHabitId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteHabit(String id) async {
    final db = await database.database;
    await db.delete(
      DatabaseConstants.tableHabits,
      where: '${DatabaseConstants.colHabitId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Map<String, HabitCompletion>> getCompletionsForHabit(String habitId) async {
    final db = await database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.tableCompletions,
      where: '${DatabaseConstants.colCompletionHabitId} = ?',
      whereArgs: [habitId],
      orderBy: '${DatabaseConstants.colCompletionLocalDate} ASC',
    );

    final map = <String, HabitCompletion>{};
    for (final m in maps) {
      final completion = HabitCompletionModel.fromMap(m).toEntity();
      map[completion.localDate] = completion;
    }
    return map;
  }

  @override
  Future<List<HabitCompletion>> getCompletionsForDate(String localDate) async {
    final db = await database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.tableCompletions,
      where: '${DatabaseConstants.colCompletionLocalDate} = ?',
      whereArgs: [localDate],
    );

    return maps.map((m) => HabitCompletionModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<List<HabitCompletion>> getAllCompletions() async {
    final db = await database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.tableCompletions,
      orderBy: '${DatabaseConstants.colCompletionLocalDate} ASC',
    );

    return maps.map((m) => HabitCompletionModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<void> recordProgress(HabitCompletion completion) async {
    final db = await database.database;
    final model = HabitCompletionModel.fromEntity(completion);

    await db.insert(
      DatabaseConstants.tableCompletions,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteCompletion(String habitId, String localDate) async {
    final db = await database.database;
    await db.delete(
      DatabaseConstants.tableCompletions,
      where: '${DatabaseConstants.colCompletionHabitId} = ? AND ${DatabaseConstants.colCompletionLocalDate} = ?',
      whereArgs: [habitId, localDate],
    );
  }

  @override
  Future<void> resetAllData() async {
    await database.clearAllData();
  }
}
