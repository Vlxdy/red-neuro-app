import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/plugins/utils/encode.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena_store.dart';

class CambioContrasenaResult {
  const CambioContrasenaResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class CambiarContrasenaService extends ServiceConfig {
  CambiarContrasenaService(super.urlBase, super.context);

  final CambiarContrasenaStore _store = CambiarContrasenaStore.instance;

  String? validarContrasenaActual(String? value) {
    return _validarCampoRequerido(value, 'Contraseña actual');
  }

  String? validarNuevaContrasena(String? value) {
    final String? error = _validarCampoRequerido(value, 'Nueva contraseña');
    if (error != null) return error;

    if (value!.trim().length < 8) {
      return 'Mínimo 8 caracteres';
    }

    return null;
  }

  String? validarRepetirContrasena(String? value) {
    final String? error = _validarCampoRequerido(
      value,
      'Repite la nueva contraseña',
    );
    if (error != null) return error;

    if (value != _store.nuevaContrasena) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  bool validarForm(GlobalKey<FormState> formKey) {
    return validateForm(formKey);
  }

  Future<CambioContrasenaResult> cambiarContrasena() async {
    final Map<String, dynamic> body = <String, dynamic>{
      'contrasenaActual': Encode.toBase64(_store.contrasena),
      'contrasenaNueva': Encode.toBase64(_store.nuevaContrasena),
    };
    _store.cargando = true;
    try {
      final ResponseApi response = await fetch(
        '/usuarios/cuenta/contrasena',
        type: HttpProtocol.patch,
        body: body,
      );
      if (response.status == StatusNetwork.connected) {
        final String message = _resolveSuccessMessage(response);
        _limpiarFormulario();
        return CambioContrasenaResult(success: true, message: message);
      } else {
        final String message = _resolveErrorMessage(response);
        return CambioContrasenaResult(
          success: false,
          message: message,
        );
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al cambiar contrasena $e');
      Logger.error('stacktrace $stacktrace');
      return const CambioContrasenaResult(
        success: false,
        message: 'No se pudo cambiar la contraseña. Inténtalo nuevamente.',
      );
    } finally {
      _store.cargando = false;
    }
  }

  String? _validarCampoRequerido(String? value, String alias) {
    if (value == null || value.trim().isEmpty) {
      return '$alias es requerido';
    }

    return null;
  }

  String _resolveErrorMessage(ResponseApi response) {
    final String responseMessage = response.message.trim();
    if (responseMessage.isNotEmpty) {
      return responseMessage;
    }

    final dynamic dataMessage =
        response.data['message'] ?? response.data['mensaje'];
    if (dataMessage is String && dataMessage.trim().isNotEmpty) {
      return dataMessage.trim();
    }

    return 'No fue posible cambiar la contraseña.';
  }

  String _resolveSuccessMessage(ResponseApi response) {
    final String responseMessage = response.message.trim();
    if (responseMessage.isNotEmpty) {
      return responseMessage;
    }

    final dynamic dataMessage =
        response.data['message'] ?? response.data['mensaje'];
    if (dataMessage is String && dataMessage.trim().isNotEmpty) {
      return dataMessage.trim();
    }

    return 'La contraseña se cambió correctamente.';
  }

  void _limpiarFormulario() {
    _store.contrasena = '';
    _store.nuevaContrasena = '';
    _store.repiteContrasena = '';
    _store.calificacion = 0;
  }
}
