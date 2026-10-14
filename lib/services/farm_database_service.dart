
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/farm_model.dart';

class FarmDatabaseService {
  FarmDatabaseService._internal();

  static final FarmDatabaseService instance =
      FarmDatabaseService._internal();

  static const String _databaseName = 'farmpulse.db';
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final String databasePath;

    if (kIsWeb) {
      // Stable filename for browser IndexedDB persistence.
      databasePath = 'farmpulse_web.db';
    } else {
      final basePath = await getDatabasesPath();
      databasePath = p.join(basePath, _databaseName);
    }

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE farms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            location TEXT NOT NULL,
            area REAL NOT NULL DEFAULT 0,
            areaUnit TEXT NOT NULL DEFAULT 'acres',
            soilType TEXT NOT NULL DEFAULT '',
            description TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE crops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            farmId INTEGER NOT NULL,
            name TEXT NOT NULL,
            variety TEXT NOT NULL DEFAULT '',
            plantingDate TEXT NOT NULL,
            harvestDate TEXT NOT NULL,
            growthStage TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL,
            FOREIGN KEY (farmId) REFERENCES farms (id)
              ON DELETE CASCADE
          )
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<List<FarmModel>> getFarms() async {
    final db = await database;

    final rows = await db.query(
      'farms',
      orderBy: 'createdAt DESC',
    );

    return rows.map((row) => FarmModel.fromMap(row)).toList();
  }

  Future<int> insertFarm(FarmModel farm) async {
    final db = await database;

    final data = Map<String, Object?>.from(farm.toMap());
    data.remove('id');

    return db.insert(
      'farms',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateFarm(FarmModel farm) async {
    final db = await database;

    return db.update(
      'farms',
      farm.toMap(),
      where: 'id = ?',
      whereArgs: [farm.id],
    );
  }

  Future<int> deleteFarm(int id) async {
    final db = await database;

    // Delete associated crops explicitly for compatibility across platforms.
    await db.delete(
      'crops',
      where: 'farmId = ?',
      whereArgs: [id],
    );

    return db.delete(
      'farms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getFarmCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM farms');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalArea() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(area) AS totalArea FROM farms',
    );

    final value = result.first['totalArea'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }
}
