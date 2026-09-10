import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/models/transaction.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final TransactionRepository _repository = TransactionRepository();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<ExpenseTransaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await _repository.getTransactions();

    if (!mounted) return;

    setState(() {
      _transactions = transactions;
      _loading = false;
    });
  }

  List<ExpenseTransaction> get _monthTransactions {
    return _transactions.where((transaction) {
      return transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month;
    }).toList();
  }

  List<ExpenseTransaction> get _expenses {
    return _monthTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList();
  }

  List<ExpenseTransaction> get _income {
    return _monthTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .toList();
  }

  double _total(List<ExpenseTransaction> transactions) {
    return transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

  Map<String, double> _groupByCategory(List<ExpenseTransaction> transactions) {
    final result = <String, double>{};

    for (final transaction in transactions) {
      result.update(
        transaction.categoryName,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return result;
  }

  void _changeMonth(int amount) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + amount,
      );
    });
  }

  String _monthName() {
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

    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  static const List<Color> _chartColors = [
    Color(0xFF4F7CFF),
    Color(0xFF00B894),
    Color(0xFFFFA726),
    Color(0xFFE056FD),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF5C6BC0),
    Color(0xFF66BB6A),
    Color(0xFFFF7043),
  ];

  Color _categoryColor(String category, int index) {
    return _chartColors[index % _chartColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final incomeTotal = _total(_income);
    final expenseTotal = _total(_expenses);
    final balance = incomeTotal - expenseTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 16),
                  _buildSummary(incomeTotal, expenseTotal, balance),
                  const SizedBox(height: 24),
                  _buildPieSection(
                    title: 'Expenses by category',
                    transactions: _expenses,
                    emptyMessage: 'No expenses this month.',
                  ),
                  const SizedBox(height: 24),
                  _buildPieSection(
                    title: 'Income by category',
                    transactions: _income,
                    emptyMessage: 'No income this month.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _monthName(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(double income, double expenses, double balance) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Income',
            income,
            Colors.green,
            Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Expenses',
            expenses,
            Colors.red,
            Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Balance',
            balance,
            balance >= 0 ? Colors.green : Colors.red,
            Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                'UGX ${_formatAmount(amount)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieSection({
    required String title,
    required List<ExpenseTransaction> transactions,
    required String emptyMessage,
  }) {
    final grouped = _groupByCategory(transactions);
    final total = _total(transactions);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (grouped.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(emptyMessage)),
              )
            else ...[
              SizedBox(
                height: 240,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 42,
                    sections: grouped.entries.toList().asMap().entries.map((
                      indexedEntry,
                    ) {
                      final entry = indexedEntry.value;
                      final percentage = (entry.value / total) * 100;

                      return PieChartSectionData(
                        value: entry.value,
                        color: _categoryColor(entry.key, indexedEntry.key),
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 78,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...grouped.entries.toList().asMap().entries.map((indexedEntry) {
                final entry = indexedEntry.value;
                final percentage = (entry.value / total) * 100;
                final color = _categoryColor(entry.key, indexedEntry.key);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text('UGX ${_formatAmount(entry.value)}'),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
