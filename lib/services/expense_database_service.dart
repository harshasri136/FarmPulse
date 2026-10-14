import 'package:sqflite/sqflite.dart';

import '../models/farm_expense.dart';
import 'farm_database_service.dart';

class ExpenseDatabaseService {
  ExpenseDatabaseService._internal();

  static final ExpenseDatabaseService instance =
      ExpenseDatabaseService._internal();

  Future<Database> get _db async =>
      FarmDatabaseService.instance.database;

  Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farm_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmId INTEGER,
        cropId INTEGER,
        title TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Other',
        amount REAL NOT NULL,
        expenseDate TEXT NOT NULL,
        paymentMethod TEXT NOT NULL DEFAULT 'Cash',
        notes TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> addExpense(FarmExpense expense) async {
    final db = await _db;
    await _ensureTable(db);

    final data = expense.toMap()..remove('id');
    return db.insert('farm_expenses', data);
  }

  Future<List<FarmExpense>> getExpenses() async {
    final db = await _db;
    await _ensureTable(db);

    final rows = await db.query(
      'farm_expenses',
      orderBy: 'expenseDate DESC, id DESC',
    );

    return rows.map(FarmExpense.fromMap).toList();
  }

  Future<int> updateExpense(FarmExpense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Expense ID is required.');
    }

    final db = await _db;
    await _ensureTable(db);

    final data = expense.toMap()..remove('id');

    return db.update(
      'farm_expenses',
      data,
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _db;
    await _ensureTable(db);

    return db.delete(
      'farm_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalExpenses() async {
    final db = await _db;
    await _ensureTable(db);

    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM farm_expenses',
    );

    return (rows.first['total'] as num).toDouble();
  }

  Future<double> getExpensesForFarm(int farmId) async {
    final db = await _db;
    await _ensureTable(db);

    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM farm_expenses WHERE farmId = ?',
      [farmId],
    );

    return (rows.first['total'] as num).toDouble();
  }

  Future<double> getExpensesForCrop(int cropId) async {
    final db = await _db;
    await _ensureTable(db);

    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM farm_expenses WHERE cropId = ?',
      [cropId],
    );

    return (rows.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getCategoryBreakdown() async {
    final db = await _db;
    await _ensureTable(db);

    final rows = await db.rawQuery('''
      SELECT category, SUM(amount) AS total
      FROM farm_expenses
      GROUP BY category
      ORDER BY total DESC
    ''');

    return {
      for (final row in rows)
        row['category'] as String:
            (row['total'] as num).toDouble(),
    };
  }

  Future<Map<String, double>> getMonthlyExpenses({
    int months = 6,
  }) async {
    final db = await _db;
    await _ensureTable(db);

    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);
    final rows = await db.rawQuery(
      '''
      SELECT substr(expenseDate, 1, 7) AS month,
             SUM(amount) AS total
      FROM farm_expenses
      WHERE expenseDate >= ?
      GROUP BY month
      ORDER BY month ASC
      ''',
      [start.toIso8601String()],
    );

    return {
      for (final row in rows)
        row['month'] as String: (row['total'] as num).toDouble(),
    };
  }
}
