import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/transaction.dart';

class TransactionRepository {
  static const String _storageKey = 'expenseflow_transactions';

  Future<List<ExpenseTransaction>> getTransactions() async {
    final preferences = await SharedPreferences.getInstance();

    final stored = preferences.getString(_storageKey);

    if (stored == null || stored.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(stored) as List;

      return decoded
          .map(
            (item) => ExpenseTransaction.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<ExpenseTransaction> transactions) async {
    final preferences = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      transactions.map((transaction) => transaction.toJson()).toList(),
    );

    await preferences.setString(_storageKey, encoded);
  }

  Future<void> addTransaction(ExpenseTransaction transaction) async {
    final transactions = await getTransactions();

    transactions.add(transaction);

    await saveTransactions(transactions);
  }

  Future<void> updateTransaction(ExpenseTransaction updatedTransaction) async {
    final transactions = await getTransactions();

    final index = transactions.indexWhere(
      (transaction) => transaction.id == updatedTransaction.id,
    );

    if (index == -1) {
      return;
    }

    transactions[index] = updatedTransaction;

    await saveTransactions(transactions);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final transactions = await getTransactions();

    transactions.removeWhere((transaction) => transaction.id == transactionId);

    await saveTransactions(transactions);
  }
}
