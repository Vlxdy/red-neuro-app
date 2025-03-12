import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/models/registro_meters.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/meters_mangueras.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/registro_meters_store.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';
import 'package:go_router/go_router.dart';

class MeterService extends ServiceConfig {
  MeterService(super.urlBase, super.context);
  final theme = ThemeController.instance;
  final store = DataListadoMetersStore.instance;

  void fetchData() {
    getMetersListado();
  }

  Future<void> getMetersListado() async {
    try {
      /* LoadingAnimation.instance.state = Overlay.of(context); */
      /*   LoadingAnimation.instance
          .showLoading(mensaje: 'Iniciando obtención de meters...'); */
      Logger.info('Obteniendo resgistros ...');
      final idBitadora = BitacoraStore.instance.bitacora.id;
      final response = await fetch('/mobile/$idBitadora/listar-meter',
          type: HttpProtocol.get);
      /* Logger.success('response -> ${response.data}'); */
      if (response.status == StatusNetwork.noInternet) {
        showSnackBar(
          metersMessenger,
          'No hay conexión a internet',
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        throw Exception('No hay conexión a internet');
      }
      if (response.status == StatusNetwork.connected) {
        store.dataListadoMeters =
            DataListadoMeters.fromJson(response.data['list']);
      }
      showSnackBar(
        metersMessenger,
        'Registros obtenidos correctamente',
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
    } catch (e, stacktrace) {
      Logger.error('Exception al obtener listado del registro de meters $e');
      Logger.error('stacktrace $stacktrace');
      showSnackBar(
        metersMessenger,
        'Ocurrió un error al obtener los registros.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> guardarMetersRegistro(BuildContext context) async {
    final store = RegistroMetersStore.instance;
    final idBitadora = BitacoraStore.instance.bitacora.id;

    try {
      LoadingAnimation.instance.state = Overlay.of(context);
      LoadingAnimation.instance.showLoading(mensaje: 'Guardando registro...');
      Logger.info('Guardando registro meters: $store');
      Logger.info(store.registros.toString());

      final response = await fetch('/mobile/$idBitadora/registro-meter',
          type: HttpProtocol.post,
          withAuthorization: true,
          body: {
            ...store.registros.first.toMap(),
            "fechaRegistroApp": DateTime.now().toIso8601String(),
          });
      if (response.status != StatusNetwork.connected) {
        throw Exception(response.message);
      }
/*       final json = response.data;
      await BitacoraStore.instance.actualizar(json, fechaRegistro) */

      showSnackBar(
        metersMessenger,
        'Registro guardado correctamente',
        state: StatusSnackBar.success,
        colorText: theme.white,
      );

      LoadingAnimation.instance.hideLoading();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          GoRouter.of(context).goNamed(RouteNames.home);
        }
      });
      store.limpiarRegistros();
    } catch (e, stacktrace) {
      Logger.error('Error al guardar registros meters: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        metersMessenger,
        e.toString(),
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }
}
