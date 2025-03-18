import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales de la aplicación
  static const Color primaryBlue = Color(0xFF3C62FF);
  static const Color lightBlue = Color(0xFFEAEFFF);
  static const Color backgroundGrey = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF222222);
  static const Color textGrey = Color(0xFF777777);

  // Colores para categorías
  static const Color pinkColor = Color(0xFFFF4D9D);
  static const Color purpleColor = Color(0xFF9747FF);
  static const Color orangeColor = Color(0xFFFFA136);
  static const Color greenColor = Color(0xFF23C16B);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundGrey,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: pinkColor,
      background: backgroundGrey,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      titleTextStyle: TextStyle(
        color: textDark,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: primaryBlue.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: primaryBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: const TextStyle(color: textGrey),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: primaryBlue,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: textGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textDark),
      bodyMedium: TextStyle(fontSize: 14, color: textDark),
      bodySmall: TextStyle(fontSize: 12, color: textGrey),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: pinkColor,
      background: darkBackground,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: darkSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: primaryBlue.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: primaryBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: TextStyle(color: darkTextSecondary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: primaryBlue,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryBlue,
      unselectedItemColor: darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: darkTextPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: darkTextPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: darkTextPrimary),
      bodySmall: TextStyle(fontSize: 12, color: darkTextSecondary),
    ),
  );

  // Método para obtener colores de categoría basados en el índice
  static Color getCategoryColor(int index) {
    switch (index % 4) {
      case 0:
        return primaryBlue;
      case 1:
        return pinkColor;
      case 2:
        return purpleColor;
      case 3:
        return orangeColor;
      default:
        return primaryBlue;
    }
  }
}
