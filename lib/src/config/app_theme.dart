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
    primary20: Color(0xFFE8EFF7),
    primary50: Color(0xFFD6E2F2),
    primary200: Color(0xFF9FB6DA),
    primary: Color(0xFF1B3E73),
    primary700: Color(0xFF163461),
    primary900: Color(0xFF10284B),
    secondary: Color(0xFF2F6B3B),
    accent50: Color(0xFFEAF2FB),
    accent100: Color(0xFFCEE0F4),
    accent200: Color(0xFFA9C6E8),
    accent500: Color(0xFF5A8FCF),
    accent700: Color(0xFF4779B6),
    accent900: Color(0xFF2F5E97),
    background: Color(0xFFF6F8FC),
    fontColor: Color(0xFF0E254A),
    fontColorBrightness: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    white: Color(0xFFFFFFFF),
    monochromatic50: Color(0xFFFFFFFF),
    monochromatic200: Color(0xFFEEF3FA),
    monochromatic500: Color(0xFFD2DBE8),
    monochromatic700: Color(0xFFB7C3D4),
    monochromatic900: Color(0xFF425066),
    grey: Color(0xFF425066),
    success: Color(0xFF5D7A2E),
    error: Color(0xFFD84339),
    warning: Color(0xFFFEC748),
    neutral: Color(0xFF425066),
    otherAccent: Color(0xFF5A8FCF),
    bgCard: Color(0xFFFFFFFF),
    bgCard2: Color(0xFFF0F4FA),
    ciudadaniaBoton: Color(0xFF2F6B3B),
    bgBlue: Color(0xFF1B3E73),
  );

  static const AppColorPalette darkPalette = AppColorPalette(
    primary20: Color(0xFF1A2338),
    primary50: Color(0xFF22324C),
    primary200: Color(0xFF5A79B1),
    primary: Color(0xFF3F64B5),
    primary700: Color(0xFF35559A),
    primary900: Color(0xFF2B477F),
    secondary: Color(0xFF69B27D),
    accent50: Color(0xFF1C2432),
    accent100: Color(0xFF243147),
    accent200: Color(0xFF2E415C),
    accent500: Color(0xFF5A8FCF),
    accent700: Color(0xFF78A6DD),
    accent900: Color(0xFFA8C4EB),
    background: Color(0xFF0B0F1A),
    fontColor: Color(0xFFFFFFFF),
    fontColorBrightness: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    white: Color(0xFFFFFFFF),
    monochromatic50: Color(0xFF131A2A),
    monochromatic200: Color(0xFF1C2538),
    monochromatic500: Color(0xFF2A3347),
    monochromatic700: Color(0xFF414C63),
    monochromatic900: Color(0xFFCDD6E4),
    grey: Color(0xFFEDEDED),
    success: Color(0xFFB1D77B),
    error: Color(0xFFD84339),
    warning: Color(0xFFFEC748),
    neutral: Color(0xFFCCCCCC),
    otherAccent: Color(0xFF5A8FCF),
    bgCard: Color(0xFF121826),
    bgCard2: Color(0xFF1A2234),
    ciudadaniaBoton: Color(0xFFF18B2A),
    bgBlue: Color(0xFF2B4D88),
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
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.fontColorBrightness,
      secondary: palette.secondary,
      onSecondary: palette.fontColorBrightness,
      error: palette.error,
      onError: palette.white,
      surface: palette.bgCard,
      onSurface: palette.fontColor,
      background: palette.background,
      onBackground: palette.fontColor,
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
