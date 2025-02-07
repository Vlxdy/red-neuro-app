import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/plugins/utils/encode.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:control_ventas_movil/src/ui/pages/cambiar_contrasena/cambiar_contrasena_store.dart';

class CambiarContrasenaService extends ServiceConfig {
  CambiarContrasenaService(super.urlBase, super.context);

  final _store = CambiarContrasenaStore.instance;

  bool validarForm(GlobalKey<FormState> formKey, String mensajeFallido) {
    final theme = ThemeController.instance;
    if (_store.nuevaContrasena != _store.repiteContrasena) {
      showSnackBar(cambiarContrasenaMessenger, mensajeFallido,
          state: StatusSnackBar.error, colorText: theme.white);
      return false;
    }
    return validateForm(formKey);
  }

  Future<void> cambiarContrasena() async {
    final theme = ThemeController.instance;
    final body = {
      'contrasenaActual': Encode.toBase64(_store.contrasena),
      'contrasenaNueva': Encode.toBase64(_store.nuevaContrasena),
    };
    _store.cargando = true;
    try {
      final response = await fetch('/usuarios/cuenta/contrasena',
          type: HttpProtocol.patch, body: body);
      if (response.status == StatusNetwork.connected) {
        showSnackBar(cambiarContrasenaMessenger, response.message,
            state: StatusSnackBar.success, colorText: theme.white);
      } else {
        showSnackBar(cambiarContrasenaMessenger, response.message,
            state: StatusSnackBar.error, colorText: theme.white);
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al cambiar contrasena $e');
      Logger.error('stacktrace $stacktrace');
    }
    _store.cargando = false;
  }
}
