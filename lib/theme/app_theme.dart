import 'package:flutter/material.dart';

/// Centralized theme configuration for your app
/// Contains all colors, fonts, and text styles
class AppColors {
  static const MaterialColor purple = MaterialColor(0xFF6C4EE3, <int, Color>{
    50: Color(0xFFF4F0FC),
    100: Color(0xFFE6DBFB),
    200: Color(0xFFD0BAF9),
    300: Color(0xFFB496F5),
    400: Color(0xFF9873F0),
    500: Color(0xFF7E54E8),
    600: Color(0xFF6C4EE3),
    700: Color(0xFF5A39C8),
    800: Color(0xFF482EA3),
    900: Color(0xFF352179),
  });

  static const Color background = Color(0xFFF2EDF9);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;

}

class AppText {
  static const double heading = 28;
  static const double subHeading = 18;
  static const double body = 16;
  static const double small = 14;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: AppColors.purple,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontSize: AppText.body,
        color: AppColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: AppText.small,
        color: AppColors.textSecondary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.purple[600]!),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}
