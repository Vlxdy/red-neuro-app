import 'dart:io';

import 'package:camino_seguro/src/config/service_config.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/constants/network.dart';
import 'package:camino_seguro/src/models/area.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/ui/common/snackbar/snackbar.dart';
import 'package:camino_seguro/src/ui/global/loading_animation.dart';
import 'package:camino_seguro/src/ui/pages/areas/screens/areas.dart';
import 'package:camino_seguro/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:flutter/material.dart';

class DependientesService extends ServiceConfig {
  DependientesService(super.urlBase, super.context);
  final theme = ThemeController.instance;
  final store = RegistroAreasStore.instance;

  Future<void> fetchData() async {
    await getDependientes();
  }

  Future<void> getDependientes() async {
    store.cargando = true;
    try {
      final response = await fetch('/dependientes',
          type: HttpProtocol.get, params: {'limite': '50'});
      Logger.success('response -> ${response.data}');
      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription('La petición no se pudo completar');
      }
      showSnackBar(
        areasMessenger,
        'Registros obtenidos correctamente',
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
    } catch (e) {
      Logger.error('Exception al obtener listado del registro de volumenes $e');
      Logger.info('[getVolumenesTanques] intentando obtener registros offline');
    } finally {
      store.cargando = false;
    }
  }

  Future<void> registrarDependiente(
    BuildContext context,
    String nombre,
    List<Map<String, double>> ruta,
    List<Map<String, double>> geometria,
    String? idEdit,
  ) async {
    try {
      if (context.mounted) {
        LoadingAnimation.instance.state = Overlay.of(context);
        LoadingAnimation.instance.showLoading(mensaje: 'Registrando área...');
      }

      final body = {
        'nombre': nombre,
        'ruta': ruta,
        'geometria': geometria,
      };
      final path = idEdit != null ? '/areas/$idEdit' : '/areas';
      final response = await fetch(path,
          type: idEdit != null ? HttpProtocol.patch : HttpProtocol.post,
          body: body,
          withAuthorization: true);

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }
      showSnackBar(
        areasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      store.limpiarDatos();
      if (context.mounted) Navigator.pop(context);
    } catch (e, stacktrace) {
      Logger.error('Error al registrar área: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        areasMessenger,
        'Ocurrió un error al registrar el área',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> cambiarEstadoDependiente(
    BuildContext context,
    Area area,
  ) async {
    try {
      if (context.mounted) {
        LoadingAnimation.instance.state = Overlay.of(context);
        LoadingAnimation.instance
            .showLoading(mensaje: 'Cambiar estado área...');
      }
      final path =
          '/areas/${area.id}${area.estado == 'ACTIVO' ? '/inactivacion' : '/activacion'}';
      final response = await fetch(path,
          type: HttpProtocol.patch, withAuthorization: true, body: {});

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }
      showSnackBar(
        areasMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      store.limpiarDatos();
      if (context.mounted) Navigator.pop(context);
    } catch (e, stacktrace) {
      Logger.error('Error al actualizar estado de área: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        areasMessenger,
        'Ocurrió un error al actualizar estaso del área',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> limpiarDatos() async {
    store.limpiarDatos();
  }
}
