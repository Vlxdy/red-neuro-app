import 'dart:convert';

import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/estacion_servicio.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques.dart';
import 'package:flutter/material.dart';

class VolumenesTanquesService extends ServiceConfig {
  VolumenesTanquesService(super.urlBase, super.context);
  final theme = ThemeController.instance;
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
      Logger.error('Exception al obtener listado del registro de volumenes $e');
      Logger.error('stacktrace $stacktrace');
      return [];
    }
  }

  Future<void> registrarVolumenes(
      BuildContext context, Map<String, dynamic> datos) async {
    try {
      LoadingAnimation.instance.state = Overlay.of(context);
      LoadingAnimation.instance.showLoading(mensaje: 'Iniciando control...');

      Logger.info(jsonEncode(datos));
      Logger.info('--------------------------');
      final response = await fetch('/mobile/bitacora',
          type: HttpProtocol.post,
          withAuthorization: true,
          body: {
            // "idEstacionServicio": estacion,
            // "idHorario": horario,
            // "fechaRegistro": fechaRegistro.toString(),
          });
      if (response.status != StatusNetwork.connected) {
        throw Exception(response.message);
      }
      final json = response.data;
      // await BitacoraStore.instance.actualizar(json, fechaRegistro);
      showSnackBar(
        volumenTanquesMessenger,
        'Control iniciado correctamente',
        state: StatusSnackBar.success,
        colorText: theme.white,
      );

      LoadingAnimation.instance.hideLoading();
    } catch (e, stacktrace) {
      Logger.error('Error al iniciar control: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        volumenTanquesMessenger,
        'Ocurrió un error al iniciar el control',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }
}
