/// SQLite Database Table & Column Constants
class DatabaseConstants {
  static const String databaseName = 'habitflow.db';
  static const int databaseVersion = 1;

  // Habits Table
  static const String tableHabits = 'habits';
  static const String colHabitId = 'id';
  static const String colHabitName = 'name';
  static const String colHabitDescription = 'description';
  static const String colHabitCategory = 'category';
  static const String colHabitIcon = 'icon';
  static const String colHabitColorHex = 'color_hex';
  static const String colHabitTrackingType = 'tracking_type';
  static const String colHabitTargetValue = 'target_value';
  static const String colHabitUnit = 'unit';
  static const String colHabitScheduleType = 'schedule_type';
  static const String colHabitScheduledDays = 'scheduled_days';
  static const String colHabitStartDate = 'start_date';
  static const String colHabitReminderTime = 'reminder_time';
  static const String colHabitIsArchived = 'is_archived';
  static const String colHabitCreatedAt = 'created_at';
  static const String colHabitUpdatedAt = 'updated_at';

  // Habit Completions Table
  static const String tableCompletions = 'habit_completions';
  static const String colCompletionId = 'id';
  static const String colCompletionHabitId = 'habit_id';
  static const String colCompletionLocalDate = 'local_date';
  static const String colCompletionProgressValue = 'progress_value';
  static const String colCompletionIsCompleted = 'is_completed';
  static const String colCompletionCompletedAt = 'completed_at';

  // SQL Statements
  static const String createHabitsTableSql = '''
    CREATE TABLE $tableHabits (
      $colHabitId TEXT PRIMARY KEY,
      $colHabitName TEXT NOT NULL,
      $colHabitDescription TEXT,
      $colHabitCategory TEXT NOT NULL,
      $colHabitIcon TEXT NOT NULL,
      $colHabitColorHex TEXT NOT NULL,
      $colHabitTrackingType TEXT NOT NULL,
      $colHabitTargetValue REAL NOT NULL,
      $colHabitUnit TEXT,
      $colHabitScheduleType TEXT NOT NULL,
      $colHabitScheduledDays TEXT NOT NULL,
      $colHabitStartDate TEXT NOT NULL,
      $colHabitReminderTime TEXT,
      $colHabitIsArchived INTEGER NOT NULL DEFAULT 0,
      $colHabitCreatedAt INTEGER NOT NULL,
      $colHabitUpdatedAt INTEGER NOT NULL
    );
  ''';

  static const String createCompletionsTableSql = '''
    CREATE TABLE $tableCompletions (
      $colCompletionId TEXT PRIMARY KEY,
      $colCompletionHabitId TEXT NOT NULL,
      $colCompletionLocalDate TEXT NOT NULL,
      $colCompletionProgressValue REAL NOT NULL,
      $colCompletionIsCompleted INTEGER NOT NULL DEFAULT 0,
      $colCompletionCompletedAt INTEGER,
      FOREIGN KEY ($colCompletionHabitId) REFERENCES $tableHabits ($colHabitId) ON DELETE CASCADE,
      UNIQUE ($colCompletionHabitId, $colCompletionLocalDate)
    );
  ''';

  static const String createIndexesSql = '''
    CREATE INDEX idx_completions_habit_date ON $tableCompletions ($colCompletionHabitId, $colCompletionLocalDate);
    CREATE INDEX idx_completions_date ON $tableCompletions ($colCompletionLocalDate);
  ''';
}
