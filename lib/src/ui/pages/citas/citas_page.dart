import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/lugar.dart';
import 'package:red_neuro_app/src/models/personal_medico.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_active_filters.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_agenda.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_modal.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_confirmacion_dialog.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_formulario_modal_widget.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_filtros_modal_widget.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_catalogo_selector_modal_widget.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_historial_modal_widget.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_modo_mis_citas_banner.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;


final GlobalKey<ScaffoldMessengerState> citasMessenger =
    GlobalKey<ScaffoldMessengerState>();

class CitasPage extends StatefulWidget {
  final bool soloMisCitas;
  final String titulo;
  final bool mostrarFiltroMedico;

  const CitasPage({
    super.key,
    required this.soloMisCitas,
    required this.titulo,
    this.mostrarFiltroMedico = false,
  });

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> with WidgetsBindingObserver {
  static const _soloMisCitasPreferenceKey = 'citas_solo_mis_asignadas';
  final ThemeController _theme = ThemeController.instance;
  late final CitasService _service;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  List<CitaMedica> _citasCalendario = [];
  List<CitaMedica> _citasListado = [];
  List<CitaMedica> _citasSeleccionadas = [];
  List<CitaMedica> _citasAgenda = [];
  Map<DateTime, int> _cantidadCitasCalendarioPorDia = {};

  bool _loading = false;
  bool _agendaLoading = false;
  bool _agendaCalendarLoading = false;
  int _dayRequestId = 0;
  int _agendaRequestId = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late DateTime _agendaDay;
  late DateTime _agendaFocusedDay;
  CalendarFormat _agendaCalendarFormat = CalendarFormat.week;
  final int _currentTabIndex = 0;
  bool _soloCitasAsignadas = false;

  String _buscarTexto = '';
  late final TextEditingController _buscarController;
  late final TextEditingController _medicoFiltroController;
  late final TextEditingController _estadoFiltroController;
  late final TextEditingController _lugarFiltroController;
  final ScrollController _filtersScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _agendaScrollController = ScrollController();
  bool _agendaCalendarCollapsed = false;
  String? _estadoFiltro;
  String? _medicoFiltro;
  String? _medicoFiltroNombre;
  String? _lugarFiltro;
  String? _lugarFiltroNombre;
  int _listPage = 1;
  int _listLimit = 10;

  late final _CitasSocketClient _socketClient;
  bool get _usarSoloMisCitas => widget.soloMisCitas || _soloCitasAsignadas;
  bool get _bloquearFiltroMedicoPorSoloMisCitas =>
      _usarSoloMisCitas && widget.mostrarFiltroMedico;

  String get _nombreMedicoActual {
    final perfil = Auth.instance.profile;
    final nombreCompleto = [
      perfil.nombres,
      perfil.primerApellido,
      perfil.segundoApellido,
    ].where((valor) => valor.trim().isNotEmpty).join(' ').trim();
    return nombreCompleto.isNotEmpty ? nombreCompleto : 'Mi agenda';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
    _agendaDay = DateTime(now.year, now.month, now.day);
    _agendaFocusedDay = _agendaDay;
    _buscarController = TextEditingController();
    _medicoFiltroController = TextEditingController();
    _estadoFiltroController = TextEditingController(
      text: CitasEstado.labelFromValue(null),
    );
    _lugarFiltroController = TextEditingController();
    _service = CitasService(context);
    _socketClient = _CitasSocketClient(
      onCreated: _onSocketCreated,
      onActualizada: _onSocketActualizada,
      onEstadoActualizado: _onSocketEstadoActualizado,
      onReprogramada: _onSocketReprogramada,
      onCancelada: _onSocketCancelada,
    );
    _cargarInicial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _buscarController.dispose();
    _medicoFiltroController.dispose();
    _estadoFiltroController.dispose();
    _lugarFiltroController.dispose();
    _filtersScrollController.dispose();
    _listScrollController.dispose();
    _agendaScrollController.dispose();
    _socketClient.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_restaurarConexionSocketYRecargar());
    }
  }

  Future<void> _restaurarConexionSocketYRecargar() async {
    await _socketClient.ensureConnected();
    if (!mounted) return;
    await _cargarCitasAgendaSemana();
    if (!mounted) return;
    await _cargarCitasAgendaDay(day: _agendaDay);
  }

  Future<void> _cargarInicial() async {
    if (!widget.soloMisCitas) {
      final soloMisCitasGuardado = await PreferencesService.instance.getBool(
        _soloMisCitasPreferenceKey,
      );
      if (!mounted) return;
      setState(() {
        _soloCitasAsignadas = soloMisCitasGuardado;
      });
    } else {
      _soloCitasAsignadas = true;
    }

    await _socketClient.connect();
    await _cargarCitasAgendaSemana();
    await _cargarCitasAgendaDay(day: _agendaDay);
  }

  Future<void> _cargarCitasCalendario() async {
    setState(() => _loading = true);
    await _recargarConteoCitasCalendario();
    if (!mounted) return;
    setState(() => _loading = false);
    await _cargarCitasDelDia();
  }

  Future<void> _recargarConteoCitasCalendario() async {
    if (mounted) {
      setState(() => _agendaCalendarLoading = true);
    }
    try {
      final filtros = _buildCalendarFiltersQuery();
      final cantidadPorDia = await _service.obtenerCantidadCitasPorDia(
        filtros: filtros,
      );
      if (!mounted) return;
      setState(() {
        _cantidadCitasCalendarioPorDia = cantidadPorDia;
      });
    } finally {
      if (mounted) {
        setState(() => _agendaCalendarLoading = false);
      }
    }
  }

  Future<void> _cargarCitasAgendaSemana() async {
    await _recargarConteoCitasCalendario();
  }

  Future<void> _cargarCitasListado({int? page}) async {
    final isLoadMore = (page ?? _listPage) > 1;
    if (!isLoadMore) {
      setState(() => _loading = true);
    }
    final filtros = _buildListFiltersQuery();
    final result = await _service.obtenerCitasPaginadas(
      page: page ?? _listPage,
      limit: _listLimit,
      filtros: filtros.isNotEmpty ? filtros : null,
    );

    setState(() {
      final shouldAppend = (page ?? _listPage) > 1;
      _citasListado = shouldAppend
          ? [..._citasListado, ...result.citas]
          : result.citas;
      _listPage = result.page;
      _listLimit = result.limit;
      _loading = false;
    });
  }

  Map<String, String> _buildCalendarFiltersQuery() {
    final filtros = _buildBaseFiltersQuery();
    final range = _resolveCalendarRange();
    filtros['fechaInicio'] = range.start.toUtc().toIso8601String();
    filtros['fechaFin'] = range.end.toUtc().toIso8601String();
    return filtros;
  }

  Map<String, String> _buildListFiltersQuery() {
    return _buildBaseFiltersQuery();
  }

  Map<String, String> _buildDayFiltersQuery(DateTime day) {
    final filtros = _buildBaseFiltersQuery();
    final start = DateTime(day.year, day.month, day.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    filtros['fechaInicio'] = start.toUtc().toIso8601String();
    filtros['fechaFin'] = end.toUtc().toIso8601String();
    return filtros;
  }

  Map<String, String> _buildBaseFiltersQuery() {
    final filtros = <String, String>{};
    if (_estadoFiltro != null && _estadoFiltro!.isNotEmpty) {
      filtros['estado'] = _estadoFiltro!;
    }

    final medicoFiltro = (_medicoFiltro?.isNotEmpty ?? false)
        ? _medicoFiltro!
        : _usarSoloMisCitas
        ? (Auth.instance.profile.idUsuarioRol ?? '')
        : '';

    if (medicoFiltro.isNotEmpty) {
      filtros['idPersonal'] = medicoFiltro;
    }

    if (_lugarFiltro != null && _lugarFiltro!.isNotEmpty) {
      filtros['idLugar'] = _lugarFiltro!;
    }

    return filtros;
  }

  List<CitaMedica> _filtrarCitasLocal(List<CitaMedica> citas) {
    if (_buscarTexto.trim().isEmpty) return citas;
    final query = _buscarTexto.toLowerCase();
    return citas
        .where(
          (cita) =>
              cita.detalle.toLowerCase().contains(query) ||
              cita.medicoId.toLowerCase().contains(query) ||
              cita.estado.toLowerCase().contains(query),
        )
        .toList();
  }

  String _validarRequerido(String? value, String alias) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    return '';
  }

  Future<bool> _handleResponseError(
    ResponseApi response,
    String fallbackMessage,
  ) async {
    if (response.status == StatusNetwork.connected) return true;
    final message = response.message.isNotEmpty
        ? response.message
        : fallbackMessage;
    await showErrorDialog(context, message);
    return false;
  }

  Future<String?> _confirmarAccionCita({
    required bool esNueva,
    required String tipoCita,
    required String servicioNombre,
    required DateTime fechaInicio,
    int? duracionMinutos,
    String? pacienteNombre,
    String? ocupacionNombre,
    String? medicoNombre,
    String? pacienteDocumento,
    String? pacienteTelefono,
    String? pacienteGenero,
    String? lugarNombre,
    String? lugarDireccion,
    String? detalle,
  }) {
    return showCitaConfirmacionDialog(
      context: context,
      data: CitaAccionConfirmacionData(
        esNueva: esNueva,
        tipoCita: tipoCita,
        servicioNombre: servicioNombre,
        fechaInicio: fechaInicio,
        duracionMinutos: duracionMinutos,
        pacienteNombre: pacienteNombre,
        ocupacionNombre: ocupacionNombre,
        medicoNombre: medicoNombre,
        pacienteDocumento: pacienteDocumento,
        pacienteTelefono: pacienteTelefono,
        pacienteGenero: pacienteGenero,
        lugarNombre: lugarNombre,
        lugarDireccion: lugarDireccion,
        detalle: detalle,
      ),
      dateTimeFormat: _dateTimeFormat,
      formatearGenero: _formatearGenero,
    );
  }

  void _onSocketCreated(dynamic data) {
    final cita = _parseSocketCita(data);
    if (cita == null) return;
    _syncSocketCita(cita);
    unawaited(_recargarConteoCitasCalendario());
  }

  void _onSocketEstadoActualizado(dynamic data) {
    if (data is Map<String, dynamic>) {
      final id = (data['id'] ?? data['citaId'] ?? '').toString();
      final estado = (data['estado'] ?? '').toString();
      if (id.isEmpty) return;
      _patchSocketCitaById(
        id,
        (cita) =>
            cita.copyWith(estado: estado.isNotEmpty ? estado : cita.estado),
      );
      unawaited(_recargarConteoCitasCalendario());
      return;
    }
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _syncSocketCita(cita);
      unawaited(_recargarConteoCitasCalendario());
    }
  }

  void _onSocketActualizada(dynamic data) {
    final cita = _parseSocketCita(data);
    if (cita == null) return;
    _syncSocketCita(cita);
    unawaited(_recargarConteoCitasCalendario());
  }

  void _onSocketReprogramada(dynamic data) {
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _syncSocketCita(cita);
      unawaited(_recargarConteoCitasCalendario());
      return;
    }
    if (data is Map<String, dynamic>) {
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) return;
      _patchSocketCitaById(
        id,
        (cita) => cita.copyWith(
          fechaInicio: _parseDate(data['fechaInicio']),
          fechaFin: _parseDate(data['fechaFin']),
        ),
      );
      unawaited(_recargarConteoCitasCalendario());
    }
  }

  void _onSocketCancelada(dynamic data) {
    if (data is Map<String, dynamic>) {
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) return;
      _patchSocketCitaById(id, (cita) => cita.copyWith(estado: 'CANCELADA'));
      unawaited(_recargarConteoCitasCalendario());
      return;
    }
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _syncSocketCita(cita.copyWith(estado: 'CANCELADA'));
      unawaited(_recargarConteoCitasCalendario());
    }
  }

  CitaMedica? _parseSocketCita(dynamic data) {
    final map = _normalizeSocketMap(data);
    if (map != null) {
      return CitaMedica.fromJson(map);
    }
    return null;
  }

  Map<String, dynamic>? _normalizeSocketMap(dynamic data) {
    if (data is! Map) return null;
    return data.map((key, value) => MapEntry(key.toString(), value));
  }

  void _syncSocketCita(CitaMedica cita) {
    setState(() {
      _citasCalendario = _upsertOrRemoveCitaEnLista(
        _citasCalendario,
        cita,
        _shouldIncludeInCalendario,
      );
      _citasListado = _upsertOrRemoveCitaEnLista(
        _citasListado,
        cita,
        _shouldIncludeInListado,
      );
      _citasAgenda = _upsertOrRemoveCitaEnAgenda(_citasAgenda, cita);
    });
  }

  void _patchSocketCitaById(
    String id,
    CitaMedica Function(CitaMedica) updater,
  ) {
    setState(() {
      _citasCalendario = _actualizarCitaConFiltro(
        _citasCalendario,
        id,
        updater,
        _shouldIncludeInCalendario,
      );
      _citasListado = _actualizarCitaConFiltro(
        _citasListado,
        id,
        updater,
        _shouldIncludeInListado,
      );
      _citasAgenda = _actualizarAgendaConFiltro(_citasAgenda, id, updater);
    });
  }

  bool _matchesBaseSocketFilters(CitaMedica cita) {
    final estado = cita.estado.trim();
    if (_estadoFiltro != null &&
        _estadoFiltro!.isNotEmpty &&
        estado != _estadoFiltro) {
      return false;
    }

    final medicoFiltro = (_medicoFiltro?.isNotEmpty ?? false)
        ? _medicoFiltro!
        : _usarSoloMisCitas
        ? (Auth.instance.profile.idUsuarioRol ?? '')
        : '';

    if (medicoFiltro.isNotEmpty && cita.idPersonal != medicoFiltro) {
      return false;
    }

    if ((_lugarFiltro?.isNotEmpty ?? false) && cita.lugarId != _lugarFiltro) {
      return false;
    }

    if ((estado == 'BORRADOR' || estado == 'RECHAZADA') &&
        !_canViewRestrictedDraftStatus(cita)) {
      return false;
    }

    return true;
  }

  bool _canViewRestrictedDraftStatus(CitaMedica cita) {
    if (Auth.instance.profile.esSupervisor) return true;
    final idUsuarioRol = (Auth.instance.profile.idUsuarioRol ?? '').trim();
    if (idUsuarioRol.isEmpty) return false;
    final idCreador = (cita.idUsuarioProgramo ?? '').trim();
    return idCreador.isNotEmpty && idCreador == idUsuarioRol;
  }

  bool _isInCalendarRange(CitaMedica cita) {
    final fecha = cita.fechaInicio;
    if (fecha == null) return false;
    final range = _resolveCalendarRange();
    return !fecha.isBefore(range.start) && !fecha.isAfter(range.end);
  }

  bool _shouldIncludeInCalendario(CitaMedica cita) {
    return _matchesBaseSocketFilters(cita) && _isInCalendarRange(cita);
  }

  bool _shouldIncludeInListado(CitaMedica cita) {
    return _matchesBaseSocketFilters(cita);
  }

  bool _shouldIncludeInAgenda(CitaMedica cita) {
    if (!_matchesBaseSocketFilters(cita)) return false;
    final fecha = cita.fechaInicio;
    return fecha != null && isSameDay(fecha, _agendaDay);
  }

  List<CitaMedica> _upsertOrRemoveCitaEnLista(
    List<CitaMedica> lista,
    CitaMedica cita,
    bool Function(CitaMedica cita) shouldInclude,
  ) {
    final include = shouldInclude(cita);
    final index = lista.indexWhere((item) => item.id == cita.id);

    if (!include) {
      if (index < 0) return lista;
      final updated = [...lista]..removeAt(index);
      return updated;
    }

    if (index >= 0) {
      final updated = [...lista];
      updated[index] = cita;
      return updated;
    }

    if (_currentTabIndex == 2 && _listPage > 1) {
      return lista;
    }

    return [cita, ...lista];
  }

  List<CitaMedica> _upsertOrRemoveCitaEnAgenda(
    List<CitaMedica> lista,
    CitaMedica cita,
  ) {
    final index = lista.indexWhere((item) => item.id == cita.id);
    final include = _shouldIncludeInAgenda(cita);

    if (!include) {
      if (index < 0) return lista;
      final updated = [...lista]..removeAt(index);
      return updated;
    }

    if (index >= 0) {
      final updated = [...lista];
      updated[index] = cita;
      return updated;
    }

    return [...lista, cita];
  }

  List<CitaMedica> _actualizarCitaConFiltro(
    List<CitaMedica> lista,
    String id,
    CitaMedica Function(CitaMedica) updater,
    bool Function(CitaMedica cita) shouldInclude,
  ) {
    final index = lista.indexWhere((item) => item.id == id);
    if (index < 0) return lista;

    final updatedCita = updater(lista[index]);
    final include = shouldInclude(updatedCita);
    final updated = [...lista];

    if (!include) {
      updated.removeAt(index);
      return updated;
    }

    updated[index] = updatedCita;
    return updated;
  }

  List<CitaMedica> _actualizarAgendaConFiltro(
    List<CitaMedica> lista,
    String id,
    CitaMedica Function(CitaMedica) updater,
  ) {
    final index = lista.indexWhere((item) => item.id == id);
    if (index < 0) return lista;

    final updatedCita = updater(lista[index]);
    final include = _shouldIncludeInAgenda(updatedCita);
    final updated = [...lista];

    if (!include) {
      updated.removeAt(index);
      return updated;
    }

    updated[index] = updatedCita;
    return updated;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  List<CitaMedica> _obtenerCitasDelDiaParaDefault(DateTime baseDay) {
    final key = DateTime(baseDay.year, baseDay.month, baseDay.day);
    final acumuladas = <String, CitaMedica>{};

    void agregar(List<CitaMedica> origen) {
      for (final cita in origen) {
        final inicio = cita.fechaInicio;
        if (inicio == null) continue;
        final citaKey = DateTime(inicio.year, inicio.month, inicio.day);
        if (citaKey != key) continue;
        acumuladas[cita.id] = cita;
      }
    }

    agregar(_citasSeleccionadas);
    agregar(_citasAgenda);
    agregar(_citasCalendario);

    final citas = acumuladas.values.toList();
    citas.sort((a, b) {
      final aFecha = a.fechaInicio;
      final bFecha = b.fechaInicio;
      if (aFecha == null && bFecha == null) return 0;
      if (aFecha == null) return -1;
      if (bFecha == null) return 1;
      return aFecha.compareTo(bFecha);
    });
    return citas;
  }

  DateTime _resolveDefaultStartTime(DateTime baseDay) {
    final citasDelDia = _obtenerCitasDelDiaParaDefault(baseDay);
    DateTime? ultimaHora;
    for (final cita in citasDelDia) {
      final fecha = cita.fechaFin ?? cita.fechaInicio;
      if (fecha == null) continue;
      if (ultimaHora == null || fecha.isAfter(ultimaHora)) {
        ultimaHora = fecha;
      }
    }
    if (ultimaHora != null) {
      return DateTime(
        baseDay.year,
        baseDay.month,
        baseDay.day,
        ultimaHora.hour,
        ultimaHora.minute,
      );
    }
    return DateTime(baseDay.year, baseDay.month, baseDay.day, 8, 0);
  }

  void _toggleFilters() {
    _abrirFiltrosModal();
  }

  _DateRange _resolveCalendarRange() {
    final focusedDay = _agendaFocusedDay;
    if (_agendaCalendarFormat == CalendarFormat.week) {
      final start = focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
      final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
      return _DateRange(start: start, end: end);
    }
    final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0, 23, 59);
    return _DateRange(start: firstDay, end: lastDay);
  }

  void _toggleAgendaCalendarCollapsed() {
    setState(() => _agendaCalendarCollapsed = !_agendaCalendarCollapsed);
  }

  Future<void> _refreshAgenda() async {
    await Future.wait<void>([
      _cargarCitasAgendaSemana(),
      _cargarCitasAgendaDay(day: _agendaDay),
    ]);
  }


  Future<void> _abrirFiltrosModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CitasFiltrosModalWidget(
          filtersScrollController: _filtersScrollController,
          buscarController: _buscarController,
          onBuscarChanged: (value) => setState(() => _buscarTexto = value),
          estadoController: _estadoFiltroController,
          onTapEstado: _abrirSelectorEstadoFiltro,
          mostrarFiltroMedico: widget.mostrarFiltroMedico,
          personalAsignadoController: _medicoFiltroController,
          personalAsignadoIdSeleccionado: _medicoFiltro,
          bloquearFiltroPersonalAsignado: _bloquearFiltroMedicoPorSoloMisCitas,
          etiquetaPersonalAsignadoBloqueado: _nombreMedicoActual,
          onTapPersonalAsignado: _abrirSelectorMedicoFiltro,
          onClearPersonalAsignado: () {
            setState(() {
              _medicoFiltro = null;
              _medicoFiltroNombre = null;
              _medicoFiltroController.clear();
            });
          },
          lugarController: _lugarFiltroController,
          lugarIdSeleccionado: _lugarFiltro,
          onTapLugar: _abrirSelectorLugarFiltro,
          onClearLugar: () {
            setState(() {
              _lugarFiltro = null;
              _lugarFiltroNombre = null;
              _lugarFiltroController.clear();
            });
          },
          onLimpiar: _limpiarFiltros,
          onAplicar: () {
            _aplicarFiltros();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _abrirSelectorMedicoFiltro() async {
    final seleccionado = await showModalBottomSheet<PersonalMedico>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CitasMedicoSelectorModalWidget(
          cargarMedicos: _service.obtenerPersonalMedico,
        );
      },
    );

    if (!mounted || seleccionado == null) return;
    setState(() {
      _medicoFiltro = seleccionado.id;
      _medicoFiltroNombre = seleccionado.nombreCompleto;
      _medicoFiltroController.text = seleccionado.nombreCompleto;
    });
  }

  Future<void> _abrirSelectorLugarFiltro() async {
    final seleccionado = await showModalBottomSheet<Lugar>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CitasLugarSelectorModalWidget(
          cargarLugares: _service.obtenerLugares,
        );
      },
    );

    if (!mounted || seleccionado == null) return;
    setState(() {
      _lugarFiltro = seleccionado.id;
      _lugarFiltroNombre = seleccionado.nombre;
      _lugarFiltroController.text = seleccionado.nombre;
    });
  }


  Future<void> _abrirSelectorEstadoFiltro() async {
    final seleccionado = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final opciones = <String?>[null, ...CitasEstado.valuesAsString];
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: opciones.length,
              itemBuilder: (context, index) {
                final estado = opciones[index];
                final seleccionadoActual = _estadoFiltro == estado;
                return ListTile(
                  title: Text(CitasEstado.labelFromValue(estado)),
                  trailing: seleccionadoActual
                      ? Icon(Icons.check_rounded, color: _theme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, estado),
                );
              },
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _estadoFiltro = seleccionado;
      _estadoFiltroController.text = CitasEstado.labelFromValue(seleccionado);
    });
  }

  void _aplicarFiltrosTrasCambiosRapidos() {
    _aplicarFiltros();
  }

  void _limpiarFiltroBuscar() {
    setState(() {
      _buscarTexto = '';
      _buscarController.clear();
    });
    _aplicarFiltrosTrasCambiosRapidos();
  }

  void _limpiarFiltroEstado() {
    setState(() {
      _estadoFiltro = null;
      _estadoFiltroController.text = CitasEstado.labelFromValue(null);
    });
    _aplicarFiltrosTrasCambiosRapidos();
  }

  void _limpiarFiltroMedico() {
    setState(() {
      _medicoFiltro = null;
      _medicoFiltroNombre = null;
      _medicoFiltroController.clear();
    });
    _aplicarFiltrosTrasCambiosRapidos();
  }

  void _limpiarFiltroLugar() {
    setState(() {
      _lugarFiltro = null;
      _lugarFiltroNombre = null;
      _lugarFiltroController.clear();
    });
    _aplicarFiltrosTrasCambiosRapidos();
  }

  void _limpiarFiltros() {
    setState(() {
      _estadoFiltro = null;
      _estadoFiltroController.text = CitasEstado.labelFromValue(null);
      _medicoFiltro = null;
      _medicoFiltroNombre = null;
      _lugarFiltro = null;
      _lugarFiltroNombre = null;
      _buscarTexto = '';
      _buscarController.clear();
      _medicoFiltroController.clear();
      _lugarFiltroController.clear();
      _listPage = 1;
    });
    _cargarCitasAgendaSemana();
    _cargarCitasAgendaDay(day: _agendaDay);
  }

  void _aplicarFiltros() {
    _cargarCitasAgendaSemana();
    _cargarCitasAgendaDay(day: _agendaDay);
  }

  Future<void> _cargarCitasDelDia({DateTime? day}) async {
    final fecha = day ?? _selectedDay;
    if (fecha == null) {
      setState(() {
        _citasSeleccionadas = [];
      });
      return;
    }
    final requestId = ++_dayRequestId;
    final filtros = _buildDayFiltersQuery(fecha);
    final citas = await _service.obtenerCitas(
      filtros: filtros.isNotEmpty ? filtros : null,
    );
    if (!mounted || requestId != _dayRequestId) return;
    setState(() {
      _citasSeleccionadas = citas;
    });
  }

  Future<void> _cargarCitasAgendaDay({DateTime? day}) async {
    final fecha = day ?? _agendaDay;
    final requestId = ++_agendaRequestId;
    setState(() => _agendaLoading = true);
    final filtros = _buildDayFiltersQuery(fecha);
    final citas = await _service.obtenerCitas(
      filtros: filtros.isNotEmpty ? filtros : null,
    );
    if (!mounted || requestId != _agendaRequestId) return;
    setState(() {
      _citasAgenda = citas;
      _agendaLoading = false;
    });
  }

  Future<void> _seleccionarAgendaDay(DateTime day) async {
    final fecha = DateTime(day.year, day.month, day.day);
    if (isSameDay(fecha, _agendaDay)) return;
    setState(() {
      _agendaDay = fecha;
      _agendaFocusedDay = fecha;
      _selectedDay = fecha;
      _focusedDay = fecha;
    });
    await _cargarCitasAgendaDay(day: _agendaDay);
  }

  Widget build(BuildContext context) {
    final isCompactHeader = MediaQuery.sizeOf(context).width < 980;

    return TemplatePage(
      showEnvironmentBanner: false,
      cargando: _loading,
      page: ScaffoldMessenger(
        key: citasMessenger,
        child: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
            titulo: widget.titulo,
            subtitulo: widget.soloMisCitas
                ? 'Agenda personal en tiempo real'
                : 'Supervisa, crea y edita citas médicas en vivo',
            isCompact: isCompactHeader,
            actions: [
              if (!widget.soloMisCitas)
                IconButton(
                  onPressed: () async {
                    final nuevoValor = !_soloCitasAsignadas;
                    setState(() {
                      _soloCitasAsignadas = nuevoValor;
                      if (_soloCitasAsignadas) {
                        _medicoFiltro = null;
                        _medicoFiltroNombre = null;
                        _medicoFiltroController.clear();
                      }
                    });
                    await PreferencesService.instance.setBool(
                      _soloMisCitasPreferenceKey,
                      nuevoValor,
                    );
                    _aplicarFiltros();
                  },
                  tooltip: _soloCitasAsignadas
                      ? 'Mostrando citas asignadas a ti'
                      : 'Mostrando todas las citas',
                  icon: Icon(
                    _soloCitasAsignadas
                        ? Icons.person_rounded
                        : Icons.groups_rounded,
                    color: _theme.white,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    side: BorderSide(
                      color: _theme.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              IconButton(
                onPressed: _toggleFilters,
                icon: Icon(Icons.filter_list_rounded, color: _theme.white),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  side: BorderSide(color: _theme.white.withValues(alpha: 0.35)),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 980;
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CitasModoMisCitasBanner(
                          visible: _usarSoloMisCitas,
                          nombreMedicoActual: _nombreMedicoActual,
                        ),
                        CitasActiveFiltersRibbon(
                          theme: _theme,
                          buscarTexto: _buscarTexto,
                          estadoFiltro: _estadoFiltro == null
                              ? null
                              : CitasEstado.labelFromValue(_estadoFiltro),
                          medicoFiltroNombre: _medicoFiltroNombre,
                          lugarFiltroNombre: _lugarFiltroNombre,
                          onClearBuscar: _limpiarFiltroBuscar,
                          onClearEstado: _limpiarFiltroEstado,
                          onClearMedico: _limpiarFiltroMedico,
                          onClearLugar: _limpiarFiltroLugar,
                          onClearAll: _limpiarFiltros,
                        ),
                        Expanded(
                          child: CitasAgendaSection(
                            citas: _filtrarCitasLocal(_citasAgenda),
                            isCompact: isCompact,
                            theme: _theme,
                            dateFormat: _dateFormat,
                            agendaDay: _agendaDay,
                            agendaFocusedDay: _agendaFocusedDay,
                            agendaCalendarFormat: _agendaCalendarFormat,
                            agendaCalendarCollapsed: _agendaCalendarCollapsed,
                            citasAgendaPorDia: _cantidadCitasCalendarioPorDia,
                            onAgendaDaySelected: (selectedDay, focusedDay) {
                              setState(() => _agendaFocusedDay = focusedDay);
                              _seleccionarAgendaDay(selectedDay);
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _agendaFocusedDay = focusedDay;
                                _focusedDay = focusedDay;
                              });
                              _cargarCitasAgendaSemana();
                            },
                            onAgendaFormatChanged: (format) {
                              if (_agendaCalendarFormat != format) {
                                setState(() => _agendaCalendarFormat = format);
                                _cargarCitasAgendaSemana();
                              }
                            },
                            onToggleDailyInfoRibbon:
                                _toggleAgendaCalendarCollapsed,
                            isLoading: _agendaLoading,
                            isCalendarLoading: _agendaCalendarLoading,
                            scrollController: _agendaScrollController,
                            colorEstado: (estado) =>
                                CitasUtils.colorEstado(estado, _theme),
                            formatoHoraAgenda: _formatoHoraAgenda,
                            formatoHorarioCita: _formatoHorarioCita,
                            tituloCita: _tituloCita,
                            nombrePaciente: _nombrePaciente,
                            nombreMedico: _nombreMedico,
                            iconoTipoCita: _iconoTipoCita,
                            onTapCita: (cita) => _abrirCitaSegunEstado(cita),
                            onTapHora: (hour) {
                              final fechaBase = DateTime(
                                _agendaDay.year,
                                _agendaDay.month,
                                _agendaDay.day,
                                hour,
                              );
                              _abrirFormulario(fechaBase: fechaBase);
                            },
                            onRefresh: _refreshAgenda,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: FloatingActionButton(
                      onPressed: () =>
                          _abrirFormulario(fechaBase: _selectedDay),
                      backgroundColor: _theme.primary,
                      child: Icon(Icons.add, color: _theme.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatoHoraAgenda(DateTime? inicio, int hour) {
    if (inicio == null) return '${hour.toString().padLeft(2, '0')}:00';
    if (inicio.minute == 0) return '${hour.toString().padLeft(2, '0')}:00';
    return _timeFormat.format(inicio);
  }

  String _formatoFechaCita(DateTime? fecha) {
    if (fecha == null) return '--';
    return _dateFormat.format(fecha);
  }

  String _formatoHorarioCita(DateTime? inicio, DateTime? fin) {
    if (inicio == null && fin == null) return '--';
    if (inicio != null && fin != null) {
      return '${_timeFormat.format(inicio)} - ${_timeFormat.format(fin)}';
    }
    final referencia = inicio ?? fin;
    if (referencia == null) return '--';
    return _timeFormat.format(referencia);
  }

  String _nombreMedico(CitaMedica cita) {
    return (cita.medicoNombre ?? '').trim();
  }

  String _nombrePaciente(CitaMedica cita) {
    return (cita.pacienteNombre ?? '').trim();
  }

  String _resolveAvatarUrl(String? urlFoto) {
    final trimmed = (urlFoto ?? '').trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http')) return trimmed;
    return '${Constantes.apiUrl}$trimmed';
  }

  String _inicialesPersonal(CitaMedica cita) {
    final partes = [cita.personalNombre ?? '']
        .join(' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'PS';
    return partes.take(2).map((p) => p[0]).join().toUpperCase();
  }

  Future<void> _copiarDato(String valor) async {
    await Clipboard.setData(ClipboardData(text: valor));
  }

  String _formatearGenero(String? genero) {
    final value = (genero ?? '').trim().toUpperCase();
    switch (value) {
      case 'M':
      case 'MASCULINO':
        return 'Masculino';
      case 'F':
      case 'FEMENINO':
        return 'Femenino';
      case 'O':
      case 'OTRO':
        return 'Otro';
      default:
        return (genero ?? '').trim();
    }
  }

  String _formatearFechaPaciente(String? fechaRaw) {
    final value = (fechaRaw ?? '').trim();
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return _dateFormat.format(parsed.toLocal());
  }

  String _calcularEdadPaciente(String? fechaRaw) {
    final value = (fechaRaw ?? '').trim();
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '';
    final nacimiento = parsed.toLocal();
    final hoy = DateTime.now();
    var edad = hoy.year - nacimiento.year;
    final aunNoCumple =
        (hoy.month < nacimiento.month) ||
        (hoy.month == nacimiento.month && hoy.day < nacimiento.day);
    if (aunNoCumple) edad -= 1;
    if (edad < 0) return '';
    return '$edad años';
  }

  String _etiquetaPrestacion(String? tipo) {
    final tipoNormalizado = (tipo ?? '').trim().toUpperCase();
    return tipoNormalizado == 'CONSULTA' ? 'Consulta' : 'Estudio';
  }

  String _tituloCita(CitaMedica cita) {
    final estudio = (cita.servicioNombre ?? '').trim();
    if (estudio.isNotEmpty) return estudio;
    final tipo = (cita.tipoCita ?? '').trim().toUpperCase();
    if (tipo == 'CONSULTA') return 'Consulta';
    if (tipo == 'ESTUDIO') return 'Servicio';
    if (tipo.isNotEmpty) return cita.tipoCita!.trim();
    return 'Cita médica';
  }

  IconData _iconoTipoCita(CitaMedica cita) {
    final tipo = (cita.tipoCita ?? '').trim().toUpperCase();
    if (tipo == 'ESTUDIO' || (cita.servicioNombre ?? '').trim().isNotEmpty) {
      return PhosphorIconsRegular.testTube;
    }
    if (tipo == 'CONSULTA') {
      return PhosphorIconsRegular.stethoscope;
    }
    return PhosphorIconsRegular.calendarCheck;
  }

  bool _puedeEditarCita(CitaMedica cita) => CitasUtils.puedeEditarCita(cita);

  Future<bool> _confirmarAccionSimple({
    required String titulo,
    required String mensaje,
    required String accion,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(accion),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<DateTime?> _seleccionarFechaHoraReprogramacion(DateTime? base) async {
    final now = DateTime.now();
    final initial = base ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (pickedDate == null) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return null;
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _cancelarCitaConConfirmacion(CitaMedica cita) async {
    final confirmar = await _confirmarAccionSimple(
      titulo: 'Cancelar cita',
      mensaje: '¿Confirmas que deseas cancelar esta cita?',
      accion: 'Sí, cancelar',
    );
    if (!confirmar) return;
    final ok = await _handleResponseError(
      await _service.cancelarCita(cita.id),
      'No se pudo cancelar la cita.',
    );
    if (!ok) return;
    if (mounted) {
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) await _cargarCitasListado();
    }
  }

  Future<void> _reprogramarCitaConConfirmacion(CitaMedica cita) async {
    final nuevaFecha = await _seleccionarFechaHoraReprogramacion(
      cita.fechaInicio,
    );
    if (nuevaFecha == null) return;
    final confirmar = await _confirmarAccionSimple(
      titulo: 'Reprogramar cita',
      mensaje:
          '¿Confirmas reprogramar la cita para ${_dateTimeFormat.format(nuevaFecha)}?',
      accion: 'Sí, reprogramar',
    );
    if (!confirmar) return;
    final ok = await _handleResponseError(
      await _service.reprogramarCita(cita.id, {
        'fechaInicio': nuevaFecha.toUtc().toIso8601String(),
        'tipoCita': cita.tipoCita,
        if ((cita.servicioId ?? '').trim().isNotEmpty)
          'idServicio': cita.servicioId,
      }),
      'No se pudo reprogramar la cita.',
    );
    if (!ok) return;
    if (mounted) {
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) await _cargarCitasListado();
    }
  }

  bool _citaYaIniciada(CitaMedica cita) {
    final fechaInicio = cita.fechaInicio;
    if (fechaInicio == null) return false;
    return !DateTime.now().isBefore(fechaInicio);
  }

  Future<void> _completarCitaConConfirmacion(CitaMedica cita) async {
    final confirmar = await _confirmarAccionSimple(
      titulo: 'Completar cita',
      mensaje: '¿Confirmas marcar esta cita como completada?',
      accion: 'Sí, completar',
    );
    if (!confirmar) return;
    final ok = await _handleResponseError(
      await _service.completarCita(cita.id),
      'No se pudo completar la cita.',
    );
    if (!ok) return;
    if (mounted) {
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) await _cargarCitasListado();
    }
  }

  Future<void> _marcarNoAsistioCitaConConfirmacion(CitaMedica cita) async {
    final confirmar = await _confirmarAccionSimple(
      titulo: 'Marcar no asistió',
      mensaje: '¿Confirmas marcar esta cita como no asistió?',
      accion: 'Sí, marcar',
    );
    if (!confirmar) return;
    final ok = await _handleResponseError(
      await _service.marcarNoAsistioCita(cita.id),
      'No se pudo marcar la cita como no asistió.',
    );
    if (!ok) return;
    if (mounted) {
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) await _cargarCitasListado();
    }
  }

  Future<void> _eliminarBorradorConConfirmacion(CitaMedica cita) async {
    final ok = await _eliminarBorradorEditable(cita);
    if (!ok || !mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> _eliminarBorradorEditable(CitaMedica cita) async {
    final confirmar = await _confirmarAccionSimple(
      titulo: 'Eliminar borrador',
      mensaje: '¿Confirmas eliminar este borrador de cita?',
      accion: 'Sí, eliminar',
    );
    if (!confirmar) return false;
    final ok = await _handleResponseError(
      await _service.eliminarCitaBorrador(cita.id),
      'No se pudo eliminar el borrador.',
    );
    if (!ok) return false;
    if (mounted) {
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) await _cargarCitasListado();
    }
    return true;
  }

  Future<String?> _solicitarMotivoRechazo() async {
    var motivo = '';
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Motivo de rechazo'),
        content: TextFormField(
          initialValue: motivo,
          maxLines: 3,
          maxLength: 255,
          decoration: const InputDecoration(labelText: 'Motivo'),
          onChanged: (value) => motivo = value,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final motivoNormalizado = motivo.trim();
              if (motivoNormalizado.isEmpty) {
                return;
              }
              FocusScope.of(dialogContext).unfocus();
              Navigator.of(
                dialogContext,
                rootNavigator: true,
              ).pop(motivoNormalizado);
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _solicitarMotivoRechazoYEnviar(CitaMedica cita) async {
    var motivo = '';
    var enviando = false;
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: const Text('Motivo de rechazo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: motivo,
                enabled: !enviando,
                maxLines: 3,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'Motivo'),
                onChanged: (value) => motivo = value,
              ),
              if (enviando) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: enviando
                  ? null
                  : () => Navigator.of(
                      dialogContext,
                      rootNavigator: true,
                    ).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: enviando
                  ? null
                  : () async {
                      FocusScope.of(dialogContext).unfocus();
                      final motivoNormalizado = motivo.trim();
                      if (motivoNormalizado.isEmpty) {
                        await showErrorDialog(
                          context,
                          'Debes ingresar un motivo de rechazo.',
                        );
                        return;
                      }

                      setStateDialog(() => enviando = true);
                      final ok = await _handleResponseError(
                        await _service.rechazarCita(
                          cita.id,
                          motivoRechazo: motivoNormalizado,
                        ),
                        'No se pudo rechazar la cita.',
                      );
                      if (!dialogContext.mounted) return;
                      if (!ok) {
                        setStateDialog(() => enviando = false);
                        return;
                      }
                      Navigator.of(
                        dialogContext,
                        rootNavigator: true,
                      ).pop(true);
                    },
              child: const Text('Rechazar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _rechazarCitaSolicitadaConConfirmacion(CitaMedica cita) async {
    if (!CitasUtils.puedeGestionarSolicitada(cita, Auth.instance.profile))
      return false;
    final resultado = await _solicitarMotivoRechazoYEnviar(cita);
    if (resultado != true) {
      if (resultado == false && mounted) {
        await _mostrarDetalleCita(cita);
      }
      return false;
    }

    if (mounted) {
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) await _cargarCitasListado();
    }
    return true;
  }

  Future<bool> _confirmarCitaSolicitadaConOpciones(CitaMedica cita) async {
    if (!CitasUtils.puedeGestionarSolicitada(cita, Auth.instance.profile))
      return false;

    final detalleController = TextEditingController(text: cita.detalle);
    DateTime? fechaSeleccionada = cita.fechaInicio;

    final aplicar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          Future<void> seleccionarFechaHora() async {
            final nueva = await _seleccionarFechaHoraReprogramacion(
              fechaSeleccionada,
            );
            if (nueva == null) return;
            setStateDialog(() => fechaSeleccionada = nueva);
          }

          return AlertDialog(
            title: const Text('Confirmar cita solicitada'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: detalleController,
                  minLines: 2,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(labelText: 'Detalle'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: seleccionarFechaHora,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    fechaSeleccionada == null
                        ? 'Ajustar hora'
                        : 'Hora: ${_dateTimeFormat.format(fechaSeleccionada!)}',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );

    if (aplicar != true) return false;

    final body = <String, dynamic>{};
    final detalle = detalleController.text.trim();
    if (detalle != cita.detalle) body['detalle'] = detalle;
    if (fechaSeleccionada != null && fechaSeleccionada != cita.fechaInicio) {
      body['fechaInicio'] = fechaSeleccionada!.toUtc().toIso8601String();
    }

    final ok = await _handleResponseError(
      await _service.confirmarCita(cita.id, body: body),
      'No se pudo confirmar la cita.',
    );
    if (!ok) return false;

    if (mounted) {
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) await _cargarCitasListado();
    }
    return true;
  }

  Future<void> _abrirCitaSegunEstado(CitaMedica cita) async {
    final destino = CitasUtils.resolverDestinoModalCita(
      cita: cita,
      perfil: Auth.instance.profile,
    );

    switch (destino) {
      case CitasModalDestino.formulario:
        await _abrirFormulario(cita: cita);
        return;
      case CitasModalDestino.detalle:
        await _mostrarDetalleCita(cita);
        return;
    }
  }

  Future<void> _mostrarDetalleCita(CitaMedica cita) async {
    final detallePayload = CitasUtils.construirDetalleModalPayload(
      cita: cita,
      theme: _theme,
      titulo: _tituloCita(cita),
      nombrePaciente: _nombrePaciente,
      formatearGenero: _formatearGenero,
      formatearFechaPaciente: _formatearFechaPaciente,
      calcularEdadPaciente: _calcularEdadPaciente,
      etiquetaPrestacion: _etiquetaPrestacion,
      nombreMedico: _nombreMedico,
      resolveAvatarUrl: _resolveAvatarUrl,
      inicialesPersonal: _inicialesPersonal,
      formatoFechaCita: _formatoFechaCita,
      formatoHorarioCita: _formatoHorarioCita,
    );

    final accionesDetalleModal = CitasUtils.construirAccionesDetalleCita(
      cita: cita,
      puedeGestionarSolicitada: (citaItem) =>
          CitasUtils.puedeGestionarSolicitada(citaItem, Auth.instance.profile),
      puedeEditarCita: _puedeEditarCita,
      citaYaIniciada: _citaYaIniciada,
      confirmarCitaSolicitada: _confirmarCitaSolicitadaConOpciones,
      rechazarCitaSolicitada: _rechazarCitaSolicitadaConConfirmacion,
      completarCita: _completarCitaConConfirmacion,
      marcarNoAsistioCita: _marcarNoAsistioCitaConConfirmacion,
      reprogramarCita: _reprogramarCitaConConfirmacion,
      cancelarCita: _cancelarCitaConConfirmacion,
      eliminarBorrador: _eliminarBorradorConConfirmacion,
      abrirFormulario: (citaItem) => _abrirFormulario(cita: citaItem),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CitasDetalleModal.fromPayload(
          cita: cita,
          theme: _theme,
          payload: detallePayload,
          acciones: accionesDetalleModal,
          onClose: () => Navigator.of(context).pop(),
          onVerHistorial: () => _mostrarHistorialCita(cita),
          onCopiarDato: _copiarDato,
        );
      },
    );
  }
}

extension _CitasPageFormularioModalPart on _CitasPageState {
  Future<void> _abrirFormulario({CitaMedica? cita, DateTime? fechaBase}) async {
    await abrirCitasFormularioModal(
      context: context,
      theme: _theme,
      service: _service,
      dateFormat: _dateFormat,
      timeFormat: _timeFormat,
      messengerKey: citasMessenger,
      selectedDay: _selectedDay,
      currentTabIndex: _currentTabIndex,
      resolveDefaultStartTime: _resolveDefaultStartTime,
      validarRequerido: _validarRequerido,
      calcularEdadPaciente: _calcularEdadPaciente,
      formatearFechaPaciente: _formatearFechaPaciente,
      formatearGenero: _formatearGenero,
      puedeGestionarSolicitada: (citaItem) =>
          CitasUtils.puedeGestionarSolicitada(citaItem, Auth.instance.profile),
      colorEstado: (estado) => CitasUtils.colorEstado(estado, _theme),
      formatearTipoCita: CitasUtils.formatearTipoCita,
      confirmarAccionCita: _confirmarAccionCita,
      confirmarAccionSimple: _confirmarAccionSimple,
      solicitarMotivoRechazo: _solicitarMotivoRechazo,
      handleResponseError: (response, fallback) =>
          _handleResponseError(response, fallback),
      cargarCitasCalendario: _cargarCitasCalendario,
      cargarCitasListado: _cargarCitasListado,
      mostrarHistorialCita: _mostrarHistorialCita,
      eliminarCitaEditable: _eliminarBorradorEditable,
      cita: cita,
      fechaBase: fechaBase,
    );
  }
}

extension _CitasPageHistorialModalPart on _CitasPageState {
  Future<void> _mostrarHistorialCita(CitaMedica cita) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return CitasHistorialModalDialog(
          cita: cita,
          service: _service,
          theme: _theme,
          dateFormat: _dateFormat,
          inicioDia: CitasUtils.inicioDia,
          finDia: CitasUtils.finDia,
          formatoFechaHoraHistorial: (fecha) =>
              CitasUtils.formatoFechaHoraHistorial(fecha, _dateTimeFormat),
          tituloHistorial: CitasUtils.tituloHistorial,
          formatearDetalleCambio: (cambio) =>
              CitasUtils.formatearDetalleCambio(cambio, _dateTimeFormat),
        );
      },
    );
  }
}

class _CitasSocketClient {
  io.Socket? _socket;
  final ValueNotifier<bool> connectionNotifier = ValueNotifier(false);

  final void Function(dynamic data) onCreated;
  final void Function(dynamic data) onActualizada;
  final void Function(dynamic data) onEstadoActualizado;
  final void Function(dynamic data) onReprogramada;
  final void Function(dynamic data) onCancelada;

  _CitasSocketClient({
    required this.onCreated,
    required this.onActualizada,
    required this.onEstadoActualizado,
    required this.onReprogramada,
    required this.onCancelada,
  });

  Future<void> connect() async {
    if (_socket != null) {
      if (_socket!.connected != true) {
        _socket!.connect();
      }
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
      connectionNotifier.value = true;
    });
    _socket!.on('disconnect', (reason) {
      connectionNotifier.value = false;
      Logger.warning('Citas socket disconnected: $reason');
    });
    _socket!.on('connect_error', (error) {
      connectionNotifier.value = false;
      Logger.warning('Citas socket connect_error: $error');
    });
    _socket!.on('error', (error) {
      connectionNotifier.value = false;
      Logger.warning('Citas socket error: $error');
    });

    _socket!.on('citas:created', onCreated);
    _socket!.on('citas:actualizada', onActualizada);
    _socket!.on('citas:estado-actualizado', onEstadoActualizado);
    _socket!.on('citas:reprogramada', onReprogramada);
    _socket!.on('citas:cancelada', onCancelada);

    _socket!.connect();
  }

  Future<void> ensureConnected() async {
    if (_socket == null || _socket!.connected != true) {
      await connect();
    }
  }

  void dispose() {
    if (_socket == null) return;
    _socket?.off('citas:created');
    _socket?.off('citas:actualizada');
    _socket?.off('citas:estado-actualizado');
    _socket?.off('citas:reprogramada');
    _socket?.off('citas:cancelada');
    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('connect_error');
    _socket?.off('error');
    _socket?.disconnect();
    _socket = null;
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}
