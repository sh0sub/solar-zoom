import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Solar Warmth Palette
  static const Color solarOrange = Color(0xFFFF8C00); // Primary Action
  static const Color warmWhite = Color(0xFFFFF8F0);   // Text & Background (Soft)
  static const Color deepCharcoal = Color(0xFF1A1A1A); // Background
  static const Color softGrey = Color(0xFF2C2C2C);     // Cards & Surfaces
  static const Color limeYellow = Color(0xFFC6FF00);   // Highlights / Focus
  static const Color errorRed = Color(0xFFFF453A);     // Warnings
}

class AppTextStyles {
  // Use Noto Sans KR for clarity and modern feel
  static TextStyle get displayLarge => GoogleFonts.notoSansKr(
    fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.warmWhite
  );
  
  static TextStyle get displayMedium => GoogleFonts.notoSansKr(
    fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.warmWhite
  );

  static TextStyle get bodyLarge => GoogleFonts.notoSansKr(
    fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.warmWhite
  );
  
  static TextStyle get bodyMedium => GoogleFonts.notoSansKr(
    fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.warmWhite.withOpacity(0.8)
  );

  static TextStyle get buttonLarge => GoogleFonts.notoSansKr(
    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Default to dark for high contrast
      scaffoldBackgroundColor: AppColors.deepCharcoal,
      primaryColor: AppColors.solarOrange,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.solarOrange,
        secondary: AppColors.limeYellow,
        surface: AppColors.softGrey,
        background: AppColors.deepCharcoal,
        error: AppColors.errorRed,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        bodyLarge: AppTextStyles.bodyLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.solarOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.solarOrange,
        inactiveTrackColor: AppColors.softGrey,
        thumbColor: AppColors.warmWhite,
        trackHeight: 12.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16.0),
        overlayColor: AppColors.solarOrange.withOpacity(0.2),
      ),
    );
  }
}
