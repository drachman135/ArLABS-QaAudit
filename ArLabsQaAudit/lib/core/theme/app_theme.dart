import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Warna Utama ──────────────────────────────────────────
  static const Color primaryColor      = Color(0xFF2563EB); // Blue-600
  static const Color primaryHover      = Color(0xFF1D4ED8); // Blue-700
  static const Color primaryGlow       = Color(0xFF3B82F6); // Blue-500
  static const Color secondaryColor    = Color(0xFF10B981); // Emerald

  // ─── Dark Mode ────────────────────────────────────────────
  static const Color darkBackground    = Color(0xFF080A0F); // Hitam pekat
  static const Color darkSurface       = Color(0xFF0D0F16); // Sedikit lebih terang
  static const Color darkCard          = Color(0xFF111520); // Card
  static const Color darkBorder        = Color(0xFF1C2033); // Border tipis
  static const Color darkBorderLight   = Color(0xFF242840); // Border hover
  static const Color darkTextPrimary   = Color(0xFFEDF0F7); // Hampir putih
  static const Color darkTextSecondary = Color(0xFF6B7A99); // Abu kebiruan
  static const Color darkTextMuted     = Color(0xFF3A4255); // Sangat redup

  // ─── Light Mode ───────────────────────────────────────────
  static const Color lightBackground   = Color(0xFFF2F4F8);
  static const Color lightSurface      = Color(0xFFFFFFFF);
  static const Color lightCard         = Color(0xFFFFFFFF);
  static const Color lightBorder       = Color(0xFFE3E8F0);
  static const Color lightTextPrimary  = Color(0xFF0D1117);
  static const Color lightTextSecondary= Color(0xFF5A6478);
  static const Color lightTextMuted    = Color(0xFFAAB3C5);

  static double get defaultRadius => 10.0;

  // ─── Status Colors ────────────────────────────────────────
  static const Color statusPassed          = Color(0xFF16A34A);
  static const Color statusFailed          = Color(0xFFDC2626);
  static const Color statusWarning         = Color(0xFFD97706);
  static const Color statusNotTested       = Color(0xFF475569);
  static const Color statusNotImplemented  = Color(0xFF7C3AED);
  static const Color statusSkipped         = Color(0xFF0891B2);

  // ─── Bug Severity Colors ──────────────────────────────────
  static const Color severityCritical      = Color(0xFFDC2626);
  static const Color severityHigh          = Color(0xFFEA580C);
  static const Color severityMedium        = Color(0xFFD97706);
  static const Color severityLow           = Color(0xFF2563EB);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      dividerColor: darkBorder,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge:   TextStyle(color: darkTextPrimary, fontSize: 15, height: 1.6),
        bodyMedium:  TextStyle(color: darkTextSecondary, fontSize: 13, height: 1.5),
        bodySmall:   TextStyle(color: darkTextMuted, fontSize: 11),
        titleLarge:  TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleMedium: TextStyle(color: darkTextPrimary, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        titleSmall:  TextStyle(color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkBorder, width: 1),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkBorder, width: 1),
          borderRadius: BorderRadius.circular(defaultRadius + 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(color: darkTextPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: darkCard,
        indicatorColor: Color(0xFF1E2D50),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 13),
        hintStyle:  const TextStyle(color: darkTextMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGlow,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      dividerColor: lightBorder,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        bodyLarge:   TextStyle(color: lightTextPrimary, fontSize: 15, height: 1.6),
        bodyMedium:  TextStyle(color: lightTextSecondary, fontSize: 13, height: 1.5),
        bodySmall:   TextStyle(color: lightTextMuted, fontSize: 11),
        titleLarge:  TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleMedium: TextStyle(color: lightTextPrimary, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        titleSmall:  TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightBorder, width: 1),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightBorder, width: 1),
          borderRadius: BorderRadius.circular(defaultRadius + 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(color: lightTextPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: lightSurface,
        indicatorColor: primaryColor.withValues(alpha: 0.08),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 13),
        hintStyle:  const TextStyle(color: lightTextMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
