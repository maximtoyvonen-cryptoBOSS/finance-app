import '../models/budget_model.dart';
import '../db/database_helper.dart';
import 'package:uuid/uuid.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  Future<List<BudgetModel>> getBudgets(int month, int year) async {
    return await _dbHelper.readBudgets(month, year);
  }

  Future<BudgetModel> addBudget(double amount, String category, int month, int year) async {
    final budget = BudgetModel(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      month: month,
      year: year,
    );
    return await _dbHelper.createBudget(budget);
  }

  Future<int> updateBudget(BudgetModel budget) async {
    return await _dbHelper.updateBudget(budget);
  }
}
