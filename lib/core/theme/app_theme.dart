import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.arcReactorCyan,
          secondary: AppColors.ironGold,
          error: AppColors.ironRed,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            displayMedium: TextStyle(
              color: AppColors.arcReactorCyan,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
            ),
            titleLarge: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
            bodyLarge: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
            bodyMedium: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              letterSpacing: 1,
            ),
            labelSmall: TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.rajdhani(
            color: AppColors.arcReactorCyan,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.textDim),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.textDim),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.arcReactorCyan, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textDim),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.arcReactorCyan,
            foregroundColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      );
}
