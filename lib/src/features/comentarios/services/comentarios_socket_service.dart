import 'dart:async';

import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ComentariosSocketService {
  ComentariosSocketService._();

  static final ComentariosSocketService instance = ComentariosSocketService._();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    final token = await Auth.instance.apiToken;
    final url = '${Constantes.sockets}/comentarios';

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );

    final completer = Completer<void>();

    _socket!.on('connect', (_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    _socket!.on('connect_error', (error) {
      if (!completer.isCompleted) {
        completer.completeError(error ?? 'Error de conexión');
      }
    });

    _socket!.connect();

    await completer.future;
  }

  void onCambio(void Function(dynamic data) handler) {
    _socket?.on('comentario:cambio', handler);
  }

  void offCambio(void Function(dynamic data) handler) {
    _socket?.off('comentario:cambio', handler);
  }

  void joinHistoriaClinica(String historiaClinicaId) {
    if (historiaClinicaId.isEmpty) return;
    _socket?.emit('joinHistoriaClinica', {
      'historiaClinicaId': historiaClinicaId,
    });
  }

  void leaveHistoriaClinica(String historiaClinicaId) {
    if (historiaClinicaId.isEmpty) return;
    _socket?.emit('leaveHistoriaClinica', {
      'historiaClinicaId': historiaClinicaId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
