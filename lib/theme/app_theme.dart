import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Space Marine Theme Colors
  static const Color marineBlue = Color(
    0xFF1F3B6C,
  ); // Azul principal del Space Marine
  static const Color marineBlueLight = Color(0xFF4A7ED3); // Azul claro/brillos
  static const Color marineBlueDark = Color(
    0xFF172A4D,
  ); // Azul más oscuro (sombras)
  static const Color marineOrange = Color(0xFFFF8A00); // Naranja del pincel
  static const Color marineGold = Color(0xFFFFC857); // Dorado/Águila
  static const Color marineBlueBg = Color(0xFF253248); // Azul de fondo

  // Colores secundarios para la UI
  static const Color textDark = Color(0xFF1A1C29); // Texto oscuro
  static const Color textGrey = Color(0xFF777777); // Texto secundario
  static const Color backgroundGrey = Color(0xFFF7F8FA); // Fondo claro

  // Colores para categorías
  static const Color pinkColor = Color(0xFFFF4D9D);
  static const Color purpleColor = Color(0xFF9747FF);
  static const Color greenColor = Color(0xFF23C16B);

  // Dark theme colors
  static const Color darkBackground = Color(
    0xFF121A2E,
  ); // Fondo oscuro (Space Marine)
  static const Color darkSurface = Color(0xFF1E2A40); // Superficie oscura
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  // Default text styles with the same font - usando .sp para tamaños de fuente responsivos
  static TextStyle get headingStyle => GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    fontSize: 32.sp,
    height: 1.2,
  );

  static TextStyle get subheadingStyle => GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
    fontSize: 20.sp,
    height: 1.3,
  );

  static TextStyle get bodyStyle => GoogleFonts.poppins(
    fontWeight: FontWeight.normal,
    fontSize: 16.sp,
    height: 1.5,
  );

  static TextStyle get buttonStyle =>
      GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16.sp);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundGrey,
    fontFamily: GoogleFonts.poppins().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: marineBlue,
      primary: marineBlue,
      secondary: marineOrange,
      tertiary: marineGold,
      background: backgroundGrey,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: marineBlue,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18.sp,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: marineBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        textStyle: buttonStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        side: BorderSide(color: marineBlue.withOpacity(0.5)),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        textStyle: buttonStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        foregroundColor: marineBlue,
        textStyle: buttonStyle,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      hintStyle: GoogleFonts.poppins(color: textGrey),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: marineBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12.sp,
        color: marineBlue,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: marineBlue,
      unselectedItemColor: textGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: TextTheme(
      titleLarge: headingStyle.copyWith(fontSize: 22.sp, color: textDark),
      titleMedium: subheadingStyle.copyWith(fontSize: 18.sp, color: textDark),
      titleSmall: subheadingStyle.copyWith(fontSize: 16.sp, color: textDark),
      bodyLarge: bodyStyle.copyWith(color: textDark),
      bodyMedium: bodyStyle.copyWith(fontSize: 14.sp, color: textDark),
      bodySmall: bodyStyle.copyWith(fontSize: 12.sp, color: textGrey),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: GoogleFonts.poppins().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: marineBlue,
      primary: marineBlueLight,
      secondary: marineOrange,
      tertiary: marineGold,
      background: darkBackground,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: marineBlueDark,
      foregroundColor: darkTextPrimary,
      titleTextStyle: GoogleFonts.poppins(
        color: darkTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 18.sp,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      color: darkSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: marineOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        textStyle: buttonStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        side: BorderSide(color: marineBlueLight.withOpacity(0.5)),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        textStyle: buttonStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        foregroundColor: marineBlueLight,
        textStyle: buttonStyle,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: darkSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      hintStyle: GoogleFonts.poppins(color: darkTextSecondary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: marineBlueLight.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12.sp,
        color: marineBlueLight,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: marineBlueDark,
      selectedItemColor: marineOrange,
      unselectedItemColor: darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: TextTheme(
      titleLarge: headingStyle.copyWith(
        fontSize: 22.sp,
        color: darkTextPrimary,
      ),
      titleMedium: subheadingStyle.copyWith(
        fontSize: 18.sp,
        color: darkTextPrimary,
      ),
      titleSmall: subheadingStyle.copyWith(
        fontSize: 16.sp,
        color: darkTextPrimary,
      ),
      bodyLarge: bodyStyle.copyWith(color: darkTextPrimary),
      bodyMedium: bodyStyle.copyWith(fontSize: 14.sp, color: darkTextPrimary),
      bodySmall: bodyStyle.copyWith(fontSize: 12.sp, color: darkTextSecondary),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: marineOrange,
      foregroundColor: Colors.white,
    ),
  );

  // Método para obtener colores de categoría basados en el índice
  static Color getCategoryColor(int index) {
    switch (index % 5) {
      case 0:
        return marineBlue;
      case 1:
        return marineOrange;
      case 2:
        return purpleColor;
      case 3:
        return marineGold;
      case 4:
        return greenColor;
      default:
        return marineBlue;
    }
  }

  // Los siguientes getters son para mantener compatibilidad con el código existente
  static Color get primaryBlue => marineBlue;
  static Color get orangeColor => marineOrange;
}
