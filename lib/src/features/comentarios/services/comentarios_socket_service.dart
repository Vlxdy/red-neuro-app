import 'dart:async';

import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
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

    final String token = await Auth.instance.apiToken;
    final String url = '${Constantes.sockets}/comentarios';

    final String auth = token.replaceAll('"', "");
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': auth})
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );

    final Completer<void> completer = Completer<void>();

    _socket!.on('connect', (_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    _socket!.on('connect_error', (dynamic error) {
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
