import 'dart:convert';

import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/estacion_servicio.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';

class VolumenesTanquesService extends ServiceConfig {
  VolumenesTanquesService(super.urlBase, super.context);

  Future<List<VolumenTanque>> fetchData() {
    return getVolumenesTanques();
  }

  Future<List<VolumenTanque>> getVolumenesTanques() async {
    try {
      final idBitacora = BitacoraStore.instance.bitacora.id;
      final idEstacionServicio =
          EstacionServicioStore.instance.estacionServicio.id;

      Logger.info(jsonEncode(idEstacionServicio));
      Logger.info(jsonEncode(idEstacionServicio));

      final response = await fetch(
          '/mobile/bitacora/$idBitacora/estacion-servicio/$idEstacionServicio/tanques-volumenes',
          type: HttpProtocol.get);
      Logger.success('response -> ${response.data}');
      if (response.data['list'] != null) {
        return (response.data['list'] as List)
            .map((item) => VolumenTanque.fromJson(item))
            .toList();
      }

      return [];
    } catch (e, stacktrace) {
      Logger.error(
          'Exception al obtener listado del registro de volumenes $e');
      Logger.error('stacktrace $stacktrace');
      return [];
    }
  }
}
