import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';

mixin Middleware {
  validateResponse(StatusNetwork status) {
    switch (status) {
      case StatusNetwork.unauthorized:
        Logger.error('401 - no authorizado');
        Auth.instance.logout();
        return;
      case StatusNetwork.noContent:
        Logger.error('No content');
        //TODO: make logic
        return;
      default:
        return;
    }
  }

  Map<String, dynamic> parseResponse(
    Map<String, dynamic> json,
    BuildContext context,
    { StatusNetwork status = StatusNetwork.noContent }
  ) {
    try {
      final Map<String, dynamic> data = {};
      data['status'] = json.containsKey('finalizado') && json['finalizado']
        ? StatusNetwork.connected
        : StatusNetwork.exception;
      if (status == StatusNetwork.unprocessableEntity) {
        data['status'] = StatusNetwork.unprocessableEntity;
      }

      data['message'] = json['mensaje'] ??
        json['message'] ??
        'Se realizó la tarea correctamente';

      if (json.containsKey('datos') ||
          json.containsKey('resultado') ||
          json.containsKey('result')) {
        dynamic value = json['resultado'] ??
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
        'mensaje': 'Ocurrió un error inesperado',
        'data': e.toString()
      };
    }
  }

  StatusNetwork decodeStatus(int status) {
    switch (status) {
      case 200:
        return StatusNetwork.connected;
      case 201:
        return StatusNetwork.connected;
      case 202:
        return StatusNetwork.connected;
      case 304:
        return StatusNetwork.connected;
      case 401:
        return StatusNetwork.unauthorized;
      case 400:
        return StatusNetwork.noValidate;
      case 403:
        return StatusNetwork.unauthorized;
      case 404:
        return StatusNetwork.noContent;
      case 412:
        return StatusNetwork.noValidate;
      case 422:
        return StatusNetwork.unprocessableEntity;
      case 500:
        return StatusNetwork.exception;
      default:
        return StatusNetwork.noValidate;
    }
  }
}
