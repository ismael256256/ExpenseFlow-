import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0B1F3A);
  static const Color accent = Color(0xFF2D7FF9);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF08111F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF08111F),
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF12243A),
        elevation: 0,
      ),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: const AppBarTheme(
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
      ),
    );
  }
}
