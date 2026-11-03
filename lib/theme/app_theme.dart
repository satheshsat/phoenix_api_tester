import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8C5A);
  static const Color primaryDark = Color(0xFFE85A20);
  static const Color accent = Color(0xFF6366F1);

  // Method Colors
  static const Color methodGet = Color(0xFF10B981); // Emerald
  static const Color methodPost = Color(0xFF3B82F6); // Blue
  static const Color methodPut = Color(0xFFF59E0B); // Amber
  static const Color methodDelete = Color(0xFFEF4444); // Red
  static const Color methodPatch = Color(0xFF8B5CF6); // Purple
  static const Color methodOther = Color(0xFF64748B); // Slate

  static Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return methodGet;
      case 'POST':
        return methodPost;
      case 'PUT':
        return methodPut;
      case 'DELETE':
        return methodDelete;
      case 'PATCH':
        return methodPatch;
      default:
        return methodOther;
    }
  }

  // Status code colors
  static Color getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return const Color(0xFF10B981);
    } else if (statusCode >= 300 && statusCode < 400) {
      return const Color(0xFF3B82F6);
    } else if (statusCode >= 400 && statusCode < 500) {
      return const Color(0xFFF59E0B);
    } else if (statusCode >= 500) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF64748B);
  }

  // Dark Theme
  static ThemeData get darkTheme {
    const bgDark = Color(0xFF0F172A);
    const surfaceDark = Color(0xFF1E293B);
    const cardDark = Color(0xFF182234);
    const borderDark = Color(0xFF334155);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surfaceDark,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSurface: Color(0xFFF1F5F9),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      dividerColor: borderDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0F1D),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF94A3B8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: Color(0xFF94A3B8),
        indicatorColor: primary,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    const bgLight = Color(0xFFF8FAFC);
    const surfaceLight = Color(0xFFFFFFFF);
    const borderLight = Color(0xFFE2E8F0);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surfaceLight,
        error: Color(0xFFDC2626),
        onPrimary: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      dividerColor: borderLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF475569)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: Color(0xFF64748B),
        indicatorColor: primary,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13),
      ),
    );
  }
}
