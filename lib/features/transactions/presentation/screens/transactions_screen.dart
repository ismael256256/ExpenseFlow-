import 'package:flutter/material.dart';

import '../../application/transaction_store.dart';

import '../../../dashboard/presentation/screens/dashboard_screen.dart';

import '../../domain/models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionStore _transactionStore = TransactionStore.instance;

  List<ExpenseTransaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _transactionStore.addListener(_onTransactionsChanged);
    _loadTransactions();
  }

  @override
  void dispose() {
    _transactionStore.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  void _onTransactionsChanged() {
    if (!mounted) return;
    setState(() {
      _transactions = _transactionStore.transactions;
      _loading = false;
    });
  }

  Future<void> _loadTransactions() async {
    final transactions = _transactionStore.transactions;

    if (!mounted) return;

    setState(() {
      _transactions = transactions;
      _loading = false;
    });
  }

  Future<void> _editTransaction(ExpenseTransaction transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialTransaction: transaction),
      ),
    );

    if (!mounted) return;

    await _loadTransactions();
  }

  Future<void> _deleteTransaction(ExpenseTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: Text('Delete "${transaction.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _transactionStore.deleteTransaction(transaction.id);

    if (!mounted) return;

    await _loadTransactions();
  }

  String _formatDateHeader(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _buildGroupedTransactions(),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );

          if (!mounted) return;
          await _loadTransactions();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
      case 'dining':
        return Icons.restaurant_outlined;
      case 'transport':
      case 'transportation':
        return Icons.directions_car_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'health':
      case 'healthcare':
        return Icons.local_hospital_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'salary':
      case 'income':
        return Icons.account_balance_wallet_outlined;
      case 'rent':
      case 'housing':
        return Icons.home_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  List<Widget> _buildGroupedTransactions() {
    final sortedTransactions = List<ExpenseTransaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final grouped = <String, List<ExpenseTransaction>>{};

    for (final transaction in sortedTransactions) {
      final key =
          '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}';

      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      final transactionsForDay = entry.value;
      final date = transactionsForDay.first.date;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Divider(
                  thickness: 1.5,
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );

      for (final transaction in transactionsForDay) {
        final isIncome = transaction.type == TransactionType.income;
        final color = isIncome ? Colors.green : Colors.red;

        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                ),
              ),
              title: Row(
                children: [
                  Icon(
                    _categoryIcon(transaction.categoryName),
                    size: 21,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transaction.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),

              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}UGX ${_formatAmount(transaction.amount)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _editTransaction(transaction),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 19,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _deleteTransaction(transaction),
                        child: Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your saved income and expenses will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
