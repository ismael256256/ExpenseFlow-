enum TransactionType { income, expense }

class ExpenseTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final String description;
  final DateTime date;
  final String account;

  const ExpenseTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.date,
    required this.account,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'date': date.toIso8601String(),
      'account': account,
    };
  }

  factory ExpenseTransaction.fromJson(Map<String, dynamic> json) {
    return ExpenseTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      account: json['account'] as String,
    );
  }
}
