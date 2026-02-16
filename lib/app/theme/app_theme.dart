import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary (The Anchor) - Dark Olive Green
  static const Color primary = Color(0xFF563825);

  // Secondary (The Glow) - Muted Gold
  static const Color secondary = Color(0xFF90c5e0);

  // Accent (The Warmth) - Burnt Sienna
  static const Color accent = Color(0xFFe090d0);

  // Surface (The Paper) - Cream/Off-White
  static const Color surface = Color(0xFFfcf9f8);
  static const Color secondarySurface = Color(0xFFe3dfde);

  // Text (The Ink) - Dark Warm Brown
  static const Color textPrimary = Color(0xFF070403);
  static const Color textSecondary = Color(0xFF2c2826);

  // Shadow Color
  static const Color shadow = Color.fromRGBO(7, 4, 3, 0.08);

  // Other Color
  static const Color danger = Color(0xFFe94d35);

}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      primaryColor: AppColors.primary,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.accent,
        onSurface: AppColors.textPrimary,
      ),

      // Typography (Be Vietnam Pro)
      textTheme: TextTheme(
        // Headings (Be Vietnam Pro)
        displayLarge: GoogleFonts.beVietnamPro(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.beVietnamPro(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.beVietnamPro(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Body (Be Vietnam Pro)
        bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 18,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 16,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        labelLarge: GoogleFonts.beVietnamPro(
          // For Buttons
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary, size: 28),
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),

      // Navigation Bar Theme (Bottom Bar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.secondary.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 30, color: AppColors.primary);
          }
          return const IconThemeData(size: 26, color: AppColors.textSecondary);
        }),
      ),
    );
  }
}
