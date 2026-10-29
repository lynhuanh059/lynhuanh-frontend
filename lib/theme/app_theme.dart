import 'package:flutter/material.dart';

class AppTheme {
  // Bảng màu "Campus Teal": xanh ngọc đậm + điểm nhấn hổ phách, nền xanh nhạt dịu mắt
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color accentBlue = Color(0xFF0284C7);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color background = Color(0xFFF3F7F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE1EAE8);

  static const Color textPrimary = Color(0xFF10201E);
  static const Color textSecondary = Color(0xFF5B6F6C);
  static const Color textMuted = Color(0xFF93A5A2);

  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFE6F6EF);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFF4E0);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFDECEC);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B5F59), Color(0xFF14A394)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get softShadow => [
        BoxShadow(color: const Color(0xFF0F766E).withAlpha(18), blurRadius: 18, offset: const Offset(0, 6)),
      ];

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryDark,
      primary: primaryDark,
      secondary: accentBlue,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryDark,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryDark.withAlpha(120),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: primaryDark, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryDark),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7FAF9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryDark, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
