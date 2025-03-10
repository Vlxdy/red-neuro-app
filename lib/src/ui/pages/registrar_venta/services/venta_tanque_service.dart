import 'dart:io';
import 'package:control_ventas_movil/src/models/venta.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/stores/venta_tanques_store.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';

GlobalKey<ScaffoldMessengerState> tanquesMessenger = GlobalKey<ScaffoldMessengerState>();

class VentaTanquesService extends ServiceConfig {
  VentaTanquesService(super.urlBase, super.context);

  final store = VentaTanquesStore.instance;
  final theme = ThemeController.instance;

  final idBitacora = BitacoraStore.instance.bitacora.id;

  void fetchDataTanques() {
    cargarVentasTanques().whenComplete(() => store.cargando = false);
  }

  Future<void> cargarVentasTanques() async {
    try {
      store.cargando = true;
      LoadingAnimation.instance.state = Overlay.of(context);

      final response = await fetch(
        '/mobile/$idBitacora/listar-venta?tipoVenta=Tanque adicional',
        type: HttpProtocol.get,
        withAuthorization: true,
      );

      if (response.status == StatusNetwork.noInternet) {
        throw Exception('No hay conexión a internet');
      }

      if (response.status == StatusNetwork.connected) {
        final datos = response.data;

        store.ventas = (datos['list'] as List<dynamic>)
            .map((item) => Venta.fromJson(item))
            .toList();
      } else {
        Logger.error('Error al obtener datos. Status: ${response.status}');
      }
    } catch (e, stacktrace) {
      Logger.error('Error al obtener ventas de bidones: $e');
      Logger.error('stacktrace: $stacktrace');
      showSnackBar(
        tanquesMessenger,
        'Ocurrió un error al obtener ventas',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
      store.cargando = false;
    }
  }

  Future<void> registrarVentaTanqueConMultipart({
    required List<String> pathsDeFotos,
    required String placa,
    required int idCombustible,
    required DateTime fechaRegistroApp,
    required BuildContext context,
    String? observacion,
  }) async {
    try {
      final List<File> files = pathsDeFotos.map((path) => File(path)).toList();

      final body = {
        'placa': placa,
        'idCombustible': '$idCombustible',
        'tipoVenta': 'Tanque adicional',
        'fechaRegistroApp': fechaRegistroApp.toIso8601String(),
        if (observacion != null && observacion.isNotEmpty)
          'observacion': observacion,
      };

      final response = await multipartRequest(
          '/mobile/$idBitacora/registro-venta',
          type: 'POST',
          files: files,
          nameFiles: files.map((_) => 'files').toList(),
          body: body,
          image: true);

      if (response.status != StatusNetwork.connected) {
        throw Exception(response.message);
      }
    } catch (e, stacktrace) {
      Logger.error('Error al registrar venta: $e');
      Logger.error('Stacktrace: $stacktrace');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showSnackBar(
            tanquesMessenger,
            'Ocurrió un error al registrar la venta',
            state: StatusSnackBar.error,
            colorText: theme.white,
          );
        }
      });
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          LoadingAnimation.instance.hideLoading();
        }
      });
    }
  }
}
