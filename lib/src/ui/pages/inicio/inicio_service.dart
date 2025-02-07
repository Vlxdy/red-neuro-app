
import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/preferences.dart';
import 'package:control_ventas_movil/src/ui/pages/inicio/inicio_store.dart';

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
