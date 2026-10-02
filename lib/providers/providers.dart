import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/budget_repository.dart';
import '../services/voice_service.dart';

final transactionRepositoryProvider = Provider((ref) => TransactionRepository());
final budgetRepositoryProvider = Provider((ref) => BudgetRepository());
final voiceServiceProvider = Provider((ref) => VoiceService());

final transactionsProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<TransactionModel>>>((ref) {
  return TransactionNotifier(ref.watch(transactionRepositoryProvider));
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final TransactionRepository _repository;

  TransactionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final transactions = await _repository.getTransactions();
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addTransactionFromInput(String input) async {
    try {
      final result = await _repository.processInput(input);
      if (result != null) {
        await loadTransactions();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }
}

final budgetsProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<List<BudgetModel>>>((ref) {
  return BudgetNotifier(ref.watch(budgetRepositoryProvider));
});

class BudgetNotifier extends StateNotifier<AsyncValue<List<BudgetModel>>> {
  final BudgetRepository _repository;

  BudgetNotifier(this._repository) : super(const AsyncValue.loading()) {
    final now = DateTime.now();
    loadBudgets(now.month, now.year);
  }

  Future<void> loadBudgets(int month, int year) async {
    try {
      final budgets = await _repository.getBudgets(month, year);
      state = AsyncValue.data(budgets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBudget(double amount, String category, int month, int year) async {
    await _repository.addBudget(amount, category, month, year);
    await loadBudgets(month, year);
  }
}
