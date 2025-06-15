import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility class to handle Google Fonts with proper error handling and fallbacks
class FontHelper {
  /// Get Poppins text style with fallback to system font
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    try {
      return GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
        fontStyle: fontStyle,
      );
    } catch (e) {
      // Fallback to system font if Google Fonts fails
      print('Google Fonts failed to load Poppins, using fallback: $e');
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
        fontStyle: fontStyle,
      );
    }
  }

  /// Get Poppins text theme with fallback
  static TextTheme poppinsTextTheme(TextTheme base) {
    try {
      return GoogleFonts.poppinsTextTheme(base);
    } catch (e) {
      print('Google Fonts failed to load Poppins text theme, using fallback: $e');
      return base.copyWith(
        displayLarge: base.displayLarge?.copyWith(fontFamily: 'sans-serif'),
        displayMedium: base.displayMedium?.copyWith(fontFamily: 'sans-serif'),
        displaySmall: base.displaySmall?.copyWith(fontFamily: 'sans-serif'),
        headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'sans-serif'),
        headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'sans-serif'),
        headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'sans-serif'),
        titleLarge: base.titleLarge?.copyWith(fontFamily: 'sans-serif'),
        titleMedium: base.titleMedium?.copyWith(fontFamily: 'sans-serif'),
        titleSmall: base.titleSmall?.copyWith(fontFamily: 'sans-serif'),
        bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'sans-serif'),
        bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'sans-serif'),
        bodySmall: base.bodySmall?.copyWith(fontFamily: 'sans-serif'),
        labelLarge: base.labelLarge?.copyWith(fontFamily: 'sans-serif'),
        labelMedium: base.labelMedium?.copyWith(fontFamily: 'sans-serif'),
        labelSmall: base.labelSmall?.copyWith(fontFamily: 'sans-serif'),
      );
    }
  }

  /// Check if Google Fonts is available
  static Future<bool> isGoogleFontsAvailable() async {
    try {
      // Try to load a simple Poppins style to test connectivity
      GoogleFonts.poppins();
      return true;
    } catch (e) {
      return false;
    }
  }
}