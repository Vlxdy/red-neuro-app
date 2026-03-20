import 'package:flutter/foundation.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  String? _idUsuario;
  DateTime? _lastConnectAt;
  DateTime? _lastDisconnectAt;
  DateTime? _lastErrorAt;
  String? _lastDisconnectReason;
  String? _lastErrorMessage;
  final Map<String, Map<Function, dynamic Function(dynamic)>> _wrappedHandlers =
      {};

  bool get isConnected => _socket?.connected == true;
  bool get hasSocketInstance => _socket != null;
  bool get hasUsuarioSuscrito => (_idUsuario ?? '').trim().isNotEmpty;
  bool get isNotificacionesReady => isConnected && hasUsuarioSuscrito;
  bool get isCitasReady => isConnected;
  String? get socketId => _socket?.id;
  DateTime? get lastConnectAt => _lastConnectAt;
  DateTime? get lastDisconnectAt => _lastDisconnectAt;
  DateTime? get lastErrorAt => _lastErrorAt;
  String? get lastDisconnectReason => _lastDisconnectReason;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Conecta el socket al namespace unificado de realtime.
  void connect(String idUsuario) {
    _idUsuario = idUsuario;
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
      _lastConnectAt = DateTime.now();
      _lastDisconnectReason = null;
      _lastErrorMessage = null;
      debugPrint('🔌 Socket connected: ${_socket!.id}');
      subscribeNotificaciones();
    });

    _socket!.on('reconnect', (_) {
      debugPrint('🔁 Socket reconnect detectado');
      subscribeNotificaciones();
    });

    _socket!.onDisconnect((reason) {
      _lastDisconnectAt = DateTime.now();
      _lastDisconnectReason = reason?.toString();
      debugPrint('🔌 Socket disconnected: $reason');
    });

    _socket!.onConnectError((error) {
      _lastErrorAt = DateTime.now();
      _lastErrorMessage = error?.toString();
      debugPrint('🔌 Socket connect_error: $error');
    });

    _socket!.onError((error) {
      _lastErrorAt = DateTime.now();
      _lastErrorMessage = error?.toString();
      debugPrint('🔌 Socket error: $error');
    });

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
    if (_idUsuario == null || _idUsuario!.isEmpty) return;
    emit('notificaciones:subscribe', {'idUsuario': _idUsuario});
    debugPrint('✅ Suscripción notificaciones con idUsuario=$_idUsuario');
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

  void on(String event, void Function(dynamic data) handler) {
    final wrapped = (dynamic data) {
      debugPrint('👂 listener event=$event payload=$data');
      handler(data);
    };
    _wrappedHandlers.putIfAbsent(event, () => {})[handler] = wrapped;
    _socket?.on(event, wrapped);
  }

  void off(String event, [dynamic Function(dynamic)? handler]) {
    if (handler == null) {
      _socket?.off(event);
      _wrappedHandlers.remove(event);
      return;
    }
    final wrapped = _wrappedHandlers[event]?.remove(handler);
    _socket?.off(event, wrapped ?? handler);
  }

  void disconnect() {
    _lastDisconnectAt = DateTime.now();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _idUsuario = null;
    _wrappedHandlers.clear();
  }
}
