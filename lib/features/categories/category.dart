enum CategoryType { income, expense }

class ExpenseCategory {
  final String id;
  final String name;
  final CategoryType type;
  final int iconCodePoint;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'income'
          ? CategoryType.income
          : CategoryType.expense,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }
}
