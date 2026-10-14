import 'package:sqflite/sqflite.dart';

import '../models/farm_reminder.dart';
import 'farm_database_service.dart';

class ReminderService {
  ReminderService._internal();

  static final ReminderService instance = ReminderService._internal();

  Future<Database> get _database async {
    return FarmDatabaseService.instance.database;
  }

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farm_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmId INTEGER,
        cropId INTEGER,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL DEFAULT 'General',
        dueDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> addReminder(FarmReminder reminder) async {
    final db = await _database;
    await createTable(db);

    final data = reminder.toMap()..remove('id');

    return db.insert('farm_reminders', data);
  }

  Future<List<FarmReminder>> getReminders() async {
    final db = await _database;
    await createTable(db);

    final rows = await db.query('farm_reminders', orderBy: 'dueDate ASC');

    return rows.map(FarmReminder.fromMap).toList();
  }

  Future<int> updateReminder(FarmReminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Reminder ID is required for updating.');
    }

    final db = await _database;
    await createTable(db);

    final data = reminder.toMap()..remove('id');

    return db.update(
      'farm_reminders',
      data,
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await _database;
    await createTable(db);

    return db.delete('farm_reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> completeReminder(FarmReminder reminder) async {
    return updateReminder(reminder.copyWith(isCompleted: true));
  }

  Future<int> getPendingCount() async {
    final db = await _database;
    await createTable(db);

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM farm_reminders '
      'WHERE isCompleted = 0',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
