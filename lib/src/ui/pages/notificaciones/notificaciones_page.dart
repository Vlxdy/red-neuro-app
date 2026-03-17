import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/socket_service.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/notificacion.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/notificaciones/notificaciones_service.dart';

final GlobalKey<ScaffoldMessengerState> notificacionesMessenger =
    GlobalKey<ScaffoldMessengerState>();

final ValueNotifier<int> notificacionesNoLeidasNotifier = ValueNotifier<int>(0);
final ValueNotifier<bool> notificacionesBandejaAbiertaNotifier =
    ValueNotifier<bool>(false);

Future<void> abrirBandejaNotificaciones(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) {
      final height = MediaQuery.of(sheetContext).size.height;
      return SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const NotificacionesPage(),
        ),
      );
    },
  );
}

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final _theme = ThemeController.instance;
  late final NotificacionesService _service;
  final ScrollController _scrollController = ScrollController();

  List<NotificacionItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  bool _hasMore = true;

  void Function(dynamic)? _onNuevaHandler;
  void Function(dynamic)? _onVistaHandler;
  void Function(dynamic)? _onTodasVistasHandler;

  int get _noLeidas => _items.where((item) => !item.visto).length;

  @override
  void initState() {
    super.initState();
    _service = NotificacionesService(context);
    _scrollController.addListener(_onScroll);
    _bindSocketEvents();
    notificacionesBandejaAbiertaNotifier.value = true;
    _cargarInicial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    if (_onNuevaHandler != null) {
      SocketService.instance.off('notificaciones:nueva', _onNuevaHandler);
    }
    if (_onVistaHandler != null) {
      SocketService.instance.off('notificaciones:vista', _onVistaHandler);
    }
    if (_onTodasVistasHandler != null) {
      SocketService.instance.off(
        'notificaciones:todas-vistas',
        _onTodasVistasHandler,
      );
    }
    notificacionesBandejaAbiertaNotifier.value = false;
    super.dispose();
  }



  bool _esEventoDelUsuario(Map<String, dynamic> payload) {
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

  void _actualizarBadgeNoLeidas() {
    notificacionesNoLeidasNotifier.value = _noLeidas;
  }

  void _bindSocketEvents() {
    _onNuevaHandler ??= (payload) {
      if (payload is! Map<String, dynamic>) return;
      if (!mounted || !_esEventoDelUsuario(payload)) return;
      final incoming = NotificacionItem.fromJson(payload);
      setState(() {
        final exists = _items.any((item) => item.id == incoming.id);
        if (!exists) {
          _items = [incoming, ..._items];
        }
        _total = _items.length > _total ? _items.length : _total;
      });
      _actualizarBadgeNoLeidas();
    };

    _onVistaHandler ??= (payload) {
      if (payload is! Map<String, dynamic>) return;
      if (!mounted || !_esEventoDelUsuario(payload)) return;
      final id = payload['id']?.toString();
      if (id == null || id.isEmpty) return;
      setState(() {
        _items = _items
            .map((e) => e.id == id ? e.copyWith(visto: true) : e)
            .toList();
      });
      _actualizarBadgeNoLeidas();
    };

    _onTodasVistasHandler ??= (payload) {
      if (payload is! Map<String, dynamic>) return;
      if (!mounted || !_esEventoDelUsuario(payload)) return;
      setState(() {
        _items = _items.map((e) => e.copyWith(visto: true)).toList();
      });
      _actualizarBadgeNoLeidas();
    };

    SocketService.instance.on('notificaciones:nueva', _onNuevaHandler!);
    SocketService.instance.on('notificaciones:vista', _onVistaHandler!);
    SocketService.instance.on(
      'notificaciones:todas-vistas',
      _onTodasVistasHandler!,
    );
  }

  Future<void> _cargarInicial() async {
    setState(() {
      _loading = true;
      _hasMore = true;
    });
    await _cargarBandeja(page: 1);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _cargarBandeja({required int page, bool append = false}) async {
    final result = await _service.obtenerNotificaciones(page: page, limit: _limit);
    if (!mounted) return;

    final merged = append ? [..._items, ...result.notificaciones] : result.notificaciones;
    final seen = <String>{};
    final next = <NotificacionItem>[];
    for (final item in merged) {
      final key = item.id;
      if (seen.add(key)) next.add(item);
    }

    setState(() {
      _items = next;
      _page = result.page;
      _total = result.total;
      _hasMore = _items.length < _total;
      _loadingMore = false;
    });
    _actualizarBadgeNoLeidas();

    if (result.status != StatusNetwork.connected) {
      showSnackBar(
        notificacionesMessenger,
        result.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }


  void _onScroll() {
    if (_loadingMore || !_hasMore || _loading || !_scrollController.hasClients) {
      return;
    }
    final current = _scrollController.position.pixels;
    final max = _scrollController.position.maxScrollExtent;
    if (current >= max - 120) {
      setState(() => _loadingMore = true);
      _cargarBandeja(page: _page + 1, append: true);
    }
  }

  Future<void> _marcarComoVista(NotificacionItem item) async {
    if (item.visto) return;
    final ok = await _service.marcarVista(item.id);
    if (!mounted || !ok) return;
    setState(() {
      _items = _items
          .map((e) => e.id == item.id ? e.copyWith(visto: true) : e)
          .toList();
    });
    _actualizarBadgeNoLeidas();
  }

  Future<void> _marcarTodas() async {
    final ok = await _service.marcarTodasVistas();
    if (!mounted) return;
    if (!ok) {
      showSnackBar(
        notificacionesMessenger,
        'No se pudo marcar todas como vistas',
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
      return;
    }
    setState(() {
      _items = _items.map((e) => e.copyWith(visto: true)).toList();
    });
    _actualizarBadgeNoLeidas();
  }



  bool _esProgramador(CitaMedica cita) {
    final profile = Auth.instance.profile;
    final candidatosUsuario = <String>{
      if (profile.id != null && profile.id!.isNotEmpty) profile.id!,
      if (profile.idUsuarioRol != null && profile.idUsuarioRol!.isNotEmpty)
        profile.idUsuarioRol!,
      if (profile.idRol != null && profile.idRol!.isNotEmpty) profile.idRol!,
    };
    final idProgramador = (cita.idUsuarioProgramo ?? '').trim();
    return idProgramador.isNotEmpty && candidatosUsuario.contains(idProgramador);
  }

  Future<void> _mostrarEstadoNotificacion(NotificacionItem item) async {
    await _marcarComoVista(item);
    final idCita = (item.idCita ?? '').trim();
    if (idCita.isEmpty) {
      showSnackBar(
        notificacionesMessenger,
        'Esta notificación no tiene una cita asociada.',
        state: StatusSnackBar.info,
        colorText: _theme.white,
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final cita = await _service.obtenerCitaPorId(idCita);
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    if (cita == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Estado no disponible'),
          content: const Text(
            'No pudimos consultar el estado actual de la cita asociada a esta notificación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    final estado = CitasEstado.fromValue(cita.estado.toUpperCase());
    final esProgramador = _esProgramador(cita);

    if (estado == CitasEstado.rechazada && !esProgramador) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cita no disponible'),
          content: const Text(
            'La cita fue rechazada y ya no está disponible para tu perfil.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final mensajes = <CitasEstado, String>{
      CitasEstado.solicitada: 'La cita está solicitada y pendiente de validación.',
      CitasEstado.programada: 'La cita está programada y activa.',
      CitasEstado.completada: 'La cita fue completada exitosamente.',
      CitasEstado.noAsistio: 'La cita se cerró como no asistida.',
      CitasEstado.cancelada: 'La cita fue cancelada.',
      CitasEstado.rechazada: esProgramador
          ? 'La cita está rechazada. Puedes revisarla en la bandeja de Citas.'
          : 'La cita está rechazada.',
      CitasEstado.borrador: 'La cita está en estado borrador.',
      CitasEstado.reprogramada: 'La cita fue reprogramada.',
    };

    final paciente = (cita.pacienteNombre ?? '').trim();
    final servicio = (cita.servicioNombre ?? '').trim();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Estado: ${estado.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensajes[estado] ?? 'Estado actualizado de la cita.'),
            if (paciente.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Paciente: $paciente'),
            ],
            if (servicio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Servicio: $servicio'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return TemplatePage(
      showEnvironmentBanner: false,
      page: ScaffoldMessenger(
        key: notificacionesMessenger,
        child: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
            titulo: 'Notificaciones',
            subtitulo: 'Bandeja personal de notificaciones',
            showNotificationsAction: false,
            actions: [
              if (Navigator.of(context).canPop())
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: _theme.white),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _cargarInicial,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    children: [
                      _buildUnreadHeader(),
                      const SizedBox(height: 8),
                      ..._groupedWidgets(),
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadHeader() {
    return Row(
      children: [
        Text(
          'Bandeja',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _theme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_noLeidas sin leer',
            style: const TextStyle(fontSize: 12, height: 1.1),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _noLeidas > 0 ? _marcarTodas : null,
          icon: const Icon(Icons.done_all, size: 16),
          label: const Text(
            'Marcar todas',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  List<Widget> _groupedWidgets() {
    if (_items.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay notificaciones registradas.'),
          ),
        ),
      ];
    }

    final now = DateTime.now();
    final startWeek = now.subtract(Duration(days: now.weekday - 1));

    final hoy = <NotificacionItem>[];
    final semana = <NotificacionItem>[];
    final anteriores = <NotificacionItem>[];

    for (final item in _items) {
      final date = item.fechaCreacion;
      if (DateUtils.isSameDay(date, now)) {
        hoy.add(item);
      } else if (date.isAfter(startWeek)) {
        semana.add(item);
      } else {
        anteriores.add(item);
      }
    }

    final widgets = <Widget>[];
    void appendSection(String title, List<NotificacionItem> items) {
      if (items.isEmpty) return;
      widgets
        ..add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ))
        ..addAll(items.map(_tileFor));
    }

    appendSection('Hoy', hoy);
    appendSection('Esta semana', semana);
    appendSection('Anteriores', anteriores);
    return widgets;
  }

  Widget _tileFor(NotificacionItem item) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.visto
              ? _theme.grey.withValues(alpha: 0.25)
              : _theme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _marcarComoVista(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.visto
                      ? _theme.grey.withValues(alpha: 0.16)
                      : _theme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.visto
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread,
                  size: 16,
                  color: item.visto ? _theme.secondary : _theme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.mensaje,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _theme.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: _theme.secondary.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Fecha: ${formatter.format(item.fechaCreacion)}',
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.1,
                              color: _theme.secondary.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _mostrarEstadoNotificacion(item),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Ver estado'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!item.visto)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _theme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
