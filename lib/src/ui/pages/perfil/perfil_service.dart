import 'dart:io';

import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/user.dart';

class PerfilService extends ServiceConfig {
  PerfilService(super.urlBase, super.context);

  Usuario? usuarioDesdeRespuesta(ResponseApi response) {
    final dynamic payload = response.log ?? response.data;
    if (payload is! Map<String, dynamic>) return null;

    final dynamic usuarioData =
        payload['datos'] ??
        payload['resultado'] ??
        payload['result'] ??
        response.data;

    if (usuarioData is! Map<String, dynamic>) return null;

    return Usuario.fromJson(usuarioData);
  }

  Future<ResponseApi> obtenerPerfil({bool refresh = false}) {
    return fetch(
      '/usuarios/cuenta/perfil',
      params: refresh
          ? <String, String>{
              't': DateTime.now().millisecondsSinceEpoch.toString(),
            }
          : null,
    );
  }

  Future<ResponseApi> actualizarFotoPerfil(File foto) {
    return multipartRequest(
      '/usuarios/cuenta/foto',
      type: 'PATCH',
      files: <File>[foto],
      nameFiles: <String>['foto'],
      image: true,
    );
  }

  Future<ResponseApi> eliminarFotoPerfil() {
    return fetch(
      '/usuarios/cuenta/foto',
      type: HttpProtocol.delete,
      body: <String, dynamic>{},
    );
  }

  Future<Usuario?> refrescarPerfilDesdeApi() async {
    final ResponseApi response = await obtenerPerfil(refresh: true);
    if (response.status != StatusNetwork.connected) {
      return null;
    }

    final dynamic payload = response.log ?? response.data;
    if (payload is Map<String, dynamic>) {
      final dynamic raw =
          payload['datos'] ??
          payload['resultado'] ??
          payload['result'] ??
          response.data;
      if (raw is Map<String, dynamic>) {
        return Usuario.fromJson(raw);
      }
    }

    return response.data.isEmpty ? null : Usuario.fromJson(response.data);
  }

  Future<Usuario?> obtenerPerfilActualizado() async {
    return refrescarPerfilDesdeApi();
  }
}
