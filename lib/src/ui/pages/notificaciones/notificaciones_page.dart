import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/notificacion.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/notificaciones/notificaciones_service.dart';

final GlobalKey<ScaffoldMessengerState> notificacionesMessenger =
    GlobalKey<ScaffoldMessengerState>();

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
  ResumenDiario? _resumen;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  bool _hasMore = true;

  int get _noLeidas => _items.where((item) => !item.visto).length;

  @override
  void initState() {
    super.initState();
    _service = NotificacionesService(context);
    _scrollController.addListener(_onScroll);
    _cargarInicial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _cargarInicial() async {
    setState(() {
      _loading = true;
      _hasMore = true;
    });
    await Future.wait([_cargarBandeja(page: 1), _cargarResumen()]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _cargarBandeja({required int page, bool append = false}) async {
    final result = await _service.obtenerNotificaciones(page: page, limit: _limit);
    if (!mounted) return;

    final userId = Auth.instance.profile.id ?? '';
    final merged = append ? [..._items, ...result.notificaciones] : result.notificaciones;
    final seen = <String>{};
    final next = <NotificacionItem>[];
    for (final item in merged) {
      final key = item.dedupeKey(userId);
      if (seen.add(key)) next.add(item);
    }

    setState(() {
      _items = next;
      _page = result.page;
      _total = result.total;
      _hasMore = _items.length < _total;
      _loadingMore = false;
    });

    if (result.status != StatusNetwork.connected) {
      showSnackBar(
        notificacionesMessenger,
        result.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _cargarResumen() async {
    final resumen = await _service.obtenerResumenDiario();
    if (!mounted) return;
    setState(() => _resumen = resumen);
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
  }

  @override
  Widget build(BuildContext context) {
    final user = Auth.instance.profile;
    final isAdmin = (user.rol ?? '').toUpperCase().contains('ADMIN');

    return TemplatePage(
      showEnvironmentBanner: false,
      page: ScaffoldMessenger(
        key: notificacionesMessenger,
        child: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
            titulo: 'Notificaciones',
            subtitulo: 'Resumen diario y bandeja de notificaciones',
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ResumenCard(resumen: _resumen, isAdmin: isAdmin),
                      const SizedBox(height: 12),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _theme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$_noLeidas sin leer'),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _noLeidas > 0 ? _marcarTodas : null,
          icon: const Icon(Icons.done_all, size: 18),
          label: const Text('Marcar todas'),
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
          padding: const EdgeInsets.only(top: 10, bottom: 6),
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
      child: ListTile(
        onTap: () => _marcarComoVista(item),
        leading: Icon(
          item.visto ? Icons.mark_email_read_outlined : Icons.mark_email_unread,
          color: item.visto ? _theme.secondary : _theme.primary,
        ),
        title: Text(item.mensaje),
        subtitle: Text(formatter.format(item.fechaCreacion)),
        trailing: !item.visto
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _theme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.resumen, required this.isAdmin});

  final ResumenDiario? resumen;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Card(
      color: theme.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen diario',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            if (resumen == null)
              const Text('No se encontró resumen para hoy.')
            else ...[
              if (isAdmin) ...[
                Text('• Citas con personal: ${resumen!.citasConPersonal}'),
                Text('• Citas sin personal: ${resumen!.citasSinPersonal}'),
              ] else
                Text(
                  '• Citas confirmadas asignadas: ${resumen!.citasConfirmadasAsignadas}',
                ),
              const SizedBox(height: 6),
              Text('Fecha: ${resumen!.fecha}'),
            ],
          ],
        ),
      ),
    );
  }
}
