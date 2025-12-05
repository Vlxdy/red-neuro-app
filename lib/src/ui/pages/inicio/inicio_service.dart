import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_store.dart';

class InicioService extends ServiceConfig {
  InicioService(super.urlBase, super.context);
  final store = CodigoPinStore.instance;
  final theme = ThemeController.instance;
  final preferences = PreferencesService.instance;
  final auth = Auth.instance;

  List<int> convertirStringArrayInt(String value, {int maxDigits = 4}) {
    String dato = value.substring(0, maxDigits);
    return dato.split('').map((elem) => int.tryParse(elem) ?? 0).toList();
  }
}
