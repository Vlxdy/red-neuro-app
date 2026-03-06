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
          .setTransports(['websocket'])
          .setPath(Constantes.socketPath)
          .setQuery({'userId': userId})
          .setReconnectionAttempts(0)
          .setTimeout(5000)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('🔌 Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((reason) {
      debugPrint('🔌 Socket disconnected: $reason');
    });

    _socket!.onConnectError((error) {
      debugPrint('🔌 Socket connect_error: $error');
    });

    _socket!.onError((error) {
      debugPrint('🔌 Socket error: $error');
    });

    _socket!.connect();
  }

  /// Suscribe un listener a un evento
  void on<T>(String event, void Function(T data) handler) {
    _socket?.on(event, (data) {
      handler(data as T);
    });
  }

  /// Elimina listeners de un evento
  void off(String event) {
    _socket?.off(event);
  }

  /// Desconecta y destruye el socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
