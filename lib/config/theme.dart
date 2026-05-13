import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primary,
        secondary: AppConstants.secondary,
        surface: AppConstants.background,
        error: AppConstants.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppConstants.textDark,
      ),
      scaffoldBackgroundColor: AppConstants.background,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppConstants.textDark),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textDark),
        titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppConstants.textDark),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal, color: AppConstants.textDark),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: AppConstants.textLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppConstants.textDark),
        titleTextStyle: TextStyle(
          color: AppConstants.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.cardColor,
        elevation: 2,
        shadowColor: AppConstants.textMuted.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: AppConstants.textMuted.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: AppConstants.textMuted.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.error),
        ),
        labelStyle: const TextStyle(color: AppConstants.textLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primary,
        secondary: AppConstants.secondary,
        surface: AppConstants.darkBackground,
        error: AppConstants.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: AppConstants.darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: AppConstants.textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.cardColorDark,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.cardColorDark,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.error),
        ),
        labelStyle: const TextStyle(color: AppConstants.textMuted),
      ),
    );
  }
}
