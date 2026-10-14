import 'package:sqflite/sqflite.dart';

import '../models/farm_activity.dart';
import 'farm_database_service.dart';

class ActivityDatabaseService {
  ActivityDatabaseService._internal();

  static final ActivityDatabaseService instance =
      ActivityDatabaseService._internal();

  Future<Database> get _database async {
    return FarmDatabaseService.instance.database;
  }

  Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farm_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmId INTEGER,
        cropId INTEGER,
        title TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'Other',
        description TEXT NOT NULL DEFAULT '',
        activityDate TEXT NOT NULL,
        expense REAL NOT NULL DEFAULT 0,
        quantity REAL NOT NULL DEFAULT 0,
        quantityUnit TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // CREATE: Add a new farm activity.
  Future<int> addActivity(FarmActivity activity) async {
    final db = await _database;
    await _createTable(db);

    final data = activity.toMap()..remove('id');

    return db.insert(
      'farm_activities',
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // READ: Get all activities, newest date first.
  Future<List<FarmActivity>> getActivities() async {
    final db = await _database;
    await _createTable(db);

    final rows = await db.query(
      'farm_activities',
      orderBy: 'activityDate DESC, id DESC',
    );

    return rows.map(FarmActivity.fromMap).toList();
  }

  // READ: Get activities for one farm.
  Future<List<FarmActivity>> getActivitiesByFarm(int farmId) async {
    final db = await _database;
    await _createTable(db);

    final rows = await db.query(
      'farm_activities',
      where: 'farmId = ?',
      whereArgs: [farmId],
      orderBy: 'activityDate DESC, id DESC',
    );

    return rows.map(FarmActivity.fromMap).toList();
  }

  // READ: Get activities for one crop.
  Future<List<FarmActivity>> getActivitiesByCrop(int cropId) async {
    final db = await _database;
    await _createTable(db);

    final rows = await db.query(
      'farm_activities',
      where: 'cropId = ?',
      whereArgs: [cropId],
      orderBy: 'activityDate DESC, id DESC',
    );

    return rows.map(FarmActivity.fromMap).toList();
  }

  // UPDATE: Edit an existing activity.
  Future<int> updateActivity(FarmActivity activity) async {
    final activityId = activity.id;

    if (activityId == null) {
      throw ArgumentError('Activity ID is required to update an activity.');
    }

    final db = await _database;
    await _createTable(db);

    final data = activity.toMap()..remove('id');

    return db.update(
      'farm_activities',
      data,
      where: 'id = ?',
      whereArgs: [activityId],
    );
  }

  // DELETE: Remove one activity.
  Future<int> deleteActivity(int id) async {
    final db = await _database;
    await _createTable(db);

    return db.delete('farm_activities', where: 'id = ?', whereArgs: [id]);
  }

  // REPORT: Calculate total activity expenses.
  Future<double> getTotalExpense() async {
    final db = await _database;
    await _createTable(db);

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(expense), 0) AS total '
      'FROM farm_activities',
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // REPORT: Calculate expenses for one farm.
  Future<double> getExpenseByFarm(int farmId) async {
    final db = await _database;
    await _createTable(db);

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(expense), 0) AS total '
      'FROM farm_activities WHERE farmId = ?',
      [farmId],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // REPORT: Count all activities.
  Future<int> getActivityCount() async {
    final db = await _database;
    await _createTable(db);

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM farm_activities',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
