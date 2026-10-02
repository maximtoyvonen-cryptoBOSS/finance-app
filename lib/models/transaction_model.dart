class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final String note;
  final String type; // 'expense' or 'income'
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      note: map['note'],
      type: map['type'],
      date: DateTime.parse(map['date']),
    );
  }
}
