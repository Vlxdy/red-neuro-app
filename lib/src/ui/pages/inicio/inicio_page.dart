import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/personal_medico.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_modal.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_catalogo_selector_modal_widget.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_service.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/widgets/inicio_bandeja_counter_card.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/widgets/inicio_bandeja_section_card.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/widgets/inicio_cita_compact_tile.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final GlobalKey<ScaffoldMessengerState> misCitasHomeMessenger =
    GlobalKey<ScaffoldMessengerState>();

enum _BandejaTipo { pendientes, rechazadas, borradores, programadas }

class MisCitasHomePage extends StatefulWidget {
  const MisCitasHomePage({super.key});

  @override
  State<MisCitasHomePage> createState() => _MisCitasHomePageState();
}

class _MisCitasHomePageState extends State<MisCitasHomePage> {
  final _theme = ThemeController.instance;
  late final MisCitasHomeService _service;
  late final CitasService _citasService;

  final _dateFormat = DateFormat('dd/MM/yyyy', 'es');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es');

  HomeBandejaResult _bandeja = HomeBandejaResult.empty('', StatusNetwork.noContent);
  bool _loading = true;

  String _scope = 'mine';
  String? _idPersonalSeleccionado;
  String? _nombrePersonalSeleccionado;

  static const _collapsePendientesKey = 'inicio_bandeja_pendientes_collapsed';
  static const _collapseRechazadasKey = 'inicio_bandeja_rechazadas_collapsed';
  static const _collapseBorradoresKey = 'inicio_bandeja_borradores_collapsed';
  static const _collapseProgramadasKey = 'inicio_bandeja_programadas_collapsed';

  bool _pendientesCollapsed = false;
  bool _rechazadasCollapsed = false;
  bool _borradoresCollapsed = false;
  bool _programadasCollapsed = false;

  late final _InicioCitasSocketClient _socketClient;
  Timer? _socketReloadDebouncer;

  @override
  void initState() {
    super.initState();
    _service = MisCitasHomeService(context);
    _citasService = CitasService(context);
    _socketClient = _InicioCitasSocketClient(onEvent: _onSocketEvent);
    _loadCollapsedPreferences();
    _loadBandeja();
    unawaited(_socketClient.connect());
  }

  @override
  void dispose() {
    _socketReloadDebouncer?.cancel();
    _socketClient.dispose();
    super.dispose();
  }

  void _onSocketEvent(dynamic payload) {
    Logger.info('Inicio citas socket evento recibido: $payload');
    _socketReloadDebouncer?.cancel();
    _socketReloadDebouncer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      unawaited(_loadBandeja());
    });
  }

  Future<void> _loadCollapsedPreferences() async {
    final pendientes = await PreferencesService.instance.getString(_collapsePendientesKey);
    final rechazadas = await PreferencesService.instance.getString(_collapseRechazadasKey);
    final borradores = await PreferencesService.instance.getString(_collapseBorradoresKey);
    final programadas = await PreferencesService.instance.getString(_collapseProgramadasKey);
    if (!mounted) return;
    setState(() {
      _pendientesCollapsed = pendientes == '1';
      _rechazadasCollapsed = rechazadas == '1';
      _borradoresCollapsed = borradores == '1';
      _programadasCollapsed = programadas == '1';
    });
  }

  Future<void> _persistCollapsed(String key, bool value) async {
    await PreferencesService.instance.setString(key, value ? '1' : '0');
  }

  Future<void> _toggleBloque(_BandejaTipo tipo) async {
    switch (tipo) {
      case _BandejaTipo.pendientes:
        setState(() => _pendientesCollapsed = !_pendientesCollapsed);
        await _persistCollapsed(_collapsePendientesKey, _pendientesCollapsed);
        break;
      case _BandejaTipo.rechazadas:
        setState(() => _rechazadasCollapsed = !_rechazadasCollapsed);
        await _persistCollapsed(_collapseRechazadasKey, _rechazadasCollapsed);
        break;
      case _BandejaTipo.borradores:
        setState(() => _borradoresCollapsed = !_borradoresCollapsed);
        await _persistCollapsed(_collapseBorradoresKey, _borradoresCollapsed);
        break;
      case _BandejaTipo.programadas:
        setState(() => _programadasCollapsed = !_programadasCollapsed);
        await _persistCollapsed(_collapseProgramadasKey, _programadasCollapsed);
        break;
    }
  }

  bool get _esPersonalAdministrador {
    final profile = Auth.instance.profile;
    final rolActivo = (profile.rol ?? '').toUpperCase();
    final esPersonalSalud = rolActivo == 'PERSONAL_SALUD' ||
        profile.roles.any((rol) => rol.rol.toUpperCase() == 'PERSONAL_SALUD');
    return esPersonalSalud && profile.esSupervisor;
  }

  String get _scopeAplicado {
    if (!_esPersonalAdministrador) return 'mine';
    if (_scope == 'personal' && (_idPersonalSeleccionado == null || _idPersonalSeleccionado!.isEmpty)) {
      return 'mine';
    }
    return _scope;
  }

  bool _isCollapsed(_BandejaTipo tipo) {
    switch (tipo) {
      case _BandejaTipo.pendientes:
        return _pendientesCollapsed;
      case _BandejaTipo.rechazadas:
        return _rechazadasCollapsed;
      case _BandejaTipo.borradores:
        return _borradoresCollapsed;
      case _BandejaTipo.programadas:
        return _programadasCollapsed;
    }
  }

  Future<void> _loadBandeja() async {
    setState(() => _loading = true);
    final result = await _service.obtenerBandeja(
      limitPreview: 5,
      scope: _scopeAplicado,
      idPersonal: _scopeAplicado == 'personal' ? _idPersonalSeleccionado : null,
    );
    if (!mounted) return;
    setState(() {
      _bandeja = result;
      _loading = false;
    });
    if (result.status != StatusNetwork.connected && result.message.isNotEmpty) {
      _showError(result.message);
    }
  }

  void _showError(String message) {
    if (message.isEmpty) return;
    showSnackBar(
      misCitasHomeMessenger,
      message,
      state: StatusSnackBar.error,
      colorText: _theme.white,
    );
  }

  Future<void> _seleccionarPersonal() async {
    final seleccionado = await showModalBottomSheet<PersonalMedico>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CitasMedicoSelectorModalWidget(
        cargarMedicos: ({page = 1, limit = 10, filtro}) =>
            _citasService.obtenerPersonalMedico(page: page, limit: limit, filtro: filtro),
      ),
    );

    if (seleccionado == null || !mounted) return;
    setState(() {
      _idPersonalSeleccionado = seleccionado.id;
      _nombrePersonalSeleccionado = seleccionado.nombreCompleto;
    });
    await _loadBandeja();
  }

  Future<void> _cambiarScope(String? value) async {
    if (value == null || value == _scope) return;
    setState(() {
      _scope = value;
      if (_scope != 'personal') {
        _idPersonalSeleccionado = null;
        _nombrePersonalSeleccionado = null;
      }
    });
    await _loadBandeja();
  }

  Future<void> _abrirDetalle(_BandejaTipo tipo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BandejaDetallePage(
          tipo: tipo,
          service: _service,
          onTapCita: _mostrarDetalleCita,
          scope: _scopeAplicado,
          idPersonal: _scopeAplicado == 'personal' ? _idPersonalSeleccionado : null,
        ),
      ),
    );
  }

  Future<void> _mostrarDetalleCita(CitaMedica cita) async {
    final detallePayload = CitasUtils.construirDetalleModalPayload(
      cita: cita,
      theme: _theme,
      titulo: 'Detalle de cita',
      nombrePaciente: InicioCitasUtils.nombrePaciente,
      formatearGenero: InicioCitasUtils.formatearGenero,
      formatearFechaPaciente: InicioCitasUtils.formatearFechaPaciente,
      calcularEdadPaciente: InicioCitasUtils.calcularEdadPaciente,
      etiquetaPrestacion: InicioCitasUtils.etiquetaPrestacion,
      nombreMedico: InicioCitasUtils.nombreMedico,
      resolveAvatarUrl: (url) => (url ?? '').trim(),
      inicialesPersonal: InicioCitasUtils.inicialesPersonal,
      formatoFechaCita: InicioCitasUtils.formatoFechaCita,
      formatoHorarioCita: InicioCitasUtils.formatoHorarioCita,
    );

    final acciones = CitasUtils.construirAccionesDetalleCita(
      cita: cita,
      puedeGestionarSolicitada: (item) =>
          CitasUtils.puedeGestionarSolicitada(item, Auth.instance.profile),
      puedeEditarCita: (_) => false,
      citaYaIniciada: InicioCitasUtils.citaYaIniciada,
      confirmarCitaSolicitada: _confirmarCitaSolicitada,
      rechazarCitaSolicitada: _rechazarCitaSolicitada,
      completarCita: _completarCita,
      marcarNoAsistioCita: _marcarNoAsistio,
      reprogramarCita: _reprogramarCita,
      cancelarCita: _cancelarCita,
      eliminarBorrador: _eliminarBorrador,
      abrirFormulario: _abrirFormularioNoDisponible,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return CitasDetalleModal.fromPayload(
          cita: cita,
          theme: _theme,
          payload: detallePayload,
          acciones: acciones,
          onClose: () => Navigator.of(sheetContext).pop(),
          onVerHistorial: () => InicioCitasUtils.mostrarHistorialCita(context: context, cita: cita, service: _citasService, theme: _theme, dateFormat: _dateFormat, dateTimeFormat: _dateTimeFormat),
          onCopiarDato: (value) async => InicioCitasUtils.mostrarNoDisponible(messenger: misCitasHomeMessenger, theme: _theme, accion: 'Copiar dato'),
        );
      },
    );
  }

  Future<void> _abrirFormularioNoDisponible(CitaMedica cita) async {
    InicioCitasUtils.mostrarNoDisponible(
      messenger: misCitasHomeMessenger,
      theme: _theme,
      accion: 'Edición de cita',
    );
  }

  Future<bool> _confirmarCitaSolicitada(CitaMedica cita) async {
    final ok = await InicioCitasUtils.confirmarYEnviar(
      context: context,
      titulo: 'Confirmar cita',
      mensaje: '¿Deseas confirmar esta cita solicitada?',
      request: () => _citasService.confirmarCita(cita.id),
      fallback: 'No se pudo confirmar la cita.',
      mounted: mounted,
      onError: _showError,
    );
    if (ok) await _loadBandeja();
    return ok;
  }

  Future<bool> _rechazarCitaSolicitada(CitaMedica cita) async {
    final motivo = await InicioCitasUtils.solicitarMotivoRechazo(context);
    if (motivo == null) return false;
    final ok = InicioCitasUtils.handleResponse(
      response: await _citasService.rechazarCita(cita.id, motivoRechazo: motivo),
      fallback: 'No se pudo rechazar la cita.',
      mounted: mounted,
      onError: _showError,
    );
    if (ok) await _loadBandeja();
    return ok;
  }

  Future<void> _completarCita(CitaMedica cita) async {
    final ok = await InicioCitasUtils.confirmarYEnviar(
      context: context,
      titulo: 'Completar cita',
      mensaje: '¿Deseas marcar la cita como completada?',
      request: () => _citasService.completarCita(cita.id),
      fallback: 'No se pudo completar la cita.',
      mounted: mounted,
      onError: _showError,
    );
    if (ok) await _loadBandeja();
  }

  Future<void> _marcarNoAsistio(CitaMedica cita) async {
    final ok = await InicioCitasUtils.confirmarYEnviar(
      context: context,
      titulo: 'Marcar no asistió',
      mensaje: '¿Deseas marcar la cita como no asistió?',
      request: () => _citasService.marcarNoAsistioCita(cita.id),
      fallback: 'No se pudo actualizar la cita.',
      mounted: mounted,
      onError: _showError,
    );
    if (ok) await _loadBandeja();
  }

  Future<void> _reprogramarCita(CitaMedica cita) async {
    InicioCitasUtils.mostrarNoDisponible(
      messenger: misCitasHomeMessenger,
      theme: _theme,
      accion: 'Reprogramación de cita',
    );
  }

  Future<void> _cancelarCita(CitaMedica cita) async {
    final ok = await InicioCitasUtils.confirmarYEnviar(
      context: context,
      titulo: 'Cancelar cita',
      mensaje: '¿Deseas cancelar esta cita?',
      request: () => _citasService.cancelarCita(cita.id),
      fallback: 'No se pudo cancelar la cita.',
      mounted: mounted,
      onError: _showError,
    );
    if (ok) await _loadBandeja();
  }

  Future<void> _eliminarBorrador(CitaMedica cita) async {
    final ok = await InicioCitasUtils.confirmarYEnviar(
      context: context,
      titulo: 'Eliminar borrador',
      mensaje: '¿Deseas eliminar este borrador?',
      request: () => _citasService.eliminarCitaBorrador(cita.id),
      fallback: 'No se pudo eliminar el borrador.',
      mounted: mounted,
      onError: _showError,
    );
    if (ok) await _loadBandeja();
  }

  IconData get _scopeIcon {
    switch (_scope) {
      case 'personal':
        return Icons.badge_outlined;
      case 'all':
        return Icons.groups_rounded;
      case 'mine':
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final datos = _bandeja.datos;
    final contadores = datos.contadores;

    return TemplatePage(
      showEnvironmentBanner: false,
      page: ScaffoldMessenger(
        key: misCitasHomeMessenger,
        child: Scaffold(
          backgroundColor: _theme.background,
          appBar: TrayModuleHeader(
            titulo: 'Inicio de citas',
            subtitulo: 'Alertas, borradores y programadas asignadas',
            actions: _esPersonalAdministrador
                ? [
                    PopupMenuButton<String>(
                      tooltip: 'Cambiar alcance',
                      onSelected: _cambiarScope,
                      initialValue: _scope,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'mine', child: Text('Mis citas')),
                        PopupMenuItem(value: 'personal', child: Text('Un personal')),
                        PopupMenuItem(value: 'all', child: Text('Todos')),
                      ],
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _theme.white.withValues(alpha: 0.35)),
                          color: _theme.white.withValues(alpha: 0.08),
                        ),
                        child: Icon(_scopeIcon, size: 19, color: _theme.white),
                      ),
                    ),
                  ]
                : const [],
          ),
          body: RefreshIndicator(
            onRefresh: _loadBandeja,
            child: _loading
                ? ListView(children: const [SizedBox(height: 240), Center(child: CircularProgressIndicator())])
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_esPersonalAdministrador && _scope == 'personal')
                        _buildCompactPersonalSelector(),
                      if (_esPersonalAdministrador && _scope == 'personal')
                        const SizedBox(height: 8),
                      _buildContadores(contadores),
                      const SizedBox(height: 12),
                      _buildSeccionWidget(
                        titulo: 'Pendientes de aprobación',
                        bloque: datos.pendientesAprobacionAsignadas,
                        tipo: _BandejaTipo.pendientes,
                        isCollapsed: _isCollapsed(_BandejaTipo.pendientes),
                      ),
                      if (datos.rechazadasSolicitadasPorMi.total > 0)
                        _buildSeccionWidget(
                          titulo: 'Rechazadas solicitadas por mí',
                          bloque: datos.rechazadasSolicitadasPorMi,
                          tipo: _BandejaTipo.rechazadas,
                          isCollapsed: _isCollapsed(_BandejaTipo.rechazadas),
                        ),
                      if (datos.borradores.total > 0)
                        _buildSeccionWidget(
                          titulo: 'Borradores',
                          bloque: datos.borradores,
                          tipo: _BandejaTipo.borradores,
                          isCollapsed: _isCollapsed(_BandejaTipo.borradores),
                        ),
                      _buildSeccionWidget(
                        titulo: 'Programadas asignadas',
                        bloque: datos.programadasAsignadas,
                        tipo: _BandejaTipo.programadas,
                        isCollapsed: _isCollapsed(_BandejaTipo.programadas),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPersonalSelector() {
    final titulo = (_nombrePersonalSeleccionado ?? '').trim().isEmpty
        ? 'Seleccionar personal'
        : _nombrePersonalSeleccionado!;

    return SizedBox(
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _seleccionarPersonal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _theme.primary.withValues(alpha: 0.32)),
            color: _theme.bgCard,
            boxShadow: [
              BoxShadow(
                color: _theme.primary.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.person_search, size: 16, color: _theme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: _theme.monochromatic500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContadores(HomeContadores contadores) {
    final cards = <Widget>[
      InicioBandejaCounterCard(
        titulo: 'Pendientes',
        valor: contadores.pendientesAprobacionAsignadas,
        icon: Icons.pending_actions,
        onTap: () => _abrirDetalle(_BandejaTipo.pendientes),
        accentColor: CitasEstado.solicitada.color(_theme),
      ),
      if (contadores.rechazadasSolicitadasPorMi > 0)
        InicioBandejaCounterCard(
          titulo: 'Rechazadas',
          valor: contadores.rechazadasSolicitadasPorMi,
          icon: Icons.warning_amber,
          onTap: () => _abrirDetalle(_BandejaTipo.rechazadas),
          accentColor: CitasEstado.rechazada.color(_theme),
        ),
      if (contadores.borradores > 0)
        InicioBandejaCounterCard(
          titulo: 'Borradores',
          valor: contadores.borradores,
          icon: Icons.edit_note,
          onTap: () => _abrirDetalle(_BandejaTipo.borradores),
          accentColor: CitasEstado.borrador.color(_theme),
        ),
      InicioBandejaCounterCard(
        titulo: 'Programadas',
        valor: contadores.programadasAsignadas,
        icon: Icons.event_available,
        onTap: () => _abrirDetalle(_BandejaTipo.programadas),
        accentColor: CitasEstado.programada.color(_theme),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final totalSpacing = spacing * (cards.length - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / cards.length;

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              SizedBox(width: itemWidth, child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSeccionWidget({
    required String titulo,
    required HomePreviewBloque bloque,
    required _BandejaTipo tipo,
    required bool isCollapsed,
  }) {
    final contenido = bloque.items.isEmpty
        ? <Widget>[const Text('Sin resultados')]
        : bloque.items
            .map(
              (cita) => InicioCitaCompactTile(
                cita: cita,
                onTap: () => _mostrarDetalleCita(cita),
              ),
            )
            .toList();

    return InicioBandejaSectionCard(
      titulo: titulo,
      total: bloque.total,
      isCollapsed: isCollapsed,
      onToggle: () => _toggleBloque(tipo),
      content: contenido,
      onViewAll: bloque.total > bloque.items.length ? () => _abrirDetalle(tipo) : null,
    );
  }
}


class _InicioCitasSocketClient {
  _InicioCitasSocketClient({required this.onEvent});

  final void Function(dynamic payload) onEvent;
  io.Socket? _socket;

  static const _events = <String>[
    'cita.creada',
    'cita.actualizada',
    'cita.estado_cambiado',
    'cita.eliminada',
    'citas:home-actualizada',
    // compatibilidad con eventos existentes
    'citas:created',
    'citas:actualizada',
    'citas:estado-actualizado',
    'citas:cancelada',
  ];

  Future<void> connect() async {
    if (_socket != null) {
      if (_socket!.connected != true) _socket!.connect();
      return;
    }

    final token = await Auth.instance.apiToken;
    _socket = io.io(
      '${Constantes.sockets}/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(5000)
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('connect', (_) {
      Logger.info('Inicio citas socket conectado: ${_socket?.id}');
    });
    _socket!.on('disconnect', (reason) {
      Logger.warning('Inicio citas socket desconectado: $reason');
    });
    _socket!.on('connect_error', (error) {
      Logger.warning('Inicio citas socket connect_error: $error');
    });
    _socket!.on('error', (error) {
      Logger.warning('Inicio citas socket error: $error');
    });

    for (final event in _events) {
      _socket!.on(event, onEvent);
    }

    _socket!.connect();
  }

  void dispose() {
    if (_socket == null) return;
    for (final event in _events) {
      _socket?.off(event);
    }
    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('connect_error');
    _socket?.off('error');
    _socket?.disconnect();
    _socket = null;
  }
}

class _BandejaDetallePage extends StatefulWidget {
  const _BandejaDetallePage({
    required this.tipo,
    required this.service,
    required this.onTapCita,
    required this.scope,
    required this.idPersonal,
  });

  final _BandejaTipo tipo;
  final MisCitasHomeService service;
  final Future<void> Function(CitaMedica cita) onTapCita;
  final String scope;
  final String? idPersonal;

  @override
  State<_BandejaDetallePage> createState() => _BandejaDetallePageState();
}

class _BandejaDetallePageState extends State<_BandejaDetallePage> {
  bool _loading = true;
  bool _loadingMore = false;
  int _pagina = 1;
  int _total = 0;
  List<CitaMedica> _items = [];
  List<HomeGrupoDia> _grupos = [];

  bool get _isProgramadas => widget.tipo == _BandejaTipo.programadas;
  bool get _hasMore {
    final loaded = _isProgramadas
        ? _grupos.fold<int>(0, (acc, g) => acc + g.items.length)
        : _items.length;
    return loaded < _total;
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore || (!reset && !_hasMore)) return;
    setState(() {
      if (reset) {
        _loading = true;
        _pagina = 1;
        _items = [];
        _grupos = [];
      } else {
        _loadingMore = true;
      }
    });

    if (_isProgramadas) {
      final res = await widget.service.obtenerProgramadasAsignadas(
        pagina: _pagina,
        scope: widget.scope,
        idPersonal: widget.idPersonal,
      );
      if (!mounted) return;
      setState(() {
        _total = res.total;
        _grupos = [..._grupos, ...res.filas];
        _loading = false;
        _loadingMore = false;
        _pagina += 1;
      });
      return;
    }

    late HomeBandejaListadoResult res;
    if (widget.tipo == _BandejaTipo.pendientes) {
      res = await widget.service.obtenerPendientesAprobacion(
        pagina: _pagina,
        scope: widget.scope,
        idPersonal: widget.idPersonal,
      );
    } else if (widget.tipo == _BandejaTipo.rechazadas) {
      res = await widget.service.obtenerRechazadasSolicitadas(
        pagina: _pagina,
        scope: widget.scope,
        idPersonal: widget.idPersonal,
      );
    } else {
      res = await widget.service.obtenerBorradores(
        pagina: _pagina,
        scope: widget.scope,
        idPersonal: widget.idPersonal,
      );
    }

    if (!mounted) return;
    setState(() {
      _total = res.total;
      _items = [..._items, ...res.filas];
      _loading = false;
      _loadingMore = false;
      _pagina += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titulo = switch (widget.tipo) {
      _BandejaTipo.pendientes => 'Pendientes de aprobación',
      _BandejaTipo.rechazadas => 'Rechazadas solicitadas',
      _BandejaTipo.borradores => 'Borradores',
      _BandejaTipo.programadas => 'Programadas asignadas',
    };

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('Total: $_total', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_isProgramadas)
                  ..._buildProgramadas()
                else
                  ..._items.map((cita) => InicioCitaCompactTile(cita: cita, onTap: () => widget.onTapCita(cita))),
                if (_hasMore)
                  TextButton(
                    onPressed: _loadingMore ? null : () => _load(),
                    child: _loadingMore ? const CircularProgressIndicator() : const Text('Cargar más'),
                  ),
              ],
            ),
    );
  }

  List<Widget> _buildProgramadas() {
    final widgets = <Widget>[];
    for (final group in _grupos) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(group.dia, style: const TextStyle(fontWeight: FontWeight.w700)),
      ));
      widgets.addAll(group.items.map((cita) => InicioCitaCompactTile(cita: cita, onTap: () => widget.onTapCita(cita))));
    }
    return widgets;
  }
}

