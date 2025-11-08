// import 'package:alimenta_app/src/constants/custom_theme.dart';
import 'package:alimenta_app/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();
  static final instance = ThemeController._();

  ValueNotifier<bool> brightness = ValueNotifier<bool>(true);
  bool get isLight => brightness.value;
  bool get isDark => !brightness.value;

  // ===========================================================
  // 🎨 Colores principales sincronizados con el tema web
  // ===========================================================

  // Primary (azul logo)
  Color get primary20 =>
      isLight ? const Color(0xFFE7ECF5) : const Color(0xFF2A3A5B);
  Color get primary50 =>
      isLight ? const Color(0xFFD2DAEB) : const Color(0xFF3A4C6C);
  Color get primary200 =>
      isLight ? const Color(0xFF8FA3C6) : const Color(0xFF62749A);
  Color get primary =>
      isLight ? const Color(0xFF0F2C5C) : const Color(0xFFFFFFFF);
  Color get primary700 =>
      isLight ? const Color(0xFF0C244D) : const Color(0xFFE0E0E0);
  Color get primary900 =>
      isLight ? const Color(0xFF091C3E) : const Color(0xFFCCCCCC);

  // Secondary (naranja zanahoria)
  Color get secondary =>
      isLight ? const Color(0xFFF18B2A) : const Color(0xFFF18B2A);

  // Accent (rosa acento)
  Color get accent50 =>
      isLight ? const Color(0xFFFEE6EC) : const Color(0xFF49313C);
  Color get accent100 =>
      isLight ? const Color(0xFFFCC2D0) : const Color(0xFF63424E);
  Color get accent200 =>
      isLight ? const Color(0xFFF98DA8) : const Color(0xFF875767);
  Color get accent500 => const Color(0xFFEF5E82);
  Color get accent700 =>
      isLight ? const Color(0xFFE24B72) : const Color(0xFFFA7094);
  Color get accent900 =>
      isLight ? const Color(0xFFCC335C) : const Color(0xFFFF94B1);

  // Backgrounds
  Color get background =>
      isLight ? const Color(0xFFF8FAFC) : const Color(0xFF000000);

  Color get transparent => Colors.transparent;

  // Font and monochromatic
  Color get fontColor => isLight
      ? const Color(0xFF0F2C5C) // texto azul oscuro
      : const Color(0xFFFFFFFF); // texto blanco

  Color get fontColorBrightness =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F2C5C);

  Color get black => const Color(0xFF000000);
  Color get white => const Color(0xFFFFFFFF);

  // Monochromatic
  Color get monochromatic50 =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);
  Color get monochromatic200 =>
      isLight ? const Color(0xFFF0F2F5) : const Color(0xFF2A2928);
  Color get monochromatic500 =>
      isLight ? const Color(0xFFD9DEE6) : const Color(0xFF3A3A3A);
  Color get monochromatic700 =>
      isLight ? const Color(0xFFBFC8D4) : const Color(0xFF5A5A5A);
  Color get monochromatic900 =>
      isLight ? const Color(0xFF4F607C) : const Color(0xFFCCCCCC);

  // Neutral y estados
  Color get grey => isLight ? const Color(0xFF454F5B) : const Color(0xFFEDEDED);
  Color get success =>
      isLight ? const Color(0xFF5D7A2E) : const Color(0xFFB1D77B);
  Color get error => const Color(0xFFD84339);
  Color get warning => const Color(0xFFFEC748);
  Color get neutral =>
      isLight ? const Color(0xFF4F607C) : const Color(0xFFCCCCCC);

  Color get otherAccent => const Color(0xFFEF5E82);

  // Cards / backgrounds secundarios
  Color get bgCard =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);
  Color get bgCard2 =>
      isLight ? const Color(0xFFF8FAFC) : const Color(0xFF2A2928);

  // Ciudadanía (mantener si se usa internamente)
  Color get ciudadaniaBoton =>
      isLight ? const Color(0xFFF18B2A) : const Color(0xFFF18B2A);

  // Chip
  Color get bgBlue =>
      isLight ? const Color(0xFF0F2C5C) : const Color(0xFF1E3A73);

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
