import '../models/transaction_model.dart';
import '../db/database_helper.dart';
import '../services/llm_service.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final LlmService _llmService = LlmService();
  final Uuid _uuid = const Uuid();

  Future<List<TransactionModel>> getTransactions() async {
    return await _dbHelper.readAllTransactions();
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    return await _dbHelper.createTransaction(transaction);
  }

  Future<TransactionModel?> processInput(String input) async {
    final extractedData = await _llmService.extractTransactionData(input);
    if (extractedData != null) {
      final transaction = TransactionModel(
        id: _uuid.v4(),
        amount: (extractedData['amount'] as num).toDouble(),
        category: extractedData['category'] as String,
        note: extractedData['note'] as String,
        type: extractedData['type'] as String,
        date: DateTime.parse(extractedData['date'] as String),
      );
      return await addTransaction(transaction);
    }
    return null;
  }

  Future<int> deleteTransaction(String id) async {
    return await _dbHelper.deleteTransaction(id);
  }
}
