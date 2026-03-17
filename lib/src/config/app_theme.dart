import 'package:flutter/material.dart';

class AppColorPalette {
  const AppColorPalette({
    required this.primary20,
    required this.primary50,
    required this.primary200,
    required this.primary,
    required this.primary700,
    required this.primary900,
    required this.secondary,
    required this.accent50,
    required this.accent100,
    required this.accent200,
    required this.accent500,
    required this.accent700,
    required this.accent900,
    required this.background,
    required this.fontColor,
    required this.fontColorBrightness,
    required this.black,
    required this.white,
    required this.monochromatic50,
    required this.monochromatic200,
    required this.monochromatic500,
    required this.monochromatic700,
    required this.monochromatic900,
    required this.grey,
    required this.success,
    required this.error,
    required this.warning,
    required this.neutral,
    required this.otherAccent,
    required this.bgCard,
    required this.bgCard2,
    required this.ciudadaniaBoton,
    required this.bgBlue,
  });

  final Color primary20;
  final Color primary50;
  final Color primary200;
  final Color primary;
  final Color primary700;
  final Color primary900;
  final Color secondary;
  final Color accent50;
  final Color accent100;
  final Color accent200;
  final Color accent500;
  final Color accent700;
  final Color accent900;
  final Color background;
  final Color fontColor;
  final Color fontColorBrightness;
  final Color black;
  final Color white;
  final Color monochromatic50;
  final Color monochromatic200;
  final Color monochromatic500;
  final Color monochromatic700;
  final Color monochromatic900;
  final Color grey;
  final Color success;
  final Color error;
  final Color warning;
  final Color neutral;
  final Color otherAccent;
  final Color bgCard;
  final Color bgCard2;
  final Color ciudadaniaBoton;
  final Color bgBlue;
}

class AppTheme {
  static const AppColorPalette lightPalette = AppColorPalette(
    primary20: Color(0xFFF1F5F9),
    primary50: Color(0xFFE2E8F0),
    primary200: Color(0xFFCBD5E1),
    primary: Color(0xFF0F172A),
    primary700: Color(0xFF1E293B),
    primary900: Color(0xFF020617),
    secondary: Color(0xFF334155),
    accent50: Color(0xFFEFF6FF),
    accent100: Color(0xFFDBEAFE),
    accent200: Color(0xFFBFDBFE),
    accent500: Color(0xFF2563EB),
    accent700: Color(0xFF1D4ED8),
    accent900: Color(0xFF1E3A8A),
    background: Color(0xFFF8FAFC),
    fontColor: Color(0xFF0F172A),
    fontColorBrightness: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    white: Color(0xFFFFFFFF),
    monochromatic50: Color(0xFFFFFFFF),
    monochromatic200: Color(0xFFF1F5F9),
    monochromatic500: Color(0xFFE2E8F0),
    monochromatic700: Color(0xFF94A3B8),
    monochromatic900: Color(0xFF334155),
    grey: Color(0xFF64748B),
    success: Color(0xFF16A34A),
    error: Color(0xFFDC2626),
    warning: Color(0xFFF59E0B),
    neutral: Color(0xFF475569),
    otherAccent: Color(0xFF2563EB),
    bgCard: Color(0xFFFFFFFF),
    bgCard2: Color(0xFFF8FAFC),
    ciudadaniaBoton: Color(0xFF0F172A),
    bgBlue: Color(0xFF1D4ED8),
  );

  static const AppColorPalette darkPalette = AppColorPalette(
    primary20: Color(0xFF000000),
    primary50: Color(0xFF050505),
    primary200: Color(0xFF0A0A0A),
    primary: Color(0xFFF5F5F5),
    primary700: Color(0xFFE5E7EB),
    primary900: Color(0xFFFFFFFF),
    secondary: Color(0xFFB3B3B3),
    accent50: Color(0xFF0C1A3D),
    accent100: Color(0xFF1B2C5A),
    accent200: Color(0xFF1D4ED8),
    accent500: Color(0xFF60A5FA),
    accent700: Color(0xFF93C5FD),
    accent900: Color(0xFFDBEAFE),
    background: Color(0xFF000000),
    fontColor: Color(0xFFF5F5F5),
    fontColorBrightness: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    white: Color(0xFFFFFFFF),
    monochromatic50: Color(0xFF000000),
    monochromatic200: Color(0xFF0A0A0A),
    monochromatic500: Color(0xFF1A1A1A),
    monochromatic700: Color(0xFF2A2A2A),
    monochromatic900: Color(0xFFE5E7EB),
    grey: Color(0xFFD1D5DB),
    success: Color(0xFF4ADE80),
    error: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    neutral: Color(0xFFD1D5DB),
    otherAccent: Color(0xFF60A5FA),
    bgCard: Color(0xFF050505),
    bgCard2: Color(0xFF0A0A0A),
    ciudadaniaBoton: Color(0xFFF5F5F5),
    bgBlue: Color(0xFF1D4ED8),
  );

  static ThemeData lightTheme = _buildTheme(
    palette: lightPalette,
    brightness: Brightness.light,
  );

  static ThemeData darkTheme = _buildTheme(
    palette: darkPalette,
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme({
    required AppColorPalette palette,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.fontColorBrightness,
      secondary: palette.secondary,
      onSecondary: palette.fontColorBrightness,
      error: palette.error,
      onError: palette.white,
      surface: palette.background,
      onSurface: palette.fontColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Poppins',
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.fontColor,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.fontColor),
        titleTextStyle: TextStyle(
          color: palette.fontColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.bgCard,
        shadowColor: palette.black.withValues(alpha: 0.15),
        elevation: 1,
      ),
      dividerColor: palette.monochromatic500,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.monochromatic500),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.monochromatic500),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary),
        ),
      ),
    );
  }
}
