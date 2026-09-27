import 'package:flutter/material.dart';
import 'mausam_colors.dart';
import 'mausam_spacing.dart';
import 'mausam_typography.dart';

class MausamTheme {
  MausamTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: MausamColors.backgroundLight,
      primaryColor: MausamColors.atmospherePrimary,
      cardColor: MausamColors.surfaceLight,
      dividerColor: MausamColors.borderLight,
      fontFamily: MausamTypography.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: MausamColors.surfaceLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: MausamColors.textPrimaryLight),
        titleTextStyle: MausamTypography.title,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MausamColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          borderSide: const BorderSide(color: MausamColors.borderLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          borderSide: const BorderSide(color: MausamColors.borderLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          borderSide: const BorderSide(color: MausamColors.atmospherePrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          borderSide: const BorderSide(color: MausamColors.criticalCrimson, width: 1.0),
        ),
        labelStyle: MausamTypography.label.copyWith(color: MausamColors.textSecondaryLight),
        hintStyle: MausamTypography.body.copyWith(color: MausamColors.textMutedLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MausamColors.surfaceLight,
        selectedItemColor: MausamColors.atmospherePrimary,
        unselectedItemColor: MausamColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MausamColors.atmospherePrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: MausamTypography.labelBold.copyWith(color: Colors.white),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MausamColors.textPrimaryLight,
          side: const BorderSide(color: MausamColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: MausamTypography.labelBold,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MausamColors.atmospherePrimary,
          textStyle: MausamTypography.labelBold,
        ),
      ),
      colorScheme: const ColorScheme.light(
        surface: MausamColors.surfaceLight,
        primary: MausamColors.atmospherePrimary,
        secondary: MausamColors.vegetativeEmerald,
        error: MausamColors.criticalCrimson,
        onSurface: MausamColors.textPrimaryLight,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MausamColors.backgroundDark,
      primaryColor: MausamColors.atmospherePrimary,
      cardColor: MausamColors.surfaceDark,
      dividerColor: MausamColors.borderDark,
      fontFamily: MausamTypography.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: MausamColors.surfaceDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: MausamColors.textPrimaryDark),
        titleTextStyle: MausamTypography.title,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MausamColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          borderSide: const BorderSide(color: MausamColors.borderDark, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          borderSide: const BorderSide(color: MausamColors.borderDark, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
          borderSide: const BorderSide(color: MausamColors.criticalCrimson, width: 1.0),
        ),
        labelStyle: MausamTypography.label.copyWith(color: MausamColors.textSecondaryDark),
        hintStyle: MausamTypography.body.copyWith(color: MausamColors.textMutedDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MausamColors.surfaceDark,
        selectedItemColor: Color(0xFF38BDF8),
        unselectedItemColor: MausamColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MausamColors.atmospherePrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: MausamTypography.labelBold.copyWith(color: Colors.white),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MausamColors.textPrimaryDark,
          side: const BorderSide(color: MausamColors.borderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MausamSpacing.radiusButtons),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: MausamTypography.labelBold,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFF38BDF8),
          textStyle: MausamTypography.labelBold,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        surface: MausamColors.surfaceDark,
        primary: MausamColors.atmospherePrimary,
        secondary: MausamColors.vegetativeEmerald,
        error: MausamColors.criticalCrimson,
        onSurface: MausamColors.textPrimaryDark,
      ),
    );
  }
}
