import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/config/app_theme.dart';
import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();
  static final instance = ThemeController._();

  ValueNotifier<bool> brightness = ValueNotifier<bool>(true);
  bool get isLight => brightness.value;
  bool get isDark => !brightness.value;
  AppColorPalette get palette =>
      isLight ? AppTheme.lightPalette : AppTheme.darkPalette;

  // ===========================================================
  // 🎨 Colores principales sincronizados con el tema web
  // ===========================================================

  // Primary (azul logo)
  Color get primary20 => palette.primary20;
  Color get primary50 => palette.primary50;
  Color get primary200 => palette.primary200;
  Color get primary => palette.primary;
  Color get primary700 => palette.primary700;
  Color get primary900 => palette.primary900;

  // Secondary (naranja zanahoria)
  Color get secondary => palette.secondary;

  // Accent (rosa acento)
  Color get accent50 => palette.accent50;
  Color get accent100 => palette.accent100;
  Color get accent200 => palette.accent200;
  Color get accent500 => palette.accent500;
  Color get accent700 => palette.accent700;
  Color get accent900 => palette.accent900;

  // Backgrounds
  Color get background => palette.background;

  Color get transparent => Colors.transparent;

  // Font and monochromatic
  Color get fontColor => palette.fontColor;

  Color get fontColorBrightness => palette.fontColorBrightness;

  Color get black => palette.black;
  Color get white => palette.white;

  // Monochromatic
  Color get monochromatic50 => palette.monochromatic50;
  Color get monochromatic200 => palette.monochromatic200;
  Color get monochromatic500 => palette.monochromatic500;
  Color get monochromatic700 => palette.monochromatic700;
  Color get monochromatic900 => palette.monochromatic900;

  // Neutral y estados
  Color get grey => palette.grey;
  Color get success => palette.success;
  Color get error => palette.error;
  Color get warning => palette.warning;
  Color get neutral => palette.neutral;

  Color get otherAccent => palette.otherAccent;

  // Cards / backgrounds secundarios
  Color get bgCard => palette.bgCard;
  Color get bgCard2 => palette.bgCard2;

  // Ciudadanía (mantener si se usa internamente)
  Color get ciudadaniaBoton => palette.ciudadaniaBoton;

  // Chip
  Color get bgBlue => palette.bgBlue;

  Color calculateTextColor(Color background) {
    return background.computeLuminance() >= 0.5
        ? const Color(0xFF0F2C5C)
        : const Color(0xFFFFFFFF);
  }

  // Métodos del tema
  void changeTheme() async {
    brightness.value = !brightness.value;
    await PreferencesService.instance.setBool('theme', brightness.value);
  }

  Future<void> initTheme() async {
    brightness.value = await PreferencesService.instance.getBool('theme');
  }
}
