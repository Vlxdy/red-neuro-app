// lib/src/providers/socket_provider.dart
import 'package:flutter/material.dart';
import 'package:red_neuro_app/main.dart';
import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/config/socket_service.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/pages/notificaciones/notificaciones_page.dart';
import 'package:red_neuro_app/src/ui/pages/notificaciones/notificaciones_service.dart';

class SocketProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _connected = false;
  bool get connected => _connected;
  SocketProvider();
  bool _initialized = false;
  bool _listenersBound = false;
  String? _idUsuarioRol;

  void Function(dynamic)? _onConnectHandler;
  void Function(dynamic)? _onDisconnectHandler;
  void Function(dynamic)? _onNotificacionNuevaHandler;

  /// Llamar tras el login, cuando tengas el idUsuarioRol
  Future<void> init(String idUsuarioRol) async {
    _idUsuarioRol = idUsuarioRol;
    SocketService.instance.connect(idUsuarioRol);

    if (!_initialized) {
      WidgetsBinding.instance.addObserver(this);
      _initialized = true;
    }

    _onConnectHandler ??= (_) {
      _connected = true;
      notifyListeners();
      _recontarNoLeidas();
    };
    _onDisconnectHandler ??= (_) {
      _connected = false;
      notifyListeners();
    };
    _onNotificacionNuevaHandler ??= (data) async {
      if (data is! Map<String, dynamic>) return;
      if (!_esEventoDelUsuarioActual(data)) return;

      Logger.info('Evento socket notificaciones:nueva recibido: $data');

      // Actualiza badge de forma inmediata al llegar el evento.
      final esVista = data['visto'] == true;
      if (!esVista) {
        notificacionesNoLeidasNotifier.value =
            notificacionesNoLeidasNotifier.value + 1;
      }

      // Luego sincroniza con backend para mantener consistencia, pero sin
      // retroceder el badge por desfase temporal de la API.
      await _recontarNoLeidas(minimo: notificacionesNoLeidasNotifier.value);

      if (notificacionesBandejaAbiertaNotifier.value) {
        return;
      }

      final messenger = rootScaffoldMessengerKey.currentState;
      final ctx = navigatorKey.currentContext;
      if (messenger == null || ctx == null || !ctx.mounted) return;

      final theme = ThemeController.instance;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            data['mensaje']?.toString() ?? 'Tienes una nueva notificación',
          ),
          backgroundColor: theme.primary,
          action: SnackBarAction(
            label: 'Ver',
            textColor: theme.white,
            onPressed: () async {
              final navCtx = navigatorKey.currentContext;
              if (navCtx == null || !navCtx.mounted) return;
              messenger.hideCurrentSnackBar();
              await abrirBandejaNotificaciones(navCtx);
            },
          ),
        ),
      );
    };

    if (!_listenersBound) {
      SocketService.instance.on('connect', _onConnectHandler!);
      SocketService.instance.on('disconnect', _onDisconnectHandler!);
      SocketService.instance.on(
        'notificaciones:nueva',
        _onNotificacionNuevaHandler!,
      );
      _listenersBound = true;
    }

    SocketService.instance.ensureSubscription();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized) return;
    if (state == AppLifecycleState.resumed) {
      final idUsuarioRol = _idUsuarioRol;
      if (idUsuarioRol == null || idUsuarioRol.isEmpty) return;
      Logger.info('App reanudada: revalidando conexión/suscripción socket');
      SocketService.instance.connect(idUsuarioRol);
      SocketService.instance.ensureSubscription();
      _recontarNoLeidas();
    }
  }

  bool _esEventoDelUsuarioActual(Map<String, dynamic> payload) {
    final notificacion = payload['notificacion'];
    final idPersonalEvento =
        payload['idPersonal']?.toString() ??
        (notificacion is Map ? notificacion['idPersonal']?.toString() : null);

    final profile = Auth.instance.profile;
    final candidatosUsuario = <String>{
      if (profile.id != null && profile.id!.isNotEmpty) profile.id!,
      if (profile.idUsuarioRol != null && profile.idUsuarioRol!.isNotEmpty)
        profile.idUsuarioRol!,
      if (profile.idRol != null && profile.idRol!.isNotEmpty) profile.idRol!,
    };

    if (idPersonalEvento == null || idPersonalEvento.isEmpty) {
      return true;
    }

    return candidatosUsuario.contains(idPersonalEvento);
  }

  Future<void> _recontarNoLeidas({int minimo = 0}) async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final service = NotificacionesService(context);
    final response = await service.obtenerNotificaciones(
      page: 1,
      limit: 50,
      soloNoLeidas: true,
    );
    if (response.status != StatusNetwork.connected) return;

    final totalNoLeidas = response.total;
    notificacionesNoLeidasNotifier.value =
        totalNoLeidas < minimo ? minimo : totalNoLeidas;
  }

  @override
  void dispose() {
    if (_initialized) {
      WidgetsBinding.instance.removeObserver(this);
      _initialized = false;
    }
    if (_onConnectHandler != null) {
      SocketService.instance.off('connect', _onConnectHandler);
    }
    if (_onDisconnectHandler != null) {
      SocketService.instance.off('disconnect', _onDisconnectHandler);
    }
    if (_onNotificacionNuevaHandler != null) {
      SocketService.instance.off(
        'notificaciones:nueva',
        _onNotificacionNuevaHandler,
      );
    }
    _listenersBound = false;
    SocketService.instance.disconnect();
    super.dispose();
  }
}
