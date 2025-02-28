import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia_store.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';

class ResumenDiaService extends ServiceConfig {
  ResumenDiaService(super.urlBase, super.context);
  final theme = ThemeController.instance;
  final store = ResumenDiaStore.instance;

  final idBitacora = BitacoraStore.instance.bitacora.id;

  void fetchData() {
    cargarResumen().whenComplete(() => {});
  }

  Future<void> cargarResumen() async {
    try {
      LoadingAnimation.instance.state = Overlay.of(context);
      final response =
          await fetch('/mobile/bitacora/1/resumen', // todo cambiar idBitacora
              type: HttpProtocol.get,
              withAuthorization: true);
      if (response.status == StatusNetwork.noInternet) {
        throw Exception('No hay conexión a internet');
      }
      if (response.status == StatusNetwork.connected) {
        Logger.info(response.data.toString());
        store.setResumenDia = (response.data['datos']);
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al obtener estaciones de servicio $e');
      Logger.error('stacktrace $stacktrace');
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }
}
