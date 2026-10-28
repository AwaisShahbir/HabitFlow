import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'database_constants.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, DatabaseConstants.databaseName);

    return await openDatabase(
      dbPath,
      version: DatabaseConstants.databaseVersion,
      onConfigure: (db) async {
        // Enforce foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await db.execute(DatabaseConstants.createHabitsTableSql);
        await db.execute(DatabaseConstants.createCompletionsTableSql);
        await db.execute(DatabaseConstants.createIndexesSql);
      },
    );
  }

  /// Closes database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Clears all data (used during Reset Data flow)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseConstants.tableCompletions);
      await txn.delete(DatabaseConstants.tableHabits);
    });
  }
}
