import 'package:alimenta_app/src/constants/custom_theme.dart';
import 'package:alimenta_app/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();
  static final instance = ThemeController._();

  ValueNotifier<bool> brightness = ValueNotifier<bool>(true);
  bool get isLight => brightness.value;
  bool get isDark => !brightness.value;

// Colors
// Primary (naranjas)
  Color get primary20 =>
      isLight ? const Color(0xFFFFF3E0) : const Color(0xFFFFE0B2); // muy claro
  Color get primary50 =>
      isLight ? const Color(0xFFFFE0B2) : const Color(0xFFFFCC80);
  Color get primary200 =>
      isLight ? const Color(0xFFFFB74D) : const Color(0xFFFFA726);
  Color get primary =>
      isLight ? const Color(0xFFFF9800) : const Color(0xFFFF9800); // principal
  Color get primary700 =>
      isLight ? const Color(0xFFFB8C00) : const Color(0xFFF57C00);
  Color get primary900 =>
      isLight ? const Color(0xFFEF6C00) : const Color(0xFFE65100);

  // secondary
  Color get secondary => Theming.primaryDarkColor100;
  // Accent
  Color get accent50 => Theming.accentColor50;
  Color get accent100 => Theming.accentColor100;
  Color get accent200 => Theming.accentColor200;
  Color get accent500 => Theming.accentColor500;
  Color get accent700 => Theming.accentColor700;
  Color get accent900 => Theming.accentColor900;

  // Background
  Color get background =>
      isLight ? const Color(0xFFFFFFFF) : Theming.backgroundDark;

  Color get transparent => Colors.transparent;

  // Font and monocromatic
  Color get fontColor => isLight ? Theming.black : Theming.white;
  Color get fontColorBrightness => isLight ? Theming.white : Theming.black;

  Color get black => Theming.black;
  Color get white => Theming.white;
  // Monochromatic 50 is white and black
  Color get monochromatic50 =>
      isLight ? Theming.monochromatic10 : Theming.monochromatic2;
  Color get monochromatic200 =>
      isLight ? Theming.monochromatic9 : Theming.monochromatic2;
  Color get monochromatic500 =>
      isLight ? Theming.monochromatic8 : Theming.monochromatic3;
  Color get monochromatic700 =>
      isLight ? Theming.monochromatic7 : Theming.monochromatic4;
  Color get monochromatic900 =>
      isLight ? Theming.monochromatic6 : Theming.monochromatic5;

  // Neutral
  Color get grey => isLight ? Theming.grey : Theming.greyDark;
  Color get success => isLight ? Theming.success : Theming.successDark;
  Color get error => isLight ? Theming.error : Theming.errorDark;
  Color get warning => isLight ? Theming.warning : Theming.warningDark;
  Color get neutral => isLight ? Theming.neutral : Theming.neutralDark;

  Color get otherAccent => isLight ? Theming.otherAccent : Theming.otherAccent;
  Color get bgCard => Theming.bgCard;
  Color get bgCard2 => Theming.bgCard2;

  //Ciudadania
  Color get ciudadaniaBoton =>
      isLight ? Theming.ciudadania : Theming.ciudadaniaDark;

  // Chip
  Color get bgBlue => Theming.bgBlue;

  Color calculateTextColor(Color background) {
    return background.computeLuminance() >= 0.5 ? Theming.black : Theming.white;
  }

  //Theme Methods
  void changeTheme() async {
    brightness.value = !brightness.value;
    await PreferencesService.instance.setBool('theme', brightness.value);
  }

  Future<void> initTheme() async {
    brightness.value = await PreferencesService.instance.getBool('theme');
  }
}
