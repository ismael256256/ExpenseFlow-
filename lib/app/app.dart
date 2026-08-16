import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ExpenseFlowApp extends StatefulWidget {
  const ExpenseFlowApp({super.key});

  @override
  State<ExpenseFlowApp> createState() => _ExpenseFlowAppState();
}

class _ExpenseFlowAppState extends State<ExpenseFlowApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpenseFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: _HomeShell(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class _HomeShell extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const _HomeShell({
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpenseFlow'),
        actions: [
          IconButton(
            tooltip: 'Switch theme',
            onPressed: onToggleTheme,
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Your finances, simplified.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
