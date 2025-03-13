import 'dart:convert';
import 'dart:io';

import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/estacion_servicio.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/registro_volumenes_store.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques.dart';
import 'package:flutter/material.dart';

class VolumenesTanquesService extends ServiceConfig {
  VolumenesTanquesService(super.urlBase, super.context);
  final theme = ThemeController.instance;
  final idBitacora = BitacoraStore.instance.bitacora.id;
  final store = RegistroVolumenesStore.instance;
  final keys = RegistroVolumenesStore.instance.fotos.keys;

  void fetchData() {
    getVolumenesTanques().whenComplete(() => store.cargando = false);
  }

  Future<void> getVolumenesTanques() async {
    try {
      final idEstacionServicio =
          EstacionServicioStore.instance.estacionServicio.id;
      final response = await fetch(
          '/mobile/bitacora/$idBitacora/estacion-servicio/$idEstacionServicio/tanques-volumenes',
          type: HttpProtocol.get);
      Logger.success('response -> ${response.data}');
      if (response.data['list'] != null) {
        final volumenes = (response.data['list'] as List)
            .map((item) => VolumenTanque.fromJson(item))
            .toList();
        store.setlistaVolumenes = volumenes;
        showSnackBar(
          volumenTanquesMessenger,
          'Registros obtenidos correctamente',
          state: StatusSnackBar.success,
          colorText: theme.white,
        );
      }
    } catch (e, stacktrace) {
      showSnackBar(
        volumenTanquesMessenger,
        'Ocurrió un error al obtener los registros.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      Logger.error('Exception al obtener listado del registro de volumenes $e');
      Logger.error('stacktrace $stacktrace');
    }
  }

  Future<void> registrarVolumenes(
      BuildContext context, FormularioRegistroVolumenes datos) async {
    try {
      if (context.mounted) {
        // Solo muestra el loading si el widget está montado
        LoadingAnimation.instance.state = Overlay.of(context);
        LoadingAnimation.instance
            .showLoading(mensaje: 'Registrando volúmenes...');
      }

      final body = {
        ...datos.toMap(),
      };
      final Map<String, List<File>> archivos = {
        for (var key in keys) key: store.obtenerFotografias(key)
      };

      final response = await multipartRequestFilesKeys(
        '/bitacora/$idBitacora/registro-tanque-volumenes',
        withAuthorization: true,
        body: body,
        files: archivos,
      );

      if (response.status != StatusNetwork.connected) {
        throw Exception(response.message);
      }
      final json = response.data;
      //Actualizar estado en la bitacora
      // await BitacoraStore.instance.actualizar(json, fechaRegistro);
      showSnackBar(
        volumenTanquesMessenger,
        'Se han registrado los valores correctamente',
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      LoadingAnimation.instance.hideLoading();
      Navigator.pop(context);
    } catch (e, stacktrace) {
      Logger.error('Error al iniciar registar volúmenes: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        volumenTanquesMessenger,
        'Ocurrió un error al registar volúmenes  $e',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }
}
