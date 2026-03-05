import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/extensions/colores_extension.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/models/historial_cita.dart';
import 'package:red_neuro_app/src/models/lugar.dart';
import 'package:red_neuro_app/src/models/paciente.dart';
import 'package:red_neuro_app/src/models/personal_medico.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_active_filters.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_agenda.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_badges.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_widgets.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_filters_fields.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_autocomplete_selector_field.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/fecha_selector.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_confirmacion_dialog.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_modo_mis_citas_banner.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

part 'widgets/citas_filtros_modal_part.dart';
part 'widgets/citas_medico_selector_modal_part.dart';
part 'widgets/citas_formulario_modal_part.dart';
part 'widgets/citas_historial_modal_part.dart';
part 'widgets/citas_detalle_modal_part.dart';

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

class _CitasPageState extends State<CitasPage> {
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
  List<CitaMedica> _citasAgendaCalendario = [];
  Map<DateTime, int> _cantidadCitasCalendarioPorDia = {};

  bool _loading = false;
  bool _agendaLoading = false;
  int _dayRequestId = 0;
  int _agendaRequestId = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late DateTime _agendaDay;
  late DateTime _agendaFocusedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.week;
  CalendarFormat _agendaCalendarFormat = CalendarFormat.week;
  final int _currentTabIndex = 0;
  bool _soloCitasAsignadas = false;

  String _buscarTexto = '';
  late final TextEditingController _buscarController;
  late final TextEditingController _medicoFiltroController;
  final ScrollController _filtersScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _agendaScrollController = ScrollController();
  bool _agendaCalendarCollapsed = false;
  String? _estadoFiltro;
  String? _medicoFiltro;
  String? _medicoFiltroNombre;
  DateTime? _fechaInicioFiltro;
  DateTime? _fechaFinFiltro;
  int _listPage = 1;
  int _listLimit = 10;
  int _listTotal = 0;

  bool get _listHasNext => _listTotal > 0
      ? (_listPage * _listLimit) < _listTotal
      : _citasListado.length == _listLimit;
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
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
    _agendaDay = DateTime(now.year, now.month, now.day);
    _agendaFocusedDay = _agendaDay;
    _buscarController = TextEditingController();
    _medicoFiltroController = TextEditingController();
    _service = CitasService(context);
    _socketClient = _CitasSocketClient(
      onCreated: _onSocketCreated,
      onEstadoActualizado: _onSocketEstadoActualizado,
      onReprogramada: _onSocketReprogramada,
      onCancelada: _onSocketCancelada,
    );
    _cargarInicial();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    _medicoFiltroController.dispose();
    _filtersScrollController.dispose();
    _listScrollController.dispose();
    _agendaScrollController.dispose();
    _socketClient.dispose();
    super.dispose();
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
    final filtros = _buildCalendarFiltersQuery();
    final cantidadPorDia = await _service.obtenerCantidadCitasPorDia(
      filtros: filtros,
    );
    if (!mounted) return;
    setState(() {
      _cantidadCitasCalendarioPorDia = cantidadPorDia;
    });
  }

  Future<void> _cargarCitasAgendaSemana() async {
    final filtros = _buildAgendaWeekFiltersQuery();
    final citas = await _service.obtenerCitas(
      soloMisCitas: _usarSoloMisCitas,
      filtros: filtros.isNotEmpty ? filtros : null,
    );
    if (!mounted) return;
    setState(() {
      _citasAgendaCalendario = citas;
    });
  }

  Future<void> _cargarCitasListado({int? page}) async {
    final isLoadMore = (page ?? _listPage) > 1;
    if (!isLoadMore) {
      setState(() => _loading = true);
    }
    final filtros = _buildListFiltersQuery();
    final result = await _service.obtenerCitasPaginadas(
      soloMisCitas: _usarSoloMisCitas,
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
      _listTotal = result.total;
      _loading = false;
    });
  }

  Map<String, String> _buildCalendarFiltersQuery() {
    final filtros = _buildBaseFiltersQuery();
    if (_usarSoloMisCitas) {
      final medicoId = Auth.instance.profile.id ?? '';
      if (medicoId.isNotEmpty &&
          (_medicoFiltro?.isNotEmpty ?? false) == false) {
        filtros['idMedico'] = medicoId;
      }
    }
    final range = _resolveCalendarRange();
    filtros['fechaInicio'] = range.start.toUtc().toIso8601String();
    filtros['fechaFin'] = range.end.toUtc().toIso8601String();
    return filtros;
  }

  Map<String, String> _buildAgendaWeekFiltersQuery() {
    final filtros = _buildBaseFiltersQuery();
    final start = _agendaFocusedDay.subtract(
      Duration(days: _agendaFocusedDay.weekday - 1),
    );
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
    filtros['fechaInicio'] = start.toUtc().toIso8601String();
    filtros['fechaFin'] = end.toUtc().toIso8601String();
    return filtros;
  }

  Map<String, String> _buildListFiltersQuery() {
    final filtros = _buildBaseFiltersQuery();
    if (_usarSoloMisCitas) {
      final medicoId = Auth.instance.profile.id ?? '';
      if (medicoId.isNotEmpty &&
          (_medicoFiltro?.isNotEmpty ?? false) == false) {
        filtros['idMedico'] = medicoId;
      }
    }
    if (_fechaInicioFiltro != null) {
      filtros['fechaInicio'] = _fechaInicioFiltro!.toUtc().toIso8601String();
    }
    if (_fechaFinFiltro != null) {
      filtros['fechaFin'] = _fechaFinFiltro!.toUtc().toIso8601String();
    }
    return filtros;
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
    if (_medicoFiltro != null && _medicoFiltro!.isNotEmpty) {
      filtros['idMedico'] = _medicoFiltro!;
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
    String? especialidadNombre,
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
        especialidadNombre: especialidadNombre,
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
    _upsertCita(cita);
    unawaited(_recargarConteoCitasCalendario());
  }

  void _onSocketEstadoActualizado(dynamic data) {
    if (data is Map<String, dynamic>) {
      final id = (data['id'] ?? data['citaId'] ?? '').toString();
      final estado = (data['estado'] ?? '').toString();
      if (id.isEmpty) return;
      _actualizarCitaLocal(
        id,
        (cita) =>
            cita.copyWith(estado: estado.isNotEmpty ? estado : cita.estado),
      );
      unawaited(_recargarConteoCitasCalendario());
      return;
    }
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _upsertCita(cita);
      unawaited(_recargarConteoCitasCalendario());
    }
  }

  void _onSocketReprogramada(dynamic data) {
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _upsertCita(cita);
      unawaited(_recargarConteoCitasCalendario());
      return;
    }
    if (data is Map<String, dynamic>) {
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) return;
      _actualizarCitaLocal(
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
      _actualizarCitaLocal(id, (cita) => cita.copyWith(estado: 'CANCELADA'));
      unawaited(_recargarConteoCitasCalendario());
      return;
    }
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _upsertCita(cita.copyWith(estado: 'CANCELADA'));
      unawaited(_recargarConteoCitasCalendario());
    }
  }

  CitaMedica? _parseSocketCita(dynamic data) {
    if (data is Map<String, dynamic>) {
      return CitaMedica.fromJson(data);
    }
    return null;
  }

  void _upsertCita(CitaMedica cita) {
    setState(() {
      _citasCalendario = _upsertCitaEnLista(_citasCalendario, cita);
      _citasListado = _upsertCitaEnLista(_citasListado, cita);
      _citasAgenda = _upsertAgendaList(_citasAgenda, cita);
    });
  }

  void _actualizarCitaLocal(
    String id,
    CitaMedica Function(CitaMedica) updater,
  ) {
    setState(() {
      _citasCalendario = _actualizarCitaEnLista(_citasCalendario, id, updater);
      _citasListado = _actualizarCitaEnLista(_citasListado, id, updater);
      _citasAgenda = _actualizarAgendaList(_citasAgenda, id, updater);
    });
  }

  List<CitaMedica> _upsertAgendaList(List<CitaMedica> lista, CitaMedica cita) {
    final fecha = cita.fechaInicio;
    final index = lista.indexWhere((item) => item.id == cita.id);
    final mismaFecha = fecha != null && isSameDay(fecha, _agendaDay);
    if (!mismaFecha) {
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

  List<CitaMedica> _actualizarAgendaList(
    List<CitaMedica> lista,
    String id,
    CitaMedica Function(CitaMedica) updater,
  ) {
    final index = lista.indexWhere((item) => item.id == id);
    if (index < 0) return lista;
    final updated = [...lista];
    updated[index] = updater(lista[index]);
    final fecha = updated[index].fechaInicio;
    if (fecha == null || !isSameDay(fecha, _agendaDay)) {
      updated.removeAt(index);
    }
    return updated;
  }

  List<CitaMedica> _upsertCitaEnLista(List<CitaMedica> lista, CitaMedica cita) {
    final index = lista.indexWhere((item) => item.id == cita.id);
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

  List<CitaMedica> _actualizarCitaEnLista(
    List<CitaMedica> lista,
    String id,
    CitaMedica Function(CitaMedica) updater,
  ) {
    final index = lista.indexWhere((item) => item.id == id);
    if (index < 0) return lista;
    final updated = [...lista];
    updated[index] = updater(lista[index]);
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

  Map<DateTime, List<CitaMedica>> get _citasAgendaPorDia {
    final Map<DateTime, List<CitaMedica>> data = {};
    for (final cita in _citasAgendaCalendario) {
      final fecha = cita.fechaInicio;
      if (fecha == null) continue;
      final key = DateTime(fecha.year, fecha.month, fecha.day);
      data.putIfAbsent(key, () => []).add(cita);
    }
    return data;
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
    agregar(_citasAgendaCalendario);

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
    if (_calendarFormat == CalendarFormat.week) {
      final start = _focusedDay.subtract(
        Duration(days: _focusedDay.weekday - 1),
      );
      final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
      return _DateRange(start: start, end: end);
    }
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
      23,
      59,
    );
    return _DateRange(start: firstDay, end: lastDay);
  }

  void _toggleAgendaCalendarCollapsed() {
    setState(() => _agendaCalendarCollapsed = !_agendaCalendarCollapsed);
  }

  Future<void> _refreshAgenda() async {
    await Future.wait<void>([
      _cargarCitasAgendaSemana(),
      _cargarCitasAgendaDay(day: _agendaDay),
      _recargarConteoCitasCalendario(),
    ]);
  }

  Future<void> _seleccionarFecha({required bool inicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (inicio) {
        _fechaInicioFiltro = picked;
      } else {
        _fechaFinFiltro = picked;
      }
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
    setState(() => _estadoFiltro = null);
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

  void _limpiarFiltroRango() {
    setState(() {
      _fechaInicioFiltro = null;
      _fechaFinFiltro = null;
    });
    _aplicarFiltrosTrasCambiosRapidos();
  }

  void _limpiarFiltros() {
    setState(() {
      _estadoFiltro = null;
      _medicoFiltro = null;
      _medicoFiltroNombre = null;
      _fechaInicioFiltro = null;
      _fechaFinFiltro = null;
      _buscarTexto = '';
      _buscarController.clear();
      _medicoFiltroController.clear();
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
      soloMisCitas: _usarSoloMisCitas,
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
      soloMisCitas: _usarSoloMisCitas,
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
    await _cargarCitasDelDia(day: _selectedDay);
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
                          estadoFiltro: _estadoFiltro,
                          medicoFiltroNombre: _medicoFiltroNombre,
                          fechaInicioFiltro: _fechaInicioFiltro,
                          fechaFinFiltro: _fechaFinFiltro,
                          formatter: _dateFormat,
                          onClearBuscar: _limpiarFiltroBuscar,
                          onClearEstado: _limpiarFiltroEstado,
                          onClearMedico: _limpiarFiltroMedico,
                          onClearRango: _limpiarFiltroRango,
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
                            citasAgendaPorDia: _citasAgendaPorDia,
                            onAgendaDaySelected: (selectedDay, focusedDay) {
                              setState(() => _agendaFocusedDay = focusedDay);
                              _seleccionarAgendaDay(selectedDay);
                            },
                            onPageChanged: (focusedDay) {
                              setState(() => _agendaFocusedDay = focusedDay);
                              _cargarCitasAgendaSemana();
                            },
                            onAgendaFormatChanged: (format) {
                              if (_agendaCalendarFormat != format) {
                                setState(() => _agendaCalendarFormat = format);
                              }
                            },
                            onToggleDailyInfoRibbon:
                                _toggleAgendaCalendarCollapsed,
                            isLoading: _agendaLoading,
                            scrollController: _agendaScrollController,
                            colorEstado: _colorEstado,
                            formatoHoraAgenda: _formatoHoraAgenda,
                            formatoHorarioCita: _formatoHorarioCita,
                            tituloCita: _tituloCita,
                            nombrePaciente: _nombrePaciente,
                            nombreMedico: _nombreMedico,
                            iconoTipoCita: _iconoTipoCita,
                            colorEspecialidad: _colorEspecialidad,
                            onTapCita: (cita) =>
                                () => _abrirCitaSegunEstado(cita),
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

  Color _colorEspecialidad(CitaMedica cita) {
    return HexColor.fromHex(cita.especialidadColorHex ?? '#64748b');
  }

  String _nombreMedico(CitaMedica cita) {
    return (cita.medicoNombre ?? '').trim();
  }

  String _nombrePaciente(CitaMedica cita) {
    return (cita.pacienteNombre ?? '').trim();
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
    if ((cita.especialidadNombre ?? '').trim().isNotEmpty) return 'Consulta';
    return 'Cita médica';
  }

  IconData _iconoTipoCita(CitaMedica cita) {
    final tipo = (cita.tipoCita ?? '').trim().toUpperCase();
    if (tipo == 'ESTUDIO' || (cita.servicioNombre ?? '').trim().isNotEmpty) {
      return PhosphorIconsRegular.testTube;
    }
    if (tipo == 'CONSULTA' ||
        (cita.especialidadNombre ?? '').trim().isNotEmpty) {
      return PhosphorIconsRegular.stethoscope;
    }
    return PhosphorIconsRegular.calendarCheck;
  }

  bool _puedeEditarCita(CitaMedica cita) {
    final estado = cita.estado;
    return estado == 'BORRADOR' || estado == 'RECHAZADA';
  }

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
    final confirmar = await _confirmarAccionSimple(
      titulo: 'Eliminar borrador',
      mensaje: '¿Confirmas eliminar este borrador de cita?',
      accion: 'Sí, eliminar',
    );
    if (!confirmar) return;
    final ok = await _handleResponseError(
      await _service.eliminarCitaBorrador(cita.id),
      'No se pudo eliminar el borrador.',
    );
    if (!ok) return;
    if (mounted) {
      Navigator.of(context).pop();
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) await _cargarCitasListado();
    }
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
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
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
                  : () => Navigator.of(dialogContext, rootNavigator: true).pop(false),
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
                      Navigator.of(dialogContext, rootNavigator: true).pop(true);
                    },
              child: const Text('Rechazar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _rechazarCitaSolicitadaConConfirmacion(CitaMedica cita) async {
    if (!_puedeGestionarSolicitada(cita)) return false;
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
    if (!_puedeGestionarSolicitada(cita)) return false;

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
                  maxLines: 2,
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
    if (cita.estado == 'BORRADOR' || cita.estado == 'RECHAZADA') {
      _abrirFormulario(cita: cita);
      return;
    }
    await _mostrarDetalleCita(cita);
  }

  String? _valorDetalle(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

class _CitaDetalleAccion {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDestructive;
  final bool cierraModal;
  final Future<bool> Function() onTap;

  const _CitaDetalleAccion({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
    this.cierraModal = true,
  });
}

class _CitasSocketClient {
  io.Socket? _socket;
  final ValueNotifier<bool> connectionNotifier = ValueNotifier(false);

  final void Function(dynamic data) onCreated;
  final void Function(dynamic data) onEstadoActualizado;
  final void Function(dynamic data) onReprogramada;
  final void Function(dynamic data) onCancelada;

  _CitasSocketClient({
    required this.onCreated,
    required this.onEstadoActualizado,
    required this.onReprogramada,
    required this.onCancelada,
  });

  Future<void> connect() async {
    if (_socket != null) return;
    final token = await Auth.instance.apiToken;
    _socket = io.io(
      '${Constantes.sockets}/citas',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setReconnectionAttempts(0)
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
    _socket!.on('citas:estado-actualizado', onEstadoActualizado);
    _socket!.on('citas:reprogramada', onReprogramada);
    _socket!.on('citas:cancelada', onCancelada);

    _socket!.connect();
  }

  void emitCreate(Map<String, dynamic> payload) {
    Logger.info('Emit citas:create $payload');
    _socket?.emit('citas:create', payload);
  }

  void emitEstado(Map<String, dynamic> payload) {
    Logger.info('Emit citas:estado $payload');
    _socket?.emit('citas:estado', payload);
  }

  void emitReprogramar(Map<String, dynamic> payload) {
    Logger.info('Emit citas:reprogramar $payload');
    _socket?.emit('citas:reprogramar', payload);
  }

  void emitCancelar(Map<String, dynamic> payload) {
    Logger.info('Emit citas:cancelar $payload');
    _socket?.emit('citas:cancelar', payload);
  }

  void dispose() {
    if (_socket == null) return;
    _socket?.off('citas:created');
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
