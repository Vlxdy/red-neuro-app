// lib/src/services/socket_service.dart
import 'package:camino_seguro/src/constants/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  IO.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  /// Conecta el socket usando el userId
  void connect(String userId) {
    if (_socket != null) return;

    _socket = IO.io(
      Constantes.sockets,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Forzar websocket
          .setQuery({'userId': userId}) // params si necesitas
          .disableAutoConnect() // conectar manualmente
          .build(),
    );

    _socket!.connect();

    _socket!.on('connect', (_) {
      debugPrint('🔌 Socket connected: ${_socket!.id}');
    });

    _socket!.on('disconnect', (_) {
      debugPrint('🔌 Socket disconnected');
    });
  }

  /// Suscribe un listener a un evento
  void on<T>(String event, void Function(T data) handler) {
    _socket?.on(event, (data) => handler(data as T));
  }

  /// Elimina listeners de un evento
  void off(String event) {
    _socket?.off(event);
  }

  /// Desconecta y destruye el socket
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
