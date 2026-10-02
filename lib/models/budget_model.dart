class BudgetModel {
  final String id;
  final double amount;
  final String category; // e.g. "Overall", "Food", etc.
  final int month;
  final int year;

  BudgetModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'month': month,
      'year': year,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      month: map['month'],
      year: map['year'],
    );
  }
}
