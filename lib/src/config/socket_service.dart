// lib/src/services/socket_service.dart
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  /// Conecta el socket usando el userId
  void connect(String userId) {
    if (_socket != null) return;

    _socket = io.io(
      Constantes.sockets,
      io.OptionBuilder()
          .setTransports(['websocket']) // Forzar websocket
          .setQuery({'userId': userId}) // params si necesitas
          .setReconnectionAttempts(0)
          .setTimeout(5000)
          .disableAutoConnect() // conectar manualmente
          .build(),
    );

    _socket!.connect();

    _socket!.on('connect', (_) {
      debugPrint('🔌 Socket connected: ${_socket!.id}');
    });

    _socket!.on('disconnect', (reason) {
      debugPrint('🔌 Socket disconnected: $reason');
    });

    _socket!.on('connect_error', (error) {
      debugPrint('🔌 Socket connect_error: $error');
    });

    _socket!.on('error', (error) {
      debugPrint('🔌 Socket error: $error');
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
