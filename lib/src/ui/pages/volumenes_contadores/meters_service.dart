import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';

class MeterService extends ServiceConfig {
  MeterService(super.urlBase, super.context);

  void fetchData() {
    getMetersListado();
  }

  Future<List<Map<String, dynamic>>> getMetersListado() async {
    try {
      final idBitadora = BitacoraStore.instance.bitacora.id;
      final response = await fetch('/mobile/$idBitadora/listar-meter',
          type: HttpProtocol.get);
      Logger.success('response -> ${response.data}');
      if (response.data['list'] != null) {
        return List<Map<String, dynamic>>.from(response.data['list']);
      }
      return [];
    } catch (e, stacktrace) {
      Logger.error('Exception al obtener lisatdo del registro de meters $e');
      Logger.error('stacktrace $stacktrace');
      return [];
    }
  }
}
