import 'package:flutter/foundation.dart';

import '../data/transaction_repository.dart';
import '../domain/models/transaction.dart';

class TransactionStore extends ChangeNotifier {
  TransactionStore._();

  static final TransactionStore instance = TransactionStore._();

  final TransactionRepository _repository = TransactionRepository();

  List<ExpenseTransaction> _transactions = [];
  bool _isLoading = true;
  bool _initialized = false;

  List<ExpenseTransaction> get transactions => List.unmodifiable(_transactions);

  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    if (_initialized) return;

    _isLoading = true;
    notifyListeners();

    _transactions = await _repository.getTransactions();
    _initialized = true;
    _isLoading = false;

    notifyListeners();
  }

  Future<void> refresh() async {
    _transactions = await _repository.getTransactions();
    _isLoading = false;
    _initialized = true;

    notifyListeners();
  }

  Future<void> addTransaction(ExpenseTransaction transaction) async {
    await _repository.addTransaction(transaction);
    await refresh();
  }

  Future<void> updateTransaction(ExpenseTransaction transaction) async {
    await _repository.updateTransaction(transaction);
    await refresh();
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _repository.deleteTransaction(transactionId);
    await refresh();
  }
}
