import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'category.dart';

class CategoryRepository {
  static const String _storageKey = 'expenseflow_categories';

  Future<List<ExpenseCategory>> getCategories() async {
    final preferences = await SharedPreferences.getInstance();

    final stored = preferences.getString(_storageKey);

    if (stored == null || stored.isEmpty) {
      final defaults = _defaultCategories();
      await saveCategories(defaults);
      return defaults;
    }

    try {
      final decoded = jsonDecode(stored) as List;

      return decoded
          .map(
            (item) => ExpenseCategory.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      final defaults = _defaultCategories();
      await saveCategories(defaults);
      return defaults;
    }
  }

  Future<void> saveCategories(List<ExpenseCategory> categories) async {
    final preferences = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      categories.map((category) => category.toJson()).toList(),
    );

    await preferences.setString(_storageKey, encoded);
  }

  Future<void> addCategory(ExpenseCategory category) async {
    final categories = await getCategories();

    categories.add(category);

    await saveCategories(categories);
  }

  Future<void> updateCategory(ExpenseCategory updatedCategory) async {
    final categories = await getCategories();

    final index = categories.indexWhere(
      (category) => category.id == updatedCategory.id,
    );

    if (index == -1) {
      return;
    }

    categories[index] = updatedCategory;

    await saveCategories(categories);
  }

  Future<void> deleteCategory(String categoryId) async {
    final categories = await getCategories();

    categories.removeWhere((category) => category.id == categoryId);

    await saveCategories(categories);
  }

  List<ExpenseCategory> _defaultCategories() {
    return [
      const ExpenseCategory(
        id: 'food',
        name: 'Food',
        type: CategoryType.expense,
        iconCodePoint: 0xe56c,
      ),
      const ExpenseCategory(
        id: 'groceries',
        name: 'Groceries',
        type: CategoryType.expense,
        iconCodePoint: 0xe59c,
      ),
      const ExpenseCategory(
        id: 'transport',
        name: 'Transport',
        type: CategoryType.expense,
        iconCodePoint: 0xe1d7,
      ),
      const ExpenseCategory(
        id: 'fuel',
        name: 'Fuel',
        type: CategoryType.expense,
        iconCodePoint: 0xe52f,
      ),
      const ExpenseCategory(
        id: 'rent',
        name: 'Rent',
        type: CategoryType.expense,
        iconCodePoint: 0xe88a,
      ),
      const ExpenseCategory(
        id: 'utilities',
        name: 'Utilities',
        type: CategoryType.expense,
        iconCodePoint: 0xe8b0,
      ),
      const ExpenseCategory(
        id: 'shopping',
        name: 'Shopping',
        type: CategoryType.expense,
        iconCodePoint: 0xe59c,
      ),
      const ExpenseCategory(
        id: 'entertainment',
        name: 'Entertainment',
        type: CategoryType.expense,
        iconCodePoint: 0xe405,
      ),
      const ExpenseCategory(
        id: 'health',
        name: 'Health',
        type: CategoryType.expense,
        iconCodePoint: 0xe3f9,
      ),
      const ExpenseCategory(
        id: 'education',
        name: 'Education',
        type: CategoryType.expense,
        iconCodePoint: 0xe80c,
      ),
      const ExpenseCategory(
        id: 'salary',
        name: 'Salary',
        type: CategoryType.income,
        iconCodePoint: 0xe8f6,
      ),
      const ExpenseCategory(
        id: 'business',
        name: 'Business',
        type: CategoryType.income,
        iconCodePoint: 0xe7ef,
      ),
      const ExpenseCategory(
        id: 'other-income',
        name: 'Other Income',
        type: CategoryType.income,
        iconCodePoint: 0xe8a1,
      ),
    ];
  }
}
