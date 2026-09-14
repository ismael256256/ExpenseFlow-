import 'package:flutter/material.dart';

import '../../../transactions/application/transaction_store.dart';

import '../../../categories/category.dart';
import '../../../categories/category_repository.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';
import '../../../analytics/presentation/screens/analysis_screen.dart';
import '../../../transactions/domain/models/transaction.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeContent(
        onSeeAll: () => _selectTab(1),
        onAddTransaction: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          await TransactionStore.instance.refresh();
          if (mounted) {
            setState(() {});
          }
        },
      ),
      const TransactionsScreen(),
      const AnalysisScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
                await TransactionStore.instance.refresh();
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Icon(Icons.add),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Analysis',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final VoidCallback onSeeAll;
  final Future<void> Function() onAddTransaction;

  const _HomeContent({required this.onSeeAll, required this.onAddTransaction});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final TransactionStore _transactionStore = TransactionStore.instance;

  List<ExpenseTransaction> _recentTransactions = [];

  double get _totalIncome => _transactionStore.transactions
      .where((transaction) => transaction.type == TransactionType.income)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get _totalExpenses => _transactionStore.transactions
      .where((transaction) => transaction.type == TransactionType.expense)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get _totalBalance => _totalIncome - _totalExpenses;

  double get _financialHealth {
    if (_totalIncome <= 0) return 0;

    final savingsRate = ((_totalIncome - _totalExpenses) / _totalIncome) * 100;
    final score = savingsRate.clamp(0, 100).toDouble();

    return score;
  }

  double get _monthlyChange {
    final now = DateTime.now();
    final currentMonth = _transactionStore.transactions.where(
      (transaction) =>
          transaction.date.year == now.year &&
          transaction.date.month == now.month,
    );

    final income = currentMonth
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    final expenses = currentMonth
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    if (income == 0) return 0;
    return ((income - expenses) / income) * 100;
  }

  double get _previousMonthIncome {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);

    return _transactionStore.transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income &&
              transaction.date.year == previousMonth.year &&
              transaction.date.month == previousMonth.month,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  double get _currentMonthIncome {
    final now = DateTime.now();

    return _transactionStore.transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income &&
              transaction.date.year == now.year &&
              transaction.date.month == now.month,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  double get _monthlyIncomeChange {
    if (_previousMonthIncome <= 0) return 0;

    return ((_currentMonthIncome - _previousMonthIncome) /
            _previousMonthIncome) *
        100;
  }

  String _summaryChangeText(double change) {
    if (change == 0) {
      return 'No change vs last month';
    }

    final direction = change > 0 ? '↑' : '↓';
    return '$direction ${change.abs().round()}% vs last month';
  }

  Color _summaryChangeColor({required double change, required bool isExpense}) {
    if (change == 0) {
      return Colors.grey;
    }

    final favorable = isExpense ? change < 0 : change > 0;
    return favorable ? Colors.green : Colors.red;
  }

  double get _previousMonthExpenses {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);

    return _transactionStore.transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense &&
              transaction.date.year == previousMonth.year &&
              transaction.date.month == previousMonth.month,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  double get _currentMonthExpenses {
    final now = DateTime.now();

    return _transactionStore.transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense &&
              transaction.date.year == now.year &&
              transaction.date.month == now.month,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  double get _monthlySpendingChange {
    if (_previousMonthExpenses <= 0) return 0;

    return ((_currentMonthExpenses - _previousMonthExpenses) /
            _previousMonthExpenses) *
        100;
  }

  String get _smartSpendingInsight {
    final transactions = _transactionStore.transactions;

    if (transactions.isEmpty) {
      return 'Add a few transactions to start receiving personalized spending insights.';
    }

    if (_totalIncome <= 0 && _totalExpenses > 0) {
      return 'Your expenses are higher than your recorded income. Review recent spending and add any missing income.';
    }

    if (_totalIncome <= 0) {
      return 'Keep recording your income and expenses to build a clearer picture of your finances.';
    }

    if (_totalExpenses > _totalIncome) {
      return 'You are spending more than your recorded income. Consider reviewing your largest expense categories.';
    }

    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);

    final currentCategoryTotals = <String, double>{};
    final previousCategoryTotals = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) continue;

      final category = transaction.categoryName.isEmpty
          ? 'Other'
          : transaction.categoryName;

      if (transaction.date.year == now.year &&
          transaction.date.month == now.month) {
        currentCategoryTotals[category] =
            (currentCategoryTotals[category] ?? 0) + transaction.amount;
      }

      if (transaction.date.year == previousMonth.year &&
          transaction.date.month == previousMonth.month) {
        previousCategoryTotals[category] =
            (previousCategoryTotals[category] ?? 0) + transaction.amount;
      }
    }

    String? risingCategory;
    double risingCategoryChange = 0;

    for (final entry in currentCategoryTotals.entries) {
      final currentAmount = entry.value;
      final previousAmount = previousCategoryTotals[entry.key] ?? 0;

      if (currentAmount <= 0) continue;

      if (previousAmount > 0) {
        final change =
            ((currentAmount - previousAmount) / previousAmount) * 100;

        if (change >= 10 && change > risingCategoryChange) {
          risingCategory = entry.key;
          risingCategoryChange = change;
        }
      }
    }

    final overallChange = _monthlySpendingChange;

    // Category-specific intelligence takes priority over the
    // generic overall monthly trend message.
    if (risingCategory != null && _previousMonthExpenses > 0) {
      if (overallChange <= -10) {
        return 'Your overall spending is down ${overallChange.abs().round()}% compared with last month, but $risingCategory spending is up ${risingCategoryChange.round()}%. Consider reviewing this category.';
      }

      if (overallChange >= 10) {
        return 'Your overall spending is up ${overallChange.round()}% compared with last month, and $risingCategory spending is up ${risingCategoryChange.round()}%. Review this category first.';
      }

      return '$risingCategory spending is up ${risingCategoryChange.round()}% compared with last month. Consider reviewing this category.';
    }

    if (_previousMonthExpenses > 0 && overallChange >= 10) {
      return 'Your spending is up ${overallChange.round()}% compared with last month. Review your recent expenses, especially your largest spending category.';
    }

    if (_previousMonthExpenses > 0 && overallChange <= -10) {
      return 'Good progress. Your spending is down ${overallChange.abs().round()}% compared with last month. Keep the momentum going.';
    }

    final savingsRate = ((_totalIncome - _totalExpenses) / _totalIncome) * 100;

    final expenses = transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList();

    if (expenses.isNotEmpty && _totalExpenses > 0) {
      final categoryTotals = <String, double>{};

      for (final transaction in expenses) {
        final category = transaction.categoryName.isEmpty
            ? 'Other'
            : transaction.categoryName;

        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + transaction.amount;
      }

      final largestCategory = categoryTotals.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );

      final largestCategoryShare =
          (largestCategory.value / _totalExpenses) * 100;

      if (largestCategoryShare >= 40) {
        return '${largestCategory.key} accounts for ${largestCategoryShare.toStringAsFixed(0)}% of your recorded spending. Review this category first for possible savings.';
      }

      if (savingsRate < 10) {
        return 'Your savings rate is ${savingsRate.toStringAsFixed(0)}%. Your largest spending category is ${largestCategory.key}. Consider setting a limit for it.';
      }

      if (savingsRate >= 30) {
        return 'Great work. You are saving ${savingsRate.toStringAsFixed(0)}% of your recorded income. Keep an eye on ${largestCategory.key}, your largest spending category.';
      }

      return '${largestCategory.key} is your largest spending category at ${largestCategoryShare.toStringAsFixed(0)}% of expenses. Look for one small reduction there to improve your savings.';
    }

    if (savingsRate >= 30) {
      return 'Great work. You are keeping a healthy share of your recorded income after expenses.';
    }

    if (savingsRate >= 10) {
      return 'You are maintaining a positive balance. Look for one or two areas where you can reduce spending further.';
    }

    return 'Your balance is positive but tight. Review recent expenses and set a budget for your biggest spending categories.';
  }

  bool _isLoadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _transactionStore.addListener(_onTransactionsChanged);
    _loadRecentTransactions();
  }

  @override
  void dispose() {
    _transactionStore.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  void _onTransactionsChanged() {
    if (!mounted) return;

    setState(() {
      _recentTransactions = _transactionStore.transactions.take(3).toList();
      _isLoadingTransactions = false;
    });
  }

  Future<void> _loadRecentTransactions() async {
    await _transactionStore.initialize();

    if (!mounted) return;

    setState(() {
      _recentTransactions = _transactionStore.transactions.take(3).toList();
      _isLoadingTransactions = false;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(transactionDay).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  IconData _iconForTransaction(ExpenseTransaction transaction) {
    if (transaction.type == TransactionType.income) {
      return Icons.account_balance_wallet_outlined;
    }

    final category = transaction.categoryName.toLowerCase();

    if (category.contains('shop') ||
        category.contains('grocer') ||
        category.contains('market')) {
      return Icons.shopping_cart_outlined;
    }

    if (category.contains('transport') ||
        category.contains('travel') ||
        category.contains('fuel')) {
      return Icons.directions_car_outlined;
    }

    if (category.contains('food') ||
        category.contains('restaurant') ||
        category.contains('dining')) {
      return Icons.restaurant_outlined;
    }

    if (category.contains('health') ||
        category.contains('medical') ||
        category.contains('medicine')) {
      return Icons.medical_services_outlined;
    }

    if (category.contains('bill') ||
        category.contains('utility') ||
        category.contains('rent')) {
      return Icons.receipt_long_outlined;
    }

    return Icons.payments_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text(
              'ExpenseFlow',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text('Good evening 👋', style: TextStyle(fontSize: 16)),

                const SizedBox(height: 6),

                const Text(
                  'Your finances at a glance',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF123A66), Color(0xFF071A2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'UGX ${_formatAmount(_totalBalance)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${_monthlyChange >= 0 ? '+' : ''}${_monthlyChange.toStringAsFixed(1)}% this month',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Income',
                        amount: 'UGX ${_formatAmount(_totalIncome)}',
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                        changeText: _previousMonthIncome > 0
                            ? _summaryChangeText(_monthlyIncomeChange)
                            : null,
                        changeColor: _previousMonthIncome > 0
                            ? _summaryChangeColor(
                                change: _monthlyIncomeChange,
                                isExpense: false,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expenses',
                        amount: 'UGX ${_formatAmount(_totalExpenses)}',
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                        changeText: _previousMonthExpenses > 0
                            ? _summaryChangeText(_monthlySpendingChange)
                            : null,
                        changeColor: _previousMonthExpenses > 0
                            ? _summaryChangeColor(
                                change: _monthlySpendingChange,
                                isExpense: true,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Financial Health',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_financialHealth.toStringAsFixed(0)}/100',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              _financialHealth >= 70
                                  ? 'Healthy'
                                  : _financialHealth >= 40
                                  ? 'Fair'
                                  : 'Needs attention',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _financialHealth / 100,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Spending Insight',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _smartSpendingInsight,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onSeeAll,
                      child: const Text('See all'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (_isLoadingTransactions)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_recentTransactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).cardColor,
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 36),
                        SizedBox(height: 10),
                        Text(
                          'No transactions yet',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your recent transactions will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._recentTransactions.map((transaction) {
                    final isIncome = transaction.type == TransactionType.income;

                    final sign = isIncome ? '+' : '-';

                    final category = transaction.categoryName.isEmpty
                        ? (isIncome ? 'Income' : 'Expense')
                        : transaction.categoryName;

                    final title = transaction.description.isEmpty
                        ? category
                        : transaction.description;

                    return _TransactionTile(
                      icon: _iconForTransaction(transaction),
                      title: title,
                      subtitle: '${_formatDate(transaction.date)} • $category',
                      amount: '$sign UGX ${_formatAmount(transaction.amount)}',
                      isIncome: isIncome,
                    );
                  }),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: widget.onAddTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Transaction'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final String? changeText;
  final Color? changeColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.changeText,
    this.changeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 25,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          if (changeText != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 24,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  changeText!,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: changeColor ?? Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;

  const _TransactionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? Colors.green : Colors.red;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Budgets',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Plan and control your spending.'),

          const SizedBox(height: 28),

          _BudgetCard(
            title: 'Food',
            spent: 'UGX 180,000',
            limit: 'UGX 300,000',
            progress: 0.60,
          ),

          _BudgetCard(
            title: 'Transport',
            spent: 'UGX 120,000',
            limit: 'UGX 200,000',
            progress: 0.60,
          ),

          _BudgetCard(
            title: 'Entertainment',
            spent: 'UGX 70,000',
            limit: 'UGX 100,000',
            progress: 0.70,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String title;
  final String spent;
  final String limit;
  final double progress;

  const _BudgetCard({
    required this.title,
    required this.spent,
    required this.limit,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Text('$spent of $limit'),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Appearance'),
                  subtitle: const Text(
                    'Use the theme button at the top of the app',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.currency_exchange),
                  title: Text('Currency'),
                  subtitle: Text('Ugandan Shilling (UGX)'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Notifications'),
                  subtitle: Text('Manage expense reminders'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Icon _categoryIcon(ExpenseCategory category, {double size = 19, Color? color}) {
  final icons = <String, IconData>{
    'food': Icons.restaurant_outlined,
    'groceries': Icons.shopping_cart_outlined,
    'transport': Icons.directions_car_outlined,
    'fuel': Icons.local_gas_station_outlined,
    'rent': Icons.home_outlined,
    'utilities': Icons.receipt_long_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'entertainment': Icons.movie_outlined,
    'health': Icons.health_and_safety_outlined,
    'education': Icons.school_outlined,
    'salary': Icons.account_balance_wallet_outlined,
    'business': Icons.business_center_outlined,
    'other-income': Icons.payments_outlined,
  };

  return Icon(
    icons[category.id] ?? Icons.category_outlined,
    size: size,
    color: color,
  );
}

class AddTransactionScreen extends StatefulWidget {
  final ExpenseTransaction? initialTransaction;

  const AddTransactionScreen({super.key, this.initialTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final CategoryRepository _repository = CategoryRepository();
  final TransactionStore _transactionStore = TransactionStore.instance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool isIncome = false;
  String? selectedCategory;
  List<ExpenseCategory> categories = [];
  bool loading = true;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();

    final transaction = widget.initialTransaction;
    if (transaction != null) {
      isIncome = transaction.type == TransactionType.income;
      selectedCategory = transaction.categoryId;
      _amountController.text = transaction.amount.toStringAsFixed(0);
      _descriptionController.text = transaction.description;
      _selectedDate = transaction.date;
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final loaded = await _repository.getCategories();

    if (!mounted) return;

    setState(() {
      categories = loaded;
      loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = categories
        .where(
          (category) =>
              category.type ==
              (isIncome ? CategoryType.income : CategoryType.expense),
        )
        .toList();

    final categoryColor = isIncome ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: (value) {
                    setState(() {
                      isIncome = value.first;
                      selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose a category',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: filteredCategories.map((category) {
                    final selected = selectedCategory == category.id;

                    return ChoiceChip(
                      selected: selected,
                      avatar: _categoryIcon(
                        category,
                        size: 19,
                        color: selected ? Colors.white : categoryColor,
                      ),
                      label: Text(category.name),
                      selectedColor: categoryColor,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: selected ? FontWeight.bold : null,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = category.id;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageCategoriesScreen(),
                      ),
                    );

                    if (!mounted) return;
                    await _loadCategories();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Manage Categories'),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'UGX ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Date: ${_formatDate(_selectedDate)}'),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: selectedCategory == null
                      ? null
                      : () async {
                          final amountText = _amountController.text.trim();
                          final amount = double.tryParse(amountText);

                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid amount.'),
                              ),
                            );
                            return;
                          }

                          final category = categories.firstWhere(
                            (item) => item.id == selectedCategory,
                          );

                          final existing = widget.initialTransaction;

                          final transaction = ExpenseTransaction(
                            id:
                                existing?.id ??
                                DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                            amount: amount,
                            type: isIncome
                                ? TransactionType.income
                                : TransactionType.expense,
                            categoryId: category.id,
                            categoryName: category.name,
                            description:
                                _descriptionController.text.trim().isEmpty
                                ? category.name
                                : _descriptionController.text.trim(),
                            date: _selectedDate,
                            account: existing?.account ?? 'Cash',
                          );

                          final navigator = Navigator.of(context);

                          if (_isEditing) {
                            await _transactionStore.updateTransaction(
                              transaction,
                            );
                          } else {
                            await _transactionStore.addTransaction(transaction);
                          }

                          if (!mounted) return;

                          navigator.pop(true);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: categoryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(_isEditing ? 'Save Changes' : 'Save Transaction'),
                ),
              ],
            ),
    );
  }
}

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final CategoryRepository _repository = CategoryRepository();

  bool showIncome = false;
  bool loading = true;
  List<ExpenseCategory> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final loaded = await _repository.getCategories();

    if (!mounted) return;

    setState(() {
      categories = loaded;
      loading = false;
    });
  }

  List<ExpenseCategory> get filteredCategories {
    return categories
        .where(
          (category) =>
              category.type ==
              (showIncome ? CategoryType.income : CategoryType.expense),
        )
        .toList();
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            showIncome ? 'Add income category' : 'Add expense category',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    final category = ExpenseCategory(
      id: '${showIncome ? 'income' : 'expense'}-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      type: showIncome ? CategoryType.income : CategoryType.expense,
      iconCodePoint: showIncome ? 0xe8a1 : 0xe8b1,
    );

    await _repository.addCategory(category);
    await _loadCategories();
  }

  Future<void> _editCategory(ExpenseCategory category) async {
    final controller = TextEditingController(text: category.name);

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    final updated = ExpenseCategory(
      id: category.id,
      name: name.trim(),
      type: category.type,
      iconCodePoint: category.iconCodePoint,
    );

    await _repository.updateCategory(updated);
    await _loadCategories();
  }

  Future<void> _deleteCategory(ExpenseCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete category?'),
          content: Text('Are you sure you want to delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _repository.deleteCategory(category.id);
    await _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final color = showIncome ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Expenses')),
                    ButtonSegment(value: true, label: Text('Income')),
                  ],
                  selected: {showIncome},
                  onSelectionChanged: (value) {
                    setState(() {
                      showIncome = value.first;
                    });
                  },
                ),

                const SizedBox(height: 20),

                ...filteredCategories.map(
                  (category) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: _categoryIcon(category, color: color),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editCategory(category),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteCategory(category),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                FilledButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: Text(
                    showIncome ? 'Add Income Category' : 'Add Expense Category',
                  ),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
              ],
            ),
    );
  }
}
