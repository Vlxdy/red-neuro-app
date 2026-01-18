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
    primary20: Color(0xFFE7ECF5),
    primary50: Color(0xFFD2DAEB),
    primary200: Color(0xFF8FA3C6),
    primary: Color(0xFF0F2C5C),
    primary700: Color(0xFF0C244D),
    primary900: Color(0xFF091C3E),
    secondary: Color(0xFFF18B2A),
    accent50: Color(0xFFFEE6EC),
    accent100: Color(0xFFFCC2D0),
    accent200: Color(0xFFF98DA8),
    accent500: Color(0xFFEF5E82),
    accent700: Color(0xFFE24B72),
    accent900: Color(0xFFCC335C),
    background: Color(0xFFF8FAFC),
    fontColor: Color(0xFF0F2C5C),
    fontColorBrightness: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    white: Color(0xFFFFFFFF),
    monochromatic50: Color(0xFFFFFFFF),
    monochromatic200: Color(0xFFF0F2F5),
    monochromatic500: Color(0xFFD9DEE6),
    monochromatic700: Color(0xFFBFC8D4),
    monochromatic900: Color(0xFF4F607C),
    grey: Color(0xFF454F5B),
    success: Color(0xFF5D7A2E),
    error: Color(0xFFD84339),
    warning: Color(0xFFFEC748),
    neutral: Color(0xFF4F607C),
    otherAccent: Color(0xFFEF5E82),
    bgCard: Color(0xFFFFFFFF),
    bgCard2: Color(0xFFF8FAFC),
    ciudadaniaBoton: Color(0xFFF18B2A),
    bgBlue: Color(0xFF0F2C5C),
  );

  static const AppColorPalette darkPalette = AppColorPalette(
    primary20: Color(0xFF2A3A5B),
    primary50: Color(0xFF3A4C6C),
    primary200: Color(0xFF62749A),
    primary: Color(0xFFFFFFFF),
    primary700: Color(0xFFE0E0E0),
    primary900: Color(0xFFCCCCCC),
    secondary: Color(0xFFF18B2A),
    accent50: Color(0xFF49313C),
    accent100: Color(0xFF63424E),
    accent200: Color(0xFF875767),
    accent500: Color(0xFFEF5E82),
    accent700: Color(0xFFFA7094),
    accent900: Color(0xFFFF94B1),
    background: Color(0xFF000000),
    fontColor: Color(0xFFFFFFFF),
    fontColorBrightness: Color(0xFF0F2C5C),
    black: Color(0xFF000000),
    white: Color(0xFFFFFFFF),
    monochromatic50: Color(0xFF1C1C1E),
    monochromatic200: Color(0xFF2A2928),
    monochromatic500: Color(0xFF3A3A3A),
    monochromatic700: Color(0xFF5A5A5A),
    monochromatic900: Color(0xFFCCCCCC),
    grey: Color(0xFFEDEDED),
    success: Color(0xFFB1D77B),
    error: Color(0xFFD84339),
    warning: Color(0xFFFEC748),
    neutral: Color(0xFFCCCCCC),
    otherAccent: Color(0xFFEF5E82),
    bgCard: Color(0xFF1C1C1E),
    bgCard2: Color(0xFF2A2928),
    ciudadaniaBoton: Color(0xFFF18B2A),
    bgBlue: Color(0xFF1E3A73),
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
