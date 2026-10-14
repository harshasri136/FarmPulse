
import 'package:sqflite/sqflite.dart';

import '../models/crop_model.dart';
import 'farm_database_service.dart';

class CropDatabaseService {
  CropDatabaseService._internal();

  static final CropDatabaseService instance =
      CropDatabaseService._internal();

  Future<Database> get _database async {
    final db = await FarmDatabaseService.instance.database;

    // Also ensure the table exists if the database was created earlier.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmId INTEGER NOT NULL,
        name TEXT NOT NULL,
        variety TEXT NOT NULL DEFAULT '',
        plantingDate TEXT NOT NULL,
        harvestDate TEXT NOT NULL,
        growthStage TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL
      )
    ''');

    return db;
  }

  Future<int> insertCrop(CropModel crop) async {
    final db = await _database;

    final data = Map<String, Object?>.from(crop.toMap());
    data.remove('id');

    return db.insert(
      'crops',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CropModel>> getCrops() async {
    final db = await _database;

    final rows = await db.query(
      'crops',
      orderBy: 'createdAt DESC',
    );

    return rows.map((row) => CropModel.fromMap(row)).toList();
  }

  Future<List<CropModel>> getCropsByFarm(int farmId) async {
    final db = await _database;

    final rows = await db.query(
      'crops',
      where: 'farmId = ?',
      whereArgs: [farmId],
      orderBy: 'createdAt DESC',
    );

    return rows.map((row) => CropModel.fromMap(row)).toList();
  }

  Future<int> updateCrop(CropModel crop) async {
    final db = await _database;

    return db.update(
      'crops',
      crop.toMap(),
      where: 'id = ?',
      whereArgs: [crop.id],
    );
  }

  Future<int> deleteCrop(int id) async {
    final db = await _database;

    return db.delete(
      'crops',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCropCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM crops',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteAllCropsForFarm(int farmId) async {
    final db = await _database;

    return db.delete(
      'crops',
      where: 'farmId = ?',
      whereArgs: [farmId],
    );
  }
}
