import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/models/conductor.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/plugins/utils/preferences.dart';
import 'package:control_ventas_movil/src/ui/pages/principal_page/principal_page_store.dart';

class PrincipalPageService extends ServiceConfig {
  PrincipalPageService(super.urlBase, super.context);
  final store = PrincipalPageStore.instance;
  final theme = ThemeController.instance;
  final preferences = PreferencesService.instance;
  final auth = Auth.instance;

  void fetchData() {
    // store.cargando = true;
    getConductores(store.vehiculoActivo.identidad)
        .whenComplete(() => store.cargando = false);
  }

  Future<void> getConductores(String idVehiculo) async {
    try {
      final response = await fetch('/asignacion/conductores/$idVehiculo',
          type: HttpProtocol.get);
      if (response.status == StatusNetwork.noInternet) {
        throw Exception('No hay conexión a internet');
      }
      if (response.status == StatusNetwork.connected) {
        store.conductores = (response.data['list'] as List)
            .map((item) => ConductorVehiculo.fromJson(item))
            .toList();
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al obtener vehiculos $e');
      Logger.error('stacktrace $stacktrace');
    }
  }
}
