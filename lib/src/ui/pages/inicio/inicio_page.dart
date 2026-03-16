import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_modal.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_service.dart';

final GlobalKey<ScaffoldMessengerState> misCitasHomeMessenger =
    GlobalKey<ScaffoldMessengerState>();

class MisCitasHomePage extends StatefulWidget {
  const MisCitasHomePage({super.key});

  @override
  State<MisCitasHomePage> createState() => _MisCitasHomePageState();
}

class _MisCitasHomePageState extends State<MisCitasHomePage> {
  static const _collapsedKey = 'mis_citas_solicitadas_collapsed';

  final _theme = ThemeController.instance;
  final _scrollController = ScrollController();

  late final MisCitasHomeService _service;
  late final CitasService _citasService;

  final _dateFormat = DateFormat('dd/MM/yyyy', 'es');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es');

  MisCitasResumenResult _resumen =
      MisCitasResumenResult.empty('', StatusNetwork.noContent);
  List<CitaMedica> _solicitadas = [];
  List<MisCitasTimelineGroup> _timeline = [];

  String? _solicitadasCursor;
  bool _solicitadasHasMore = true;
  int _solicitadasTotalAprox = 0;

  bool _timelineHasMore = true;
  String? _timelineCursorFechaHora;
  String? _timelineCursorId;

  bool _loading = true;
  bool _loadingSolicitadas = false;
  bool _loadingTimeline = false;
  bool _solicitadasCollapsed = false;

  int get _timelineItemsCount => _timeline.fold<int>(
        0,
        (prev, element) => prev + element.items.length,
      );

  @override
  void initState() {
    super.initState();
    _service = MisCitasHomeService(context);
    _citasService = CitasService(context);
    _scrollController.addListener(_onScroll);
    _loadCollapsedPreference();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadCollapsedPreference() async {
    final saved = await PreferencesService.instance.getString(_collapsedKey);
    if (!mounted || saved.isEmpty) return;
    setState(() => _solicitadasCollapsed = saved == '1');
  }

  Future<void> _persistCollapsedPreference() async {
    await PreferencesService.instance.setString(
      _collapsedKey,
      _solicitadasCollapsed ? '1' : '0',
    );
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _solicitadas = [];
      _timeline = [];
      _solicitadasCursor = null;
      _timelineCursorFechaHora = null;
      _timelineCursorId = null;
      _solicitadasHasMore = true;
      _timelineHasMore = true;
      _solicitadasTotalAprox = 0;
    });

    await Future.wait([
      _loadResumen(),
      _loadSolicitadas(reset: true),
      _loadTimeline(reset: true),
    ]);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadResumen() async {
    final resumen = await _service.obtenerResumen();
    if (!mounted) return;
    setState(() => _resumen = resumen);
    if (resumen.status != StatusNetwork.connected && resumen.message.isNotEmpty) {
      _showError(resumen.message);
    }
  }

  Future<void> _loadSolicitadas({bool reset = false}) async {
    if (_loadingSolicitadas) return;
    if (!reset && !_solicitadasHasMore) return;

    setState(() => _loadingSolicitadas = true);
    final result = await _service.obtenerSolicitadas(
      cursor: reset ? null : _solicitadasCursor,
    );

    if (!mounted) return;

    if (result.status != StatusNetwork.connected) {
      _showError(result.message);
      setState(() => _loadingSolicitadas = false);
      return;
    }

    setState(() {
      _solicitadas = reset ? result.items : [..._solicitadas, ...result.items];
      _solicitadasCursor = result.nextCursor;
      _solicitadasHasMore = result.hasMore;
      _solicitadasTotalAprox = result.totalAprox;
      _loadingSolicitadas = false;
    });
  }

  Future<void> _loadTimeline({bool reset = false}) async {
    if (_loadingTimeline) return;
    if (!reset && !_timelineHasMore) return;

    setState(() => _loadingTimeline = true);
    final result = await _service.obtenerTimeline(
      cursorFechaHora: reset ? null : _timelineCursorFechaHora,
      cursorId: reset ? null : _timelineCursorId,
    );

    if (!mounted) return;

    if (result.status != StatusNetwork.connected) {
      _showError(result.message);
      setState(() => _loadingTimeline = false);
      return;
    }

    setState(() {
      _timeline = reset ? result.grupos : [..._timeline, ...result.grupos];
      _timelineHasMore = result.hasMore;
      _timelineCursorFechaHora = result.nextCursorFechaHora;
      _timelineCursorId = result.nextCursorId;
      _loadingTimeline = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingTimeline) return;
    final current = _scrollController.position.pixels;
    final max = _scrollController.position.maxScrollExtent;
    if (current >= max - 180) {
      _loadTimeline();
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

  Future<void> _toggleSolicitadas() async {
    setState(() => _solicitadasCollapsed = !_solicitadasCollapsed);
    await _persistCollapsedPreference();
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
    if (ok) await _loadInitial();
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
    if (ok) await _loadInitial();
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
    if (ok) await _loadInitial();
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
    if (ok) await _loadInitial();
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
    if (ok) await _loadInitial();
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
    if (ok) await _loadInitial();
  }


  @override
  Widget build(BuildContext context) {
    return TemplatePage(
      showEnvironmentBanner: false,
      page: ScaffoldMessenger(
        key: misCitasHomeMessenger,
        child: Scaffold(
          backgroundColor: _theme.background,
          appBar: const TrayModuleHeader(
            titulo: 'Inicio de citas',
            subtitulo: 'Resumen, solicitadas y timeline de mis citas',
          ),
          body: RefreshIndicator(
            onRefresh: _loadInitial,
            child: _loading
                ? ListView(
                    children: const [
                      SizedBox(height: 240),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildResumen()),
                      SliverToBoxAdapter(child: _buildSolicitadasHeader()),
                      if (!_solicitadasCollapsed)
                        SliverToBoxAdapter(child: _buildSolicitadasItems()),
                      SliverToBoxAdapter(child: _buildTimelineHeader()),
                      ..._buildTimelineSlivers(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumen() {
    final primeraFecha = _resumen.primeraFechaConCitas;
    final textoPrimeraFecha = primeraFecha == null
        ? 'Sin fecha'
        : DateFormat('EEE d MMM', 'es').format(primeraFecha);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMiniCard(
              titulo: 'Solicitadas',
              valor: _resumen.solicitadasPendientesConfirmacion,
              icon: Icons.pending_actions,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryMiniCard(
              titulo: 'Confirmadas',
              valor: _resumen.proximasConfirmadas,
              icon: Icons.event_available,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryMiniCard(
              titulo: 'Desde hoy',
              valor: _resumen.totalDesdeHoy,
              icon: Icons.today,
              extra: textoPrimeraFecha,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitadasHeader() {
    final totalLabel = _solicitadasTotalAprox > 0
        ? 'Mostrando ${_solicitadas.length} de aprox $_solicitadasTotalAprox'
        : '${_solicitadas.length} cargadas';

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: const Text(
        'Solicitadas',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(totalLabel),
      trailing: IconButton(
        tooltip: _solicitadasCollapsed ? 'Expandir' : 'Colapsar',
        onPressed: _toggleSolicitadas,
        icon: Icon(_solicitadasCollapsed ? Icons.expand_more : Icons.expand_less),
      ),
    );
  }

  Widget _buildSolicitadasItems() {
    if (_solicitadas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('No hay citas solicitadas.'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (final cita in _solicitadas)
            _CitaCompactTile(
              cita: cita,
              onTap: () => _mostrarDetalleCita(cita),
            ),
          if (_solicitadasHasMore)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _loadingSolicitadas ? null : () => _loadSolicitadas(),
                icon: _loadingSolicitadas
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: const Text('Ver más solicitadas'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader() {
    final subtitle = _timelineHasMore
        ? 'Cargadas: $_timelineItemsCount'
        : 'Cargadas: $_timelineItemsCount · fin del timeline';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline por fecha',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          Text(
            subtitle,
            style: TextStyle(color: _theme.secondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineSlivers() {
    if (_timeline.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('No hay citas para mostrar en el timeline.'),
              ),
            ),
          ),
        ),
      ];
    }

    final slivers = <Widget>[];
    for (final group in _timeline) {
      final fechaTexto = group.fecha == null
          ? 'Fecha no disponible'
          : DateFormat('EEEE d MMM yyyy', 'es').format(group.fecha!);

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              fechaTexto,
              style: TextStyle(
                color: _theme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverList.builder(
          itemCount: group.items.length,
          itemBuilder: (context, index) {
            final cita = group.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _CitaCompactTile(
                cita: cita,
                onTap: () => _mostrarDetalleCita(cita),
              ),
            );
          },
        ),
      );
    }

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loadingTimeline
              ? const Center(child: CircularProgressIndicator())
              : (!_timelineHasMore
                    ? const Center(child: Text('Fin del timeline'))
                    : const SizedBox.shrink()),
        ),
      ),
    );

    return slivers;
  }
}

class _SummaryMiniCard extends StatelessWidget {
  const _SummaryMiniCard({
    required this.titulo,
    required this.valor,
    required this.icon,
    this.extra,
  });

  final String titulo;
  final int valor;
  final IconData icon;
  final String? extra;

  Color _cardAccent() {
    final key = titulo.toLowerCase();
    if (key.contains('solicit')) return Colors.deepOrange;
    if (key.contains('confirm')) return Colors.indigo;
    return Colors.purple;
  }


  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final accent = _cardAccent();

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: theme.isDark ? 0.18 : 0.10),
            accent.withValues(alpha: theme.isDark ? 0.10 : 0.05),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent.withValues(alpha: 0.86)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.neutral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$valor',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.neutral,
            ),
          ),
          if (extra != null)
            Text(
              extra!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: theme.neutral.withValues(alpha: 0.80),
              ),
            ),
        ],
      ),
    );
  }
}

class _CitaCompactTile extends StatelessWidget {
  const _CitaCompactTile({required this.cita, required this.onTap});

  final CitaMedica cita;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final inicio = cita.fechaInicio;
    final fin = cita.fechaFin;
    final hora = inicio == null
        ? '--:--'
        : DateFormat('HH:mm').format(inicio.toLocal());
    final rangoFin = fin == null ? '--:--' : DateFormat('HH:mm').format(fin.toLocal());
    final estado = cita.estado.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: _estadoColor(estado),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.pacienteNombre?.isNotEmpty == true
                          ? cita.pacienteNombre!
                          : cita.detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.neutral,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$hora-$rangoFin · ${cita.servicioNombre ?? 'Sin servicio'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: theme.secondary),
                    ),
                    Text(
                      cita.lugarNombre ?? 'Lugar no definido',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: theme.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _estadoColor(estado).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    color: _estadoColor(estado),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'SOLICITADA':
        return Colors.orange;
      case 'CONFIRMADA':
        return Colors.blue;
      case 'CANCELADA':
      case 'RECHAZADA':
        return Colors.red;
      case 'COMPLETADA':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }
}

class _DetalleRow extends StatelessWidget {
  const _DetalleRow({required this.label, required this.value});

  final String label;
  final String value;


  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.neutral),
            ),
          ),
        ],
      ),
    );
  }
}
