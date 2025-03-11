import 'package:control_ventas_movil/src/models/venta.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/combustibles_store.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/stores/venta_bidones_store.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';

GlobalKey<ScaffoldMessengerState> bidonesMessenger =
GlobalKey<ScaffoldMessengerState>();

class VentaBidonesService extends ServiceConfig {
  VentaBidonesService(super.urlBase, super.context);

  final store = VentaBidonesStore.instance;
  final theme = ThemeController.instance;

  final idBitacora = BitacoraStore.instance.bitacora.id;

  void fetchDataBidones() {
    cargarVentasBidones().whenComplete(() => store.cargando = false);
  }

  Future<void> cargarVentasBidones() async {
    try {

      final dataa = CombustiblesStore.instance;
      print('yoss:3');
      for (final x in dataa.combustibles) {
        print(x.codigo);
        print(x.color);
        print(x.descripcion);
        print(x.id);
        print('-'*10);
      }
      print('yoss:4');
      store.cargando = true;
      LoadingAnimation.instance.state = Overlay.of(context);
      // LoadingAnimation.instance.showLoading(mensaje: 'Cargando Bidones...');

      final response = await fetch(
        '/mobile/$idBitacora/listar-venta?tipoVenta=Bidones',
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
        bidonesMessenger,
        'Ocurrió un error al obtener ventas',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
      store.cargando = false;
    }
  }

  Future<void> incrementarVenta(String idCombustible, String observacion) async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          LoadingAnimation.instance.state = Overlay.of(context);
          LoadingAnimation.instance.showLoading(mensaje: 'Registrando venta...');
        }
      });

      final response = await fetch(
        '/mobile/$idBitacora/registro-venta',
        type: HttpProtocol.post,
        withAuthorization: true,
        body: {
          "tipoVenta": "Bidones",
          "fechaRegistroApp": DateTime.now().toIso8601String(),
          "idCombustible": idCombustible,
          "observacion": observacion.isEmpty ? null : observacion,
        },
      );

      if (response.status != StatusNetwork.connected) {
        throw Exception(response.message);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showSnackBar(
            bidonesMessenger,
            'Venta registrada correctamente',
            state: StatusSnackBar.success,
            colorText: theme.white,
          );
        }
      });

      fetchDataBidones();
    } catch (e, stacktrace) {
      Logger.error('Error al registrar venta: $e');
      Logger.error('Stacktrace: $stacktrace');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showSnackBar(
            bidonesMessenger,
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
