import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

mixin Middleware {
  void validateResponse(StatusNetwork status, {bool requiresAuth = true}) {
    switch (status) {
      case StatusNetwork.unauthorized:
        Logger.error('401 - no authorizado');
        if (requiresAuth) {
          Auth.instance.logout();
        }
        return;
      case StatusNetwork.noContent:
        Logger.error('No content');
        return;
      default:
        return;
    }
  }

  Map<String, dynamic> parseResponse(
    Map<String, dynamic> json,
    BuildContext context, {
    StatusNetwork status = StatusNetwork.noContent,
    int? statusCode,
    bool requiresAuth = true,
  }) {
    try {
      final Map<String, dynamic> data = {};
      data['status'] = json.containsKey('finalizado') && json['finalizado']
          ? StatusNetwork.connected
          : status;
      if (status == StatusNetwork.connected &&
          data['status'] != StatusNetwork.connected) {
        data['status'] = StatusNetwork.exception;
      }

      data['message'] = buildDetailedMessage(
        json,
        status: data['status'] as StatusNetwork,
        statusCode: statusCode,
        requiresAuth: requiresAuth,
      );
      data['log'] = json;

      if (json.containsKey('datos') ||
          json.containsKey('resultado') ||
          json.containsKey('result')) {
        dynamic value =
            json['resultado'] ??
            json['datos'] ??
            json['result'] ??
            {'data': null};
        if (value.runtimeType == List<dynamic>) {
          data['data'] = {'list': value};
        } else if (value.runtimeType == int || value.runtimeType == String) {
          data['data'] = {'data': value};
        } else {
          data['data'] = value;
        }
      } else {
        data['data'] = json;
      }
      return data;
    } catch (e, stacktrace) {
      Logger.error('exception ${e.toString()}');
      Logger.error('stacktrace $stacktrace');
      return {
        'status': StatusNetwork.exception,
        'message':
            'Ocurrió un problema al procesar la información. Inténtelo nuevamente o comuníquese con el administrador del sistema.',
        'data': {'error': e.toString()},
      };
    }
  }

  StatusNetwork decodeStatus(int status) {
    switch (status) {
      case 200:
      case 201:
      case 202:
      case 304:
        return StatusNetwork.connected;
      case 401:
      case 403:
        return StatusNetwork.unauthorized;
      case 400:
      case 412:
        return StatusNetwork.noValidate;
      case 404:
        return StatusNetwork.noContent;
      case 422:
        return StatusNetwork.unprocessableEntity;
      case 500:
        return StatusNetwork.exception;
      default:
        return StatusNetwork.noValidate;
    }
  }

  String buildDetailedMessage(
    Map<String, dynamic> json, {
    required StatusNetwork status,
    int? statusCode,
    bool requiresAuth = true,
  }) {
    final rawMessage = _extractMessage(json);
    if (rawMessage.isNotEmpty) {
      return _decorateMessage(
        rawMessage,
        status: status,
        statusCode: statusCode,
        requiresAuth: requiresAuth,
      );
    }
    return buildHttpErrorMessage(
      status: status,
      statusCode: statusCode,
      requiresAuth: requiresAuth,
    );
  }

  String buildHttpErrorMessage({
    required StatusNetwork status,
    int? statusCode,
    Map<String, dynamic>? body,
    String? rawBody,
    bool requiresAuth = true,
  }) {
    switch (status) {
      case StatusNetwork.noInternet:
        return 'No fue posible comunicarse con el servidor. Por favor, comuníquese con el administrador del sistema.';
      case StatusNetwork.timeout:
        return 'La solicitud tardó demasiado en responder. Inténtelo nuevamente y, si el problema continúa, comuníquese con el administrador del sistema.';
      case StatusNetwork.unauthorized:
        return requiresAuth
            ? 'Su sesión ya no es válida. Inicie sesión nuevamente para continuar.'
            : 'No fue posible iniciar sesión con la información ingresada.';
      case StatusNetwork.noValidate:
      case StatusNetwork.unprocessableEntity:
        return 'No fue posible completar la solicitud. Revise la información ingresada e inténtelo nuevamente.';
      case StatusNetwork.noContent:
        return 'No se encontró información disponible para esta consulta.';
      case StatusNetwork.exception:
        return 'Ocurrió un problema al procesar la solicitud. Inténtelo nuevamente o comuníquese con el administrador del sistema.';
      case StatusNetwork.connected:
        return 'Se realizó la tarea correctamente';
    }
  }

  String _extractMessage(Map<String, dynamic> json) {
    final candidates = [
      json['mensaje'],
      json['message'],
      json['error'],
      json['detalle'],
      json['detail'],
      json['descripcion'],
      json['description'],
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeMessageValue(candidate);
      if (normalized.isNotEmpty) return normalized;
    }

    final errors = json['errors'] ?? json['errores'];
    final normalizedErrors = _normalizeMessageValue(errors);
    if (normalizedErrors.isNotEmpty) return normalizedErrors;

    return '';
  }

  String _normalizeMessageValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is List) {
      return value
          .map(_normalizeMessageValue)
          .where((item) => item.isNotEmpty)
          .join('\n');
    }
    if (value is Map) {
      return value.entries
          .map((entry) {
            final normalized = _normalizeMessageValue(entry.value);
            if (normalized.isEmpty) return '';
            return normalized;
          })
          .where((item) => item.isNotEmpty)
          .join('\n');
    }
    return value.toString().trim();
  }

  String _decorateMessage(
    String message, {
    required StatusNetwork status,
    int? statusCode,
    bool requiresAuth = true,
  }) {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      return buildHttpErrorMessage(
        status: status,
        statusCode: statusCode,
        requiresAuth: requiresAuth,
      );
    }

    return cleanMessage;
  }
}
