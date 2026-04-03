import 'package:flutter/material.dart';

class NavalTheme {
  static const background = Color(0xFF0D1F3C);
  static const surface = Color(0xFF1C1F2D);
  static const primary = Color(0xFFC9BEFF);
  static const secondary = Color(0xFF91CDFF);
  static const tertiary = Color(0xFF4AE183);
  static const error = Color(0xFFFFB4AB);
  static const text = Color(0xFFE0E1F5);
  static const textDim = Color(0xFF8888AA);

  static ThemeData get themeData => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          error: error,
          surface: surface,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: text,
              displayColor: text,
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: const TextStyle(color: textDim),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: primary, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: primary.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );

  static Color hpColor(double fraction) {
    if (fraction > 0.6) return tertiary;
    if (fraction > 0.3) return primary;
    return const Color(0xFFFF8A80);
  }
}
