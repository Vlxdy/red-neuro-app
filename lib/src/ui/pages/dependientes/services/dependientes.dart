import 'dart:convert';

import 'package:camino_seguro/src/config/service_config.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/constants/network.dart';
import 'package:camino_seguro/src/models/dependiente.dart';
import 'package:camino_seguro/src/plugins/auth/auth.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/ui/common/snackbar/snackbar.dart';
import 'package:camino_seguro/src/ui/global/loading_animation.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/screens/dependientes.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/stores/registro_dependientes_store.dart';
import 'package:flutter/material.dart';

class DependientesService extends ServiceConfig {
  DependientesService(super.urlBase, super.context);
  final theme = ThemeController.instance;
  late String idUsuario = '';
  final store = RegistroDependientesStore.instance;

  DependientesService.named(super.urlBase, super.context) {
    _initializeIdUsuario();
  }

  void _initializeIdUsuario() async {
    idUsuario = (await Auth.instance.idUsuario) ?? '';
  }

  Future<void> fetchData(DateTime? selectedDate) async {
    await getDependientes();
    await getUbicaciones(selectedDate);
  }

  Future<void> getDependientes() async {
    try {
      final response = await fetch('/dependientes',
          type: HttpProtocol.get, params: {'limite': '50'});
      Logger.success('response -> ${response.data}');
      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription('La petición no se pudo completar');
      }
      if (response.status == StatusNetwork.connected) {
        store.setlistaDependientes = (response.data['filas'] as List)
            .map((e) => Dependiente.fromJson(e))
            .toList();
      }
      Logger.info('Registros obtenidos correctamente');
    } catch (e) {
      Logger.error('Exception al obtener listado de dependientes $e');
    } finally {}
  }

  Future<void> registrarDependiente(
    BuildContext context,
    String nombre,
    String codigo,
    List<ObjetoId> areas,
    String? idEdit,
  ) async {
    try {
      if (context.mounted) {
        LoadingAnimation.instance.state = Overlay.of(context);
        LoadingAnimation.instance
            .showLoading(mensaje: 'Registrando dependiente...');
      }

      final body = {
        'nombre': nombre,
        'codigo': codigo,
        'areas': areas,
      };
      final path = idEdit != null ? '/dependientes/$idEdit' : '/dependientes';
      final response = await fetch(path,
          type: idEdit != null ? HttpProtocol.patch : HttpProtocol.post,
          body: body,
          withAuthorization: true);

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }
      showSnackBar(
        dependientesMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (e, stacktrace) {
      Logger.error('Error al registrar dependiente: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        dependientesMessenger,
        'Ocurrió un error al registrar el dependiente',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> cambiarEstadoDependiente(
    BuildContext context,
    Dependiente dependiente,
  ) async {
    try {
      if (context.mounted) {
        LoadingAnimation.instance.state = Overlay.of(context);
        LoadingAnimation.instance
            .showLoading(mensaje: 'Cambiar estado dependiente...');
      }
      final path =
          '/dependientes/${dependiente.id}${dependiente.estado == 'ACTIVO' ? '/inactivacion' : '/activacion'}';
      final response = await fetch(path,
          type: HttpProtocol.patch, withAuthorization: true, body: {});

      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription(response.message);
      }
      showSnackBar(
        dependientesMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (e, stacktrace) {
      Logger.error('Error al actualizar estado de dependiente: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        dependientesMessenger,
        'Ocurrió un error al actualizar estaso del dependiente',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> getUbicaciones(DateTime? selectedDate) async {
    try {
      final response = await fetch(
        '/ubicaciones',
        type: HttpProtocol.get,
        params: {
          'fecha': selectedDate?.toIso8601String() ?? '',
        },
      );
      Logger.success('response -> ${response.data}');
      if (response.status != StatusNetwork.connected) {
        throw ErrorDescription('La petición no se pudo completar');
      }
      final ubicaciones = (response.data['list'] as List)
          .map((e) => DependienteRuta.fromJson(e as Map<String, dynamic>))
          .toList();
      Logger.info(
          'Ubicaciones obtenidas: ${jsonEncode(ubicaciones.map((e) => e.toString()).toList())}');

      store.setlistaDependientesRuta = ubicaciones;
      Logger.info(
          '------------------------------> ${store.listaDependientesRuta[0].rutadeHoy.coordinates}');
      if (response.status == StatusNetwork.connected) {}
      Logger.info('Registros obtenidos correctamente');
    } catch (e) {
      Logger.error('Exception al obtener listado de ubicaciones $e');
    } finally {}
  }
}
