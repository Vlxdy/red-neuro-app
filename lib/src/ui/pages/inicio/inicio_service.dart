import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_store.dart';

class InicioService extends ServiceConfig {
  InicioService(super.urlBase, super.context);
  final CodigoPinStore store = CodigoPinStore.instance;
  final ThemeController theme = ThemeController.instance;
  final PreferencesService preferences = PreferencesService.instance;
  final Auth auth = Auth.instance;

  List<int> convertirStringArrayInt(String value, {int maxDigits = 4}) {
    String dato = value.substring(0, maxDigits);
    return dato
        .split('')
        .map((String elem) => int.tryParse(elem) ?? 0)
        .toList();
  }
}
