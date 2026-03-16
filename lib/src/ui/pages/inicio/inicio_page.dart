import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_modal.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_service.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/widgets/inicio_bandeja_counter_card.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/widgets/inicio_bandeja_section_card.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/widgets/inicio_cita_compact_tile.dart';

final GlobalKey<ScaffoldMessengerState> misCitasHomeMessenger =
    GlobalKey<ScaffoldMessengerState>();

enum _BandejaTipo { pendientes, rechazadas, borradores, confirmadas }

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

  static const _collapsePendientesKey = 'inicio_bandeja_pendientes_collapsed';
  static const _collapseRechazadasKey = 'inicio_bandeja_rechazadas_collapsed';
  static const _collapseBorradoresKey = 'inicio_bandeja_borradores_collapsed';
  static const _collapseConfirmadasKey = 'inicio_bandeja_confirmadas_collapsed';

  bool _pendientesCollapsed = false;
  bool _rechazadasCollapsed = false;
  bool _borradoresCollapsed = false;
  bool _confirmadasCollapsed = false;

  @override
  void initState() {
    super.initState();
    _service = MisCitasHomeService(context);
    _citasService = CitasService(context);
    _loadCollapsedPreferences();
    _loadBandeja();
  }

  Future<void> _loadCollapsedPreferences() async {
    final pendientes = await PreferencesService.instance.getString(_collapsePendientesKey);
    final rechazadas = await PreferencesService.instance.getString(_collapseRechazadasKey);
    final borradores = await PreferencesService.instance.getString(_collapseBorradoresKey);
    final confirmadas = await PreferencesService.instance.getString(_collapseConfirmadasKey);
    if (!mounted) return;
    setState(() {
      _pendientesCollapsed = pendientes == '1';
      _rechazadasCollapsed = rechazadas == '1';
      _borradoresCollapsed = borradores == '1';
      _confirmadasCollapsed = confirmadas == '1';
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
      case _BandejaTipo.confirmadas:
        setState(() => _confirmadasCollapsed = !_confirmadasCollapsed);
        await _persistCollapsed(_collapseConfirmadasKey, _confirmadasCollapsed);
        break;
    }
  }

  bool _isCollapsed(_BandejaTipo tipo) {
    switch (tipo) {
      case _BandejaTipo.pendientes:
        return _pendientesCollapsed;
      case _BandejaTipo.rechazadas:
        return _rechazadasCollapsed;
      case _BandejaTipo.borradores:
        return _borradoresCollapsed;
      case _BandejaTipo.confirmadas:
        return _confirmadasCollapsed;
    }
  }

  Future<void> _loadBandeja() async {
    setState(() => _loading = true);
    final result = await _service.obtenerBandeja(limitPreview: 5);
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

  Future<void> _abrirDetalle(_BandejaTipo tipo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BandejaDetallePage(
          tipo: tipo,
          service: _service,
          onTapCita: _mostrarDetalleCita,
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
          appBar: const TrayModuleHeader(
            titulo: 'Inicio de citas',
            subtitulo: 'Alertas, borradores y confirmadas asignadas',
          ),
          body: RefreshIndicator(
            onRefresh: _loadBandeja,
            child: _loading
                ? ListView(children: const [SizedBox(height: 240), Center(child: CircularProgressIndicator())])
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
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
                        titulo: 'Confirmadas asignadas',
                        bloque: datos.confirmadasAsignadas,
                        tipo: _BandejaTipo.confirmadas,
                        isCollapsed: _isCollapsed(_BandejaTipo.confirmadas),
                      ),
                    ],
                  ),
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
        titulo: 'Confirmadas',
        valor: contadores.confirmadasAsignadas,
        icon: Icons.event_available,
        onTap: () => _abrirDetalle(_BandejaTipo.confirmadas),
        accentColor: CitasEstado.confirmada.color(_theme),
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

class _BandejaDetallePage extends StatefulWidget {
  const _BandejaDetallePage({
    required this.tipo,
    required this.service,
    required this.onTapCita,
  });

  final _BandejaTipo tipo;
  final MisCitasHomeService service;
  final Future<void> Function(CitaMedica cita) onTapCita;

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

  bool get _isConfirmadas => widget.tipo == _BandejaTipo.confirmadas;
  bool get _hasMore {
    final loaded = _isConfirmadas
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

    if (_isConfirmadas) {
      final res = await widget.service.obtenerConfirmadasAsignadas(pagina: _pagina);
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
      res = await widget.service.obtenerPendientesAprobacion(pagina: _pagina);
    } else if (widget.tipo == _BandejaTipo.rechazadas) {
      res = await widget.service.obtenerRechazadasSolicitadas(pagina: _pagina);
    } else {
      res = await widget.service.obtenerBorradores(pagina: _pagina);
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
      _BandejaTipo.confirmadas => 'Confirmadas asignadas',
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
                if (_isConfirmadas)
                  ..._buildConfirmadas()
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

  List<Widget> _buildConfirmadas() {
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

