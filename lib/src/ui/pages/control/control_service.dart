import 'package:control_ventas_movil/src/constants/constants.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/models/estacion_servicio.dart';
import 'package:control_ventas_movil/src/models/horario.dart';
import 'package:control_ventas_movil/src/plugins/bitacora/bitacora.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_store.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control.dart';

class ControlService extends ServiceConfig {
  final theme = ThemeController.instance;
  final store = ControlStore.instance;
  final bitacoraStore = BitacoraStore.instance;

  ControlService(BuildContext context)
      : super(
          Constantes.apiUrl,
          context,
        );

  void fetchData() {
    cargarDatosIniciales().whenComplete(() => store.cargando = false);
  }

  Future<void> cargarDatosIniciales() async {
    try {
      final response = await fetch('/mobile/inicio/bitacora',
          type: HttpProtocol.get, withAuthorization: true);
      if (response.status == StatusNetwork.noInternet) {
        throw Exception('No hay conexión a internet');
      }
      if (response.status == StatusNetwork.connected) {
        store.estaciones = (response.data['estaciones-de-servicios'][0] as List)
            .map((item) => EstacionServicio.fromJson(item))
            .toList();
        store.horarios = (response.data['horarios'][0] as List)
            .map((item) => Horario.fromJson(item))
            .toList();
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al obtener estaciones de servicio $e');
      Logger.error('stacktrace $stacktrace');
    }
  }

  Future<void> iniciarControl() async {
    try {
      LoadingAnimation.instance.state = Overlay.of(context);
      LoadingAnimation.instance.showLoading(mensaje: 'Iniciando control...');
      final estacion = store.estacionSeleccionada;
      final horario = store.horarioSeleccionado;
      final fechaRegistro = DateTime.now().toString();
      Logger.info(
          'Iniciando control con estación: $estacion y horario: $horario');

      try {
        final response = await fetch('/mobile/bitacora',
            type: HttpProtocol.post,
            withAuthorization: true,
            body: {
              "idEstacionServicio": estacion,
              "idHorario": horario,
              "fechaRegistro": fechaRegistro,
            });
        if (response.status != StatusNetwork.connected) {
          throw Exception(response.message);
        }
        final datos = response.data;
        bitacoraStore.setBitacora(datos['idBitacora'], DateTime.now());
        Logger.sesion(datos.toString());
        Logger.sesion(bitacoraStore.bitacora!.toString());
        showSnackBar(
          controlMessenger,
          'Control iniciado correctamente',
          state: StatusSnackBar.success,
          colorText: theme.white,
        );
      } catch (e) {
        Logger.error('Ocurrió un error -> $e');
        showSnackBar(controlMessenger, '$e',
            state: StatusSnackBar.error, colorText: theme.white);
      } finally {
        LoadingAnimation.instance.hideLoading();
      }
      // store.clean();
    } catch (e, stacktrace) {
      Logger.error('Error al iniciar control: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        controlMessenger,
        'Ocurrió un error al iniciar el control',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }
}
