import 'package:flutter/foundation.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  String? _idUsuarioRol;
  final Map<String, Map<Function, dynamic Function(dynamic)>> _wrappedHandlers =
      {};

  bool get isConnected => _socket?.connected == true;

  /// Conecta el socket al namespace unificado de realtime.
  void connect(String idUsuarioRol) {
    _idUsuarioRol = idUsuarioRol;
    if (_socket != null) {
      if (_socket!.connected == true) {
        debugPrint('♻️ Socket ya conectado, revalidando suscripción');
        subscribeNotificaciones();
      }
      if (_socket!.connected != true) {
        _socket!.connect();
      }
      return;
    }

    _socket = io.io(
      '${Constantes.sockets}/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(Constantes.socketPath)
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(5000)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('🔌 Socket connected: ${_socket!.id}');
      subscribeNotificaciones();
    });

    _socket!.on('reconnect', (_) {
      debugPrint('🔁 Socket reconnect detectado');
      subscribeNotificaciones();
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

    // Logs para corroborar todo el tráfico esperado en consola.
    const debugEvents = <String>[
      'notificaciones:nueva',
      'notificaciones:vista',
      'notificaciones:todas-vistas',
      'citas:created',
      'citas:actualizada',
      'citas:estado-actualizado',
      'citas:reprogramada',
      'citas:cancelada',
    ];
    for (final event in debugEvents) {
      _socket!.on(event, (data) {
        debugPrint('📥 socket event=$event payload=$data');
      });
    }

    _socket!.connect();
  }

  void emit(String event, [dynamic data]) {
    debugPrint('📤 socket emit $event -> $data');
    _socket?.emit(event, data);
  }

  void subscribeNotificaciones() {
    if (_idUsuarioRol == null || _idUsuarioRol!.isEmpty) return;
    emit('notificaciones:subscribe', {'idUsuarioRol': _idUsuarioRol});
    debugPrint('✅ Suscripción notificaciones con idUsuarioRol=$_idUsuarioRol');
  }

  void ensureSubscription() {
    if (_socket == null) return;
    if (_socket!.connected == true) {
      debugPrint('🔄 Forzando resuscripción de notificaciones');
      subscribeNotificaciones();
      return;
    }
    debugPrint('🔄 Socket no conectado en ensureSubscription, conectando...');
    _socket!.connect();
  }

  /// Suscribe un listener a un evento
  void on(String event, void Function(dynamic data) handler) {
    final wrapped = (dynamic data) {
      debugPrint('👂 listener event=$event payload=$data');
      handler(data);
    };
    _wrappedHandlers.putIfAbsent(event, () => {})[handler] = wrapped;
    _socket?.on(event, wrapped);
  }

  /// Elimina listeners de un evento
  void off(String event, [dynamic Function(dynamic)? handler]) {
    if (handler == null) {
      _socket?.off(event);
      _wrappedHandlers.remove(event);
      return;
    }
    final wrapped = _wrappedHandlers[event]?.remove(handler);
    _socket?.off(event, wrapped ?? handler);
  }

  /// Desconecta y destruye el socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _idUsuarioRol = null;
    _wrappedHandlers.clear();
  }
}
