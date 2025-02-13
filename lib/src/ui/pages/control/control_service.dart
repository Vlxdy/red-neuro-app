import 'package:control_ventas_movil/src/constants/constants.dart';
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

  ControlService(BuildContext context)
      : super(
    Constantes.apiUrl,
    context,
  );

  Future<void> cargarDatosIniciales() async {
    try {
      LoadingAnimation.instance.showLoading(mensaje: 'Cargando datos...');
      // TODO: cargar los datos desde backend
    } catch (e, stacktrace) {
      Logger.error('Error cargando datos: $e');
      Logger.error('Stacktrace: $stacktrace');
      showSnackBar(
        controlMessenger,
        'Error al cargar datos iniciales',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> iniciarControl() async {
    try {
      LoadingAnimation.instance.showLoading(mensaje: 'Iniciando control...');
      final estacion = store.estacionSeleccionada;
      final horario = store.horarioSeleccionado;
      Logger.info('Iniciando control con estación: $estacion y horario: $horario');

      // TODO: Cargar datos, y navegar a Resumen del Dia
      // final response = await fetch('/control/iniciar',
      //   type: HttpProtocol.post,
      //   body: {
      //     'estacion_id': estacion,
      //     'horario_id': horario,
      //   },
      // );
      // if (response.status != StatusNetwork.connected) {
      //   throw Exception(response.message);
      // }
      // if (context.mounted) {
      //   context.goNamed(RouteNames.algunOtroScreen);
      // }
      showSnackBar(
        controlMessenger,
        'Control iniciado correctamente',
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
      store.clean();
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
