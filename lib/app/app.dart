import 'package:flutter/material.dart';

import '../features/dashboard/presentation/screens/dashboard_screen.dart';

class ExpenseFlowApp extends StatefulWidget {
  const ExpenseFlowApp({super.key});

  @override
  State<ExpenseFlowApp> createState() => _ExpenseFlowAppState();
}

class _ExpenseFlowAppState extends State<ExpenseFlowApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExpenseFlow',
      themeMode: _themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123A66),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123A66),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF071018),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),

      home: _HomeScreen(themeMode: _themeMode, onToggleTheme: _toggleTheme),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const _HomeScreen({required this.themeMode, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DashboardScreen(),

        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: Material(
            color:
                Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            child: IconButton(
              tooltip: 'Switch theme',
              onPressed: onToggleTheme,
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
