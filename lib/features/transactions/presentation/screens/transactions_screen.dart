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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];

                  final isIncome = transaction.type == TransactionType.income;

                  final color = isIncome ? Colors.green : Colors.red;

                  return Card(
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
                      title: Text(
                        transaction.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${transaction.description}\n${_formatDate(transaction.date)}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}UGX ${_formatAmount(transaction.amount)}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
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
                  );
                },
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
