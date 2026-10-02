import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  amount $realType,
  category $textType,
  note $textType,
  type $textType,
  date $textType
  )
''');

    await db.execute('''
CREATE TABLE budgets (
  id $idType,
  amount $realType,
  category $textType,
  month $integerType,
  year $integerType
  )
''');
  }

  // Transaction Operations
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    await db.insert('transactions', transaction.toMap());
    return transaction;
  }

  Future<TransactionModel> readTransaction(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      columns: ['id', 'amount', 'category', 'note', 'type', 'date'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<TransactionModel>> readAllTransactions() async {
    final db = await instance.database;
    const orderBy = 'date DESC';
    final result = await db.query('transactions', orderBy: orderBy);
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Budget Operations
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final db = await instance.database;
    await db.insert('budgets', budget.toMap());
    return budget;
  }

  Future<List<BudgetModel>> readBudgets(int month, int year) async {
    final db = await instance.database;
    final result = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return result.map((json) => BudgetModel.fromMap(json)).toList();
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final db = await instance.database;
    return db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(String id) async {
    final db = await instance.database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
