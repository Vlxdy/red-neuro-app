import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/models/resumen_dia.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/combustibles_store.dart';
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

 Future<void> fetchData() async {
  try {
    await cargarResumen();
    await cargarCombustibles();
  } catch (e, stackTrace) {
    print("Error en fetchData: $e");
    print(stackTrace);
  }
}

  Future<void> cargarResumen() async {
    try {
      LoadingAnimation.instance.state = Overlay.of(context);
      final response = await fetch('/mobile/bitacora/$idBitacora/resumen',
          type: HttpProtocol.get, withAuthorization: true);
      if (response.status == StatusNetwork.noInternet) {
        throw Exception('No hay conexión a internet');
      }
      if (response.status == StatusNetwork.connected) {
        store.setResumenDia = ResumenDia.fromJson(response.data);
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al obtener estaciones de servicio $e');
      Logger.error('stacktrace $stacktrace');
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> cargarCombustibles() async {
    try {
      LoadingAnimation.instance.state = Overlay.of(context);
      final response = await fetch('/combustibles/listar-combustibles',
          type: HttpProtocol.get, withAuthorization: true);
      if (response.status == StatusNetwork.noInternet) {
        throw Exception('No hay conexión a internet');
      }
      final json = response.data;
      if (response.status == StatusNetwork.connected) {
        await CombustiblesStore.instance.actualizar(json['list']);
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al obtener combustibles $e');
      Logger.error('stacktrace $stacktrace');
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }
}
