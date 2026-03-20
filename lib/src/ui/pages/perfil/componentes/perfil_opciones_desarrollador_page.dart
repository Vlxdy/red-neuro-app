import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/socket_service.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';

class PerfilOpcionesDesarrolladorPage extends StatefulWidget {
  const PerfilOpcionesDesarrolladorPage({super.key});

  @override
  State<PerfilOpcionesDesarrolladorPage> createState() =>
      _PerfilOpcionesDesarrolladorPageState();
}

class _PerfilOpcionesDesarrolladorPageState
    extends State<PerfilOpcionesDesarrolladorPage> {
  Timer? _socketStatusTimer;

  @override
  void initState() {
    super.initState();
    _socketStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _socketStatusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;

    return TemplatePage(
      showEnvironmentBanner: false,
      page: Scaffold(
        backgroundColor: theme.transparent,
        appBar: AppBar(
          backgroundColor: theme.bgCard,
          surfaceTintColor: theme.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.fontColor),
          ),
          title: Text(
            'Opciones de desarrollador',
            style: TextStyle(
              color: theme.fontColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DeveloperPageHero(theme: theme),
              const SizedBox(height: 20),
              const _SocketStatusContent(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeveloperPageHero extends StatelessWidget {
  const _DeveloperPageHero({required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.primary.withValues(alpha: theme.isLight ? 0.12 : 0.24),
            theme.bgCard,
          ],
        ),
        border: Border.all(color: theme.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.developer_mode_rounded,
                  color: theme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Diagnóstico técnico',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: theme.fontColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Esta vista reúne herramientas internas para revisar el estado del realtime. Por ahora muestra únicamente el diagnóstico de sockets.',
            style: TextStyle(
              color: theme.fontColor.withValues(alpha: 0.74),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocketStatusContent extends StatelessWidget {
  const _SocketStatusContent();

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    final SocketService socketService = SocketService.instance;
    final bool realtimeConnected = socketService.isConnected;
    final bool notificationsReady = socketService.isNotificacionesReady;
    final bool citasReady = socketService.isCitasReady;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.grey.withValues(alpha: 0.16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.black.withValues(alpha: theme.isLight ? 0.05 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Estado de sockets',
            style: TextStyle(
              color: theme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Notificaciones y citas comparten el mismo canal realtime. Los datos se refrescan automáticamente mientras esta pantalla está abierta.',
            style: TextStyle(
              color: theme.fontColor.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _SocketStatusTile(
                theme: theme,
                title: 'Realtime',
                description: realtimeConnected
                    ? 'Conexión activa con el backend.'
                    : 'Sin conexión activa al socket.',
                connected: realtimeConnected,
                icon: Icons.power_settings_new_rounded,
              ),
              _SocketStatusTile(
                theme: theme,
                title: 'Notificaciones',
                description: notificationsReady
                    ? 'Suscripción lista para recibir eventos del usuario.'
                    : socketService.hasUsuarioSuscrito
                        ? 'Esperando que el socket termine de conectar.'
                        : 'No hay un id de usuario listo para suscribirse.',
                connected: notificationsReady,
                icon: Icons.notifications_active_outlined,
              ),
              _SocketStatusTile(
                theme: theme,
                title: 'Citas',
                description: citasReady
                    ? 'Canal listo para escuchar actualizaciones de citas.'
                    : 'Las actualizaciones de citas dependen del socket realtime.',
                connected: citasReady,
                icon: Icons.calendar_month_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SocketDebugDetail(
            theme: theme,
            label: 'Socket ID',
            value: socketService.socketId ?? 'Sin asignar',
          ),
          _SocketDebugDetail(
            theme: theme,
            label: 'Última conexión exitosa',
            value: _formatSocketDate(socketService.lastConnectAt),
          ),
          _SocketDebugDetail(
            theme: theme,
            label: 'Última desconexión',
            value:
                '${_formatSocketDate(socketService.lastDisconnectAt)}${_withPrefix(socketService.lastDisconnectReason)}',
          ),
          _SocketDebugDetail(
            theme: theme,
            label: 'Último error',
            value:
                '${_formatSocketDate(socketService.lastErrorAt)}${_withPrefix(socketService.lastErrorMessage)}',
          ),
        ],
      ),
    );
  }

  static String _formatSocketDate(DateTime? value) {
    if (value == null) return 'Sin registro';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} ${twoDigits(value.hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)} UTC';
  }

  static String _withPrefix(String? value) {
    final String normalized = (value ?? '').trim();
    if (normalized.isEmpty) return '';
    return ' · $normalized';
  }
}

class _SocketStatusTile extends StatelessWidget {
  const _SocketStatusTile({
    required this.theme,
    required this.title,
    required this.description,
    required this.connected,
    required this.icon,
  });

  final ThemeController theme;
  final String title;
  final String description;
  final bool connected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = connected ? Colors.green : theme.error;

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.bgCard2.withValues(alpha: theme.isLight ? 0.5 : 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.fontColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  connected ? 'Conectado' : 'Desconectado',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: theme.fontColor.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocketDebugDetail extends StatelessWidget {
  const _SocketDebugDetail({
    required this.theme,
    required this.label,
    required this.value,
  });

  final ThemeController theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: theme.fontColor.withValues(alpha: 0.82),
            height: 1.4,
          ),
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
