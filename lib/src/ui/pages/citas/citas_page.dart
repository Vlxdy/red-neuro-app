import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:red_neuro_app/src/models/paciente.dart';
import 'package:red_neuro_app/src/models/personal_medico.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_active_filters.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_agenda.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_badges.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_calendario_panel.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_widgets.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_filters_fields.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_header.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_listado.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_tabs_row.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/fecha_selector.dart';
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

class _CitasPageState extends State<CitasPage>
    with SingleTickerProviderStateMixin {
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

  bool _loading = false;
  bool _dayLoading = false;
  bool _agendaLoading = false;
  int _dayRequestId = 0;
  int _agendaRequestId = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late DateTime _agendaDay;
  late DateTime _agendaFocusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  late final TabController _tabController;
  int _currentTabIndex = 0;

  String _buscarTexto = '';
  late final TextEditingController _buscarController;
  late final TextEditingController _medicoFiltroController;
  final ScrollController _filtersScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _agendaScrollController = ScrollController();
  bool _agendaCalendarCollapsed = false;
  String? _estadoFiltro;
  String? _medicoFiltro;
  DateTime? _fechaInicioFiltro;
  DateTime? _fechaFinFiltro;
  int _listPage = 1;
  int _listLimit = 10;
  int _listTotal = 0;
  bool _listLoadingMore = false;
  bool get _listHasNext => _listTotal > 0
      ? (_listPage * _listLimit) < _listTotal
      : _citasListado.length == _listLimit;

  late final _CitasSocketClient _socketClient;

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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _listScrollController.addListener(_handleListScroll);
    _agendaScrollController.addListener(_handleAgendaScroll);
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
    _listScrollController
      ..removeListener(_handleListScroll)
      ..dispose();
    _agendaScrollController
      ..removeListener(_handleAgendaScroll)
      ..dispose();
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    _socketClient.dispose();
    super.dispose();
  }

  Future<void> _cargarInicial() async {
    await _socketClient.connect();
    await _cargarCitasCalendario();
  }

  Future<void> _cargarCitasCalendario() async {
    setState(() => _loading = true);
    final filtros = _buildCalendarFiltersQuery();
    final citas = await _service.obtenerCitas(
      soloMisCitas: widget.soloMisCitas,
      filtros: filtros.isNotEmpty ? filtros : null,
    );

    setState(() {
      _citasCalendario = citas;
      _loading = false;
    });
    await _cargarCitasDelDia();
  }

  Future<void> _cargarCitasAgendaSemana() async {
    final filtros = _buildAgendaWeekFiltersQuery();
    final citas = await _service.obtenerCitas(
      soloMisCitas: widget.soloMisCitas,
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
      soloMisCitas: widget.soloMisCitas,
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
      _listLoadingMore = false;
    });
  }

  Map<String, String> _buildCalendarFiltersQuery() {
    final filtros = _buildBaseFiltersQuery();
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
    if (widget.soloMisCitas) {
      final medicoId = Auth.instance.profile.id ?? '';
      if (medicoId.isNotEmpty && (_medicoFiltro?.isNotEmpty ?? false) == false) {
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
    final message =
        response.message.isNotEmpty ? response.message : fallbackMessage;
    await showErrorDialog(context, message);
    return false;
  }

  void _onSocketCreated(dynamic data) {
    final cita = _parseSocketCita(data);
    if (cita == null) return;
    _upsertCita(cita);
  }

  void _onSocketEstadoActualizado(dynamic data) {
    if (data is Map<String, dynamic>) {
      final id = (data['id'] ?? data['citaId'] ?? '').toString();
      final estado = (data['estado'] ?? '').toString();
      if (id.isEmpty) return;
      _actualizarCitaLocal(
        id,
        (cita) => cita.copyWith(
          estado: estado.isNotEmpty ? estado : cita.estado,
        ),
      );
      return;
    }
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _upsertCita(cita);
    }
  }

  void _onSocketReprogramada(dynamic data) {
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _upsertCita(cita);
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
    }
  }

  void _onSocketCancelada(dynamic data) {
    if (data is Map<String, dynamic>) {
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) return;
      _actualizarCitaLocal(
        id,
        (cita) => cita.copyWith(
          estado: 'CANCELADA',
        ),
      );
      return;
    }
    final cita = _parseSocketCita(data);
    if (cita != null) {
      _upsertCita(cita.copyWith(estado: 'CANCELADA'));
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

  List<CitaMedica> _upsertAgendaList(
    List<CitaMedica> lista,
    CitaMedica cita,
  ) {
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
    if (_currentTabIndex == 1 && _listPage > 1) {
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

  Map<DateTime, List<CitaMedica>> get _citasPorDia {
    final Map<DateTime, List<CitaMedica>> data = {};
    for (final cita in _citasCalendario) {
      final fecha = cita.fechaInicio;
      if (fecha == null) continue;
      final key = DateTime(fecha.year, fecha.month, fecha.day);
      data.putIfAbsent(key, () => []).add(cita);
    }
    return data;
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

  DateTime _resolveDefaultStartTime(DateTime baseDay) {
    final key = DateTime(baseDay.year, baseDay.month, baseDay.day);
    final citasDelDia = _citasPorDia[key] ?? [];
    DateTime? ultimaHora;
    for (final cita in citasDelDia) {
      final fecha = cita.fechaFin ?? cita.fechaInicio;
      if (fecha == null) continue;
      if (ultimaHora == null || fecha.isAfter(ultimaHora)) {
        ultimaHora = fecha;
      }
    }
    if (ultimaHora != null) return ultimaHora;
    return DateTime(
      baseDay.year,
      baseDay.month,
      baseDay.day,
      8,
      0,
    );
  }

  void _toggleFilters() {
    _abrirFiltrosModal();
  }

  Future<void> _abrirFiltrosModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setStateModal) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Filtros',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 320,
                        child: Scrollbar(
                          controller: _filtersScrollController,
                          child: SingleChildScrollView(
                            controller: _filtersScrollController,
                            child: CitasFiltersFields(
                              isCompact: true,
                              buscarController: _buscarController,
                              onBuscarChanged: (value) {
                                setState(() => _buscarTexto = value);
                                setStateModal(() {});
                              },
                              estadoFiltro: _estadoFiltro,
                              onEstadoChanged: (value) {
                                setState(() => _estadoFiltro = value);
                                setStateModal(() {});
                              },
                              mostrarFiltroMedico: widget.mostrarFiltroMedico,
                              medicoController: _medicoFiltroController,
                              onMedicoChanged: (value) {
                                setState(() => _medicoFiltro = value);
                                setStateModal(() {});
                              },
                              fechaInicio: _fechaInicioFiltro,
                              fechaFin: _fechaFinFiltro,
                              formatter: _dateFormat,
                              onTapFechaInicio: () =>
                                  _seleccionarFecha(inicio: true),
                              onTapFechaFin: () =>
                                  _seleccionarFecha(inicio: false),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _limpiarFiltros();
                              setStateModal(() {});
                            },
                            child: const Text('Limpiar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _aplicarFiltros();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.sync),
                            label: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
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

  void _handleTabChange() {
    if (_currentTabIndex == _tabController.index) return;
    setState(() => _currentTabIndex = _tabController.index);
    if (_currentTabIndex == 0) {
      _cargarCitasCalendario();
    } else if (_currentTabIndex == 1) {
      _cargarCitasListado();
    } else {
      _cargarCitasAgendaSemana();
      _cargarCitasAgendaDay(day: _agendaDay);
    }
  }

  void _handleListScroll() {
    if (_currentTabIndex != 1 || _listLoadingMore || !_listHasNext) return;
    if (_listScrollController.position.pixels >=
        _listScrollController.position.maxScrollExtent - 240) {
      setState(() => _listLoadingMore = true);
      _cargarCitasListado(page: _listPage + 1);
    }
  }

  void _handleAgendaScroll() {
    if (_currentTabIndex != 2 || !_agendaScrollController.hasClients) return;
    final position = _agendaScrollController.position;
    final direction = position.userScrollDirection;
    if (direction == ScrollDirection.reverse && !_agendaCalendarCollapsed) {
      setState(() => _agendaCalendarCollapsed = true);
    } else if (_agendaCalendarCollapsed &&
        position.pixels <= position.minScrollExtent + 1) {
      setState(() => _agendaCalendarCollapsed = false);
    }
  }

  Future<void> _refreshCalendario() async {
    await _cargarCitasCalendario();
  }

  Future<void> _refreshListado() async {
    _listPage = 1;
    _listLoadingMore = false;
    if (_listScrollController.hasClients) {
      _listScrollController.jumpTo(0);
    }
    await _cargarCitasListado(page: 1);
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

  void _limpiarFiltros() {
    setState(() {
      _estadoFiltro = null;
      _medicoFiltro = null;
      _fechaInicioFiltro = null;
      _fechaFinFiltro = null;
      _buscarTexto = '';
      _buscarController.clear();
      _medicoFiltroController.clear();
      _listPage = 1;
      _listLoadingMore = false;
    });
    if (_currentTabIndex == 0) {
      _cargarCitasCalendario();
    } else if (_currentTabIndex == 1) {
      _cargarCitasListado(page: 1);
    } else {
      _cargarCitasAgendaDay(day: _agendaDay);
    }
  }

  void _aplicarFiltros() {
    if (_currentTabIndex == 0) {
      _cargarCitasCalendario();
    } else if (_currentTabIndex == 1) {
      _listPage = 1;
      _listLoadingMore = false;
      if (_listScrollController.hasClients) {
        _listScrollController.jumpTo(0);
      }
      _cargarCitasListado(page: 1);
    } else {
      _cargarCitasAgendaDay(day: _agendaDay);
    }
  }

  Future<void> _cargarCitasDelDia({DateTime? day}) async {
    final fecha = day ?? _selectedDay;
    if (fecha == null) {
      setState(() {
        _citasSeleccionadas = [];
        _dayLoading = false;
      });
      return;
    }
    final requestId = ++_dayRequestId;
    setState(() => _dayLoading = true);
    final filtros = _buildDayFiltersQuery(fecha);
    final citas = await _service.obtenerCitas(
      soloMisCitas: widget.soloMisCitas,
      filtros: filtros.isNotEmpty ? filtros : null,
    );
    if (!mounted || requestId != _dayRequestId) return;
    setState(() {
      _citasSeleccionadas = citas;
      _dayLoading = false;
    });
  }

  Future<void> _cargarCitasAgendaDay({DateTime? day}) async {
    final fecha = day ?? _agendaDay;
    final requestId = ++_agendaRequestId;
    setState(() => _agendaLoading = true);
    final filtros = _buildDayFiltersQuery(fecha);
    final citas = await _service.obtenerCitas(
      soloMisCitas: widget.soloMisCitas,
      filtros: filtros.isNotEmpty ? filtros : null,
    );
    if (!mounted || requestId != _agendaRequestId) return;
    setState(() {
      _citasAgenda = citas;
      _agendaLoading = false;
    });
  }

  Future<void> _seleccionarFechaAgenda() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _agendaDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return;
    setState(() {
      _agendaDay = DateTime(fecha.year, fecha.month, fecha.day);
      _agendaFocusedDay = _agendaDay;
    });
    await _cargarCitasAgendaDay(day: _agendaDay);
  }

  Future<void> _seleccionarAgendaDay(DateTime day) async {
    final fecha = DateTime(day.year, day.month, day.day);
    if (isSameDay(fecha, _agendaDay)) return;
    setState(() {
      _agendaDay = fecha;
      _agendaFocusedDay = fecha;
    });
    await _cargarCitasAgendaDay(day: _agendaDay);
  }

  Future<void> _abrirFormulario({CitaMedica? cita, DateTime? fechaBase}) async {
    final formKey = GlobalKey<FormState>();
    final detalleController = TextEditingController(text: cita?.detalle ?? '');
    final medicoController = TextEditingController(
      text: (cita?.medicoNombre ?? '').trim().isNotEmpty
          ? cita!.medicoNombre!
          : cita?.medicoId ?? '',
    );
    String? medicoIdSeleccionado =
        (cita?.medicoId.isNotEmpty ?? false) ? cita?.medicoId : null;
    PersonalMedico? medicoSeleccionado;
    Paciente? pacienteSeleccionado;
    final pacienteFieldKey = GlobalKey<FormFieldState<Paciente>>();
    final pacienteAutocompleteController = TextEditingController(
      text: cita?.pacienteNombre ?? '',
    );
    DateTime? fechaInicio = cita?.fechaInicio;
    final baseSeleccionada = fechaBase ?? _selectedDay;
    if (cita == null && baseSeleccionada != null) {
      fechaInicio ??= _resolveDefaultStartTime(baseSeleccionada);
    }
    String? estado = cita?.estado;
    String tipoCita =
        (cita?.tipoCita?.isNotEmpty ?? false) ? cita!.tipoCita! : 'CONSULTA';
    Especialidad? especialidadSeleccionada;
    Estudio? estudioSeleccionado;
    if (cita?.especialidadId != null && cita!.especialidadId!.isNotEmpty) {
      especialidadSeleccionada = Especialidad(
        id: cita.especialidadId!,
        nombre: cita.especialidadNombre ?? 'Especialidad ${cita.especialidadId}',
        descripcion: null,
        estado: 'ACTIVO',
        colorHex: cita.especialidadColorHex ?? '#64748b',
        estudios: const [],
      );
    }
    if (cita?.estudioId != null && cita!.estudioId!.isNotEmpty) {
      estudioSeleccionado = Estudio(
        id: cita.estudioId!,
        nombre: cita.estudioNombre ?? 'Estudio ${cita.estudioId}',
        descripcion: '',
        duracionMinutos: Constantes.citasDuracionDefectoMinutos,
        estado: 'ACTIVO',
        especialidades: const [],
      );
    }
    final especialidadController = TextEditingController(
      text: especialidadSeleccionada?.nombre ?? '',
    );
    final estudioController = TextEditingController(
      text: estudioSeleccionado?.nombre ?? '',
    );
    final List<Especialidad> especialidadesDisponibles = [];
    final List<Estudio> estudiosDisponibles = [];
    final List<Paciente> pacientesDisponibles = [];
    final List<PersonalMedico> medicosDisponibles = [];
    bool especialidadesLoading = false;
    bool estudiosLoading = false;
    bool pacientesLoading = false;
    bool medicosLoading = false;
    bool especialidadesHasMore = true;
    bool estudiosHasMore = true;
    bool pacientesHasMore = true;
    bool medicosHasMore = true;
    int especialidadesPage = 1;
    int estudiosPage = 1;
    int pacientesPage = 1;
    int medicosPage = 1;
    String especialidadesFiltro = '';
    String estudiosFiltro = '';
    String pacientesFiltro = '';
    String medicosFiltro = '';
    Timer? especialidadesDebounce;
    Timer? estudiosDebounce;
    Timer? pacientesDebounce;
    Timer? medicosDebounce;
    bool inicializado = false;
    if ((cita?.pacienteId ?? '').trim().isNotEmpty) {
      pacienteSeleccionado = Paciente(
        id: cita!.pacienteId!.trim(),
        nombres: (cita.pacienteNombre ?? '').trim(),
        primerApellido: null,
        segundoApellido: null,
        nroDocumento: null,
        fechaNacimiento: null,
        telefono: null,
        genero: null,
        observacion: null,
        estado: 'ACTIVO',
      );
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> cargarEspecialidades({
              bool reset = false,
              void Function()? onUpdated,
            }) async {
              if (especialidadesLoading) return;
              setStateDialog(() => especialidadesLoading = true);
              if (reset) {
                especialidadesPage = 1;
                especialidadesHasMore = true;
                especialidadesDisponibles.clear();
              }
              final result = await _service.obtenerEspecialidades(
                page: especialidadesPage,
                limit: 10,
                filtro: especialidadesFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  especialidadesDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  especialidadesDisponibles.addAll(result.items);
                }
                final total = result.total;
                especialidadesHasMore =
                    especialidadesDisponibles.length < total;
                especialidadesPage += 1;
                especialidadesLoading = false;
              });
              onUpdated?.call();
            }

            Future<void> cargarEstudios({
              bool reset = false,
              void Function()? onUpdated,
            }) async {
              if (estudiosLoading) return;
              final especialidadId = especialidadSeleccionada?.id ?? '';
              if (especialidadId.isEmpty) return;
              setStateDialog(() => estudiosLoading = true);
              if (reset) {
                estudiosPage = 1;
                estudiosHasMore = true;
                estudiosDisponibles.clear();
              }
              final result = await _service.obtenerEstudiosPorEspecialidad(
                especialidadId: especialidadId,
                page: estudiosPage,
                limit: 10,
                filtro: estudiosFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  estudiosDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  estudiosDisponibles.addAll(result.items);
                }
                final total = result.total;
                estudiosHasMore = estudiosDisponibles.length < total;
                estudiosPage += 1;
                estudiosLoading = false;
              });
              onUpdated?.call();
            }

            Future<void> cargarPacientes({
              bool reset = false,
              void Function()? onUpdated,
            }) async {
              if (pacientesLoading) return;
              setStateDialog(() => pacientesLoading = true);
              if (reset) {
                pacientesPage = 1;
                pacientesHasMore = true;
                pacientesDisponibles.clear();
              }
              final result = await _service.obtenerPacientes(
                page: pacientesPage,
                limit: 10,
                filtro: pacientesFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  pacientesDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  pacientesDisponibles.addAll(result.items);
                }
                final total = result.total;
                pacientesHasMore = pacientesDisponibles.length < total;
                pacientesPage += 1;
                pacientesLoading = false;
              });
              onUpdated?.call();
            }

            Future<void> cargarMedicos({
              bool reset = false,
              void Function()? onUpdated,
            }) async {
              if (medicosLoading) return;
              setStateDialog(() => medicosLoading = true);
              if (reset) {
                medicosPage = 1;
                medicosHasMore = true;
                medicosDisponibles.clear();
              }
              final result = await _service.obtenerPersonalMedico(
                page: medicosPage,
                limit: 10,
                filtro: medicosFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  medicosDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  medicosDisponibles.addAll(result.items);
                }
                final total = result.total;
                medicosHasMore = medicosDisponibles.length < total;
                medicosPage += 1;
                medicosLoading = false;
              });
              onUpdated?.call();
            }

            if (!inicializado) {
              inicializado = true;
              unawaited(cargarEspecialidades(reset: true));
              if (tipoCita == 'ESTUDIO' &&
                  especialidadSeleccionada != null) {
                unawaited(cargarEstudios(reset: true));
              }
            }

            void updateFechaInicioFecha() async {
              final base = fechaInicio ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: base,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              final horaActual =
                  TimeOfDay.fromDateTime(fechaInicio ?? base);
              setStateDialog(() {
                fechaInicio = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  horaActual.hour,
                  horaActual.minute,
                );
              });
            }

            void updateFechaInicioHora() async {
              final base = fechaInicio ?? DateTime.now();
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(base),
              );
              if (picked == null) return;
              final fechaActual = fechaInicio ?? base;
              setStateDialog(() {
                fechaInicio = DateTime(
                  fechaActual.year,
                  fechaActual.month,
                  fechaActual.day,
                  picked.hour,
                  picked.minute,
                );
              });
            }

            Future<void> abrirSelectorPaciente() async {
              if (pacientesDisponibles.isEmpty && !pacientesLoading) {
                await cargarPacientes(reset: true);
              }
              final seleccion = await showModalBottomSheet<Paciente>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  final searchController = TextEditingController(
                    text: pacientesFiltro,
                  );
                  return StatefulBuilder(
                    builder: (context, setStateSheet) {
                      Future<void> cargar({
                        required bool reset,
                      }) async {
                        await cargarPacientes(
                          reset: reset,
                          onUpdated: () => setStateSheet(() {}),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona un paciente',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar paciente',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    pacientesFiltro = value;
                                    pacientesDebounce?.cancel();
                                    pacientesDebounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () => cargar(reset: true),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    if (pacientesDisponibles.isEmpty &&
                                        pacientesLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (pacientesDisponibles.isEmpty) {
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: pacientesDisponibles.length +
                                          (pacientesHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                                pacientesDisponibles.length &&
                                            pacientesHasMore) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: pacientesLoading
                                                    ? null
                                                    : () => cargar(
                                                          reset: false,
                                                        ),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label:
                                                    const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option =
                                            pacientesDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombreCompleto),
                                          subtitle: (option.nroDocumento
                                                      ?.isNotEmpty ??
                                                  false)
                                              ? Text(
                                                  'Documento: ${option.nroDocumento}',
                                                )
                                              : null,
                                          onTap: () =>
                                              Navigator.pop(context, option),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
              if (seleccion == null) return;
              setStateDialog(() {
                pacienteSeleccionado = seleccion;
                pacienteAutocompleteController.text = seleccion.nombreCompleto;
              });
              pacienteFieldKey.currentState?.didChange(seleccion);
            }

            Future<void> abrirSelectorMedico() async {
              if (medicosDisponibles.isEmpty && !medicosLoading) {
                await cargarMedicos(reset: true);
              }
              final seleccion = await showModalBottomSheet<PersonalMedico>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  final searchController = TextEditingController(
                    text: medicosFiltro,
                  );
                  return StatefulBuilder(
                    builder: (context, setStateSheet) {
                      Future<void> cargar({
                        required bool reset,
                      }) async {
                        await cargarMedicos(
                          reset: reset,
                          onUpdated: () => setStateSheet(() {}),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona un médico',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar médico',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    medicosFiltro = value;
                                    medicosDebounce?.cancel();
                                    medicosDebounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () => cargar(reset: true),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    if (medicosDisponibles.isEmpty &&
                                        medicosLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (medicosDisponibles.isEmpty) {
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: medicosDisponibles.length +
                                          (medicosHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                                medicosDisponibles.length &&
                                            medicosHasMore) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: medicosLoading
                                                    ? null
                                                    : () => cargar(
                                                          reset: false,
                                                        ),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label:
                                                    const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option = medicosDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombreCompleto),
                                          subtitle: (option.nroDocumento
                                                      ?.isNotEmpty ??
                                                  false)
                                              ? Text(
                                                  'Documento: ${option.nroDocumento}',
                                                )
                                              : null,
                                          onTap: () =>
                                              Navigator.pop(context, option),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
              if (seleccion == null) return;
              setStateDialog(() {
                medicoSeleccionado = seleccion;
                medicoIdSeleccionado = seleccion.id;
                medicoController.text = seleccion.nombreCompleto;
              });
            }

            Future<void> abrirSelectorEspecialidad() async {
              if (especialidadesDisponibles.isEmpty && !especialidadesLoading) {
                await cargarEspecialidades(reset: true);
              }
              final seleccion = await showModalBottomSheet<Especialidad>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  final searchController = TextEditingController(
                    text: especialidadesFiltro,
                  );
                  return StatefulBuilder(
                    builder: (context, setStateSheet) {
                      Future<void> cargar({
                        required bool reset,
                      }) async {
                        await cargarEspecialidades(
                          reset: reset,
                          onUpdated: () => setStateSheet(() {}),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona una especialidad',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar especialidad',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    especialidadesFiltro = value;
                                    especialidadesDebounce?.cancel();
                                    especialidadesDebounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () => cargar(reset: true),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    if (especialidadesDisponibles.isEmpty &&
                                        especialidadesLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (especialidadesDisponibles.isEmpty) {
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          especialidadesDisponibles.length +
                                              (especialidadesHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                                especialidadesDisponibles
                                                    .length &&
                                            especialidadesHasMore) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: especialidadesLoading
                                                    ? null
                                                    : () => cargar(
                                                          reset: false,
                                                        ),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label:
                                                    const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option =
                                            especialidadesDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombre),
                                          subtitle: option.descripcion != null
                                              ? Text(option.descripcion!)
                                              : null,
                                          onTap: () =>
                                              Navigator.pop(context, option),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
              if (seleccion == null) return;
              setStateDialog(() {
                especialidadSeleccionada = seleccion;
                especialidadController.text = seleccion.nombre;
                tipoCita = tipoCita.isNotEmpty ? tipoCita : 'CONSULTA';
                estudioSeleccionado = null;
                estudioController.clear();
                estudiosFiltro = '';
                estudiosDisponibles.clear();
                estudiosHasMore = true;
                estudiosPage = 1;
              });
              if (tipoCita == 'ESTUDIO') {
                unawaited(cargarEstudios(reset: true));
              }
            }

            Future<void> abrirSelectorEstudio() async {
              if (especialidadSeleccionada == null) return;
              if (estudiosDisponibles.isEmpty && !estudiosLoading) {
                await cargarEstudios(reset: true);
              }
              final seleccion = await showModalBottomSheet<Estudio>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  final searchController = TextEditingController(
                    text: estudiosFiltro,
                  );
                  return StatefulBuilder(
                    builder: (context, setStateSheet) {
                      Future<void> cargar({
                        required bool reset,
                      }) async {
                        await cargarEstudios(
                          reset: reset,
                          onUpdated: () => setStateSheet(() {}),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Selecciona un estudio',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar estudio',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    estudiosFiltro = value;
                                    estudiosDebounce?.cancel();
                                    estudiosDebounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () => cargar(reset: true),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    if (estudiosDisponibles.isEmpty &&
                                        estudiosLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (estudiosDisponibles.isEmpty) {
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: estudiosDisponibles.length +
                                          (estudiosHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                                estudiosDisponibles.length &&
                                            estudiosHasMore) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: estudiosLoading
                                                    ? null
                                                    : () => cargar(
                                                          reset: false,
                                                        ),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label:
                                                    const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option = estudiosDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombre),
                                          subtitle: option.descripcion.isNotEmpty
                                              ? Text(option.descripcion)
                                              : null,
                                          onTap: () =>
                                              Navigator.pop(context, option),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
              if (seleccion == null) return;
              setStateDialog(() {
                estudioSeleccionado = seleccion;
                estudioController.text = seleccion.nombre;
              });
            }

            Future<Paciente?> abrirNuevoPaciente() async {
              final formKeyPaciente = GlobalKey<FormState>();
              final nombresController = TextEditingController();
              final primerApellidoController = TextEditingController();
              final segundoApellidoController = TextEditingController();
              final nroDocumentoController = TextEditingController();
              final fechaNacimientoController = TextEditingController();
              final telefonoController = TextEditingController();
              final observacionController = TextEditingController();
              DateTime? fechaNacimiento;
              String? generoSeleccionado;
              bool guardando = false;

              return showDialog<Paciente>(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setStatePaciente) {
                      Future<void> seleccionarFechaNacimiento() async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked == null) return;
                        setStatePaciente(() {
                          fechaNacimiento = picked;
                          fechaNacimientoController.text =
                              DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }

                      Future<void> guardarPaciente() async {
                        if (!formKeyPaciente.currentState!.validate()) return;
                        setStatePaciente(() => guardando = true);
                        final body = <String, dynamic>{
                          'nombres': nombresController.text.trim(),
                          if (primerApellidoController.text.trim().isNotEmpty)
                            'primerApellido':
                                primerApellidoController.text.trim(),
                          if (segundoApellidoController.text.trim().isNotEmpty)
                            'segundoApellido':
                                segundoApellidoController.text.trim(),
                          if (nroDocumentoController.text.trim().isNotEmpty)
                            'nroDocumento': nroDocumentoController.text.trim(),
                          if (fechaNacimiento != null)
                            'fechaNacimiento': DateFormat('yyyy-MM-dd')
                                .format(fechaNacimiento!),
                          if (telefonoController.text.trim().isNotEmpty)
                            'telefono': telefonoController.text.trim(),
                          if (generoSeleccionado?.trim().isNotEmpty ?? false)
                            'genero': generoSeleccionado,
                          if (observacionController.text.trim().isNotEmpty)
                            'observacion': observacionController.text.trim(),
                        };
                        final response = await _service.crearPaciente(body);
                        final ok = await _handleResponseError(
                          response,
                          'No se pudo registrar el paciente.',
                        );
                        if (!ok) {
                          setStatePaciente(() => guardando = false);
                          return;
                        }
                        final raw = response.data['datos'] ??
                            response.data['data'] ??
                            response.data;
                        if (raw is Map<String, dynamic>) {
                          final paciente = Paciente.fromJson(raw);
                          showSnackBar(
                            citasMessenger,
                            'Paciente creado correctamente',
                            state: StatusSnackBar.success,
                            colorText: _theme.white,
                          );
                          Navigator.pop(context, paciente);
                          return;
                        }
                        Navigator.pop(context);
                      }

                      return AlertDialog(
                        title: const Text('Nuevo paciente'),
                        content: SingleChildScrollView(
                          child: Form(
                            key: formKeyPaciente,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: nombresController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombres',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    final result = _validarRequerido(
                                      value,
                                      'Nombres',
                                    );
                                    return result.isEmpty ? null : result;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: primerApellidoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Primer apellido',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: segundoApellidoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Segundo apellido',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: nroDocumentoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Número de documento',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: fechaNacimientoController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Fecha de nacimiento',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.event),
                                      onPressed: seleccionarFechaNacimiento,
                                    ),
                                  ),
                                  onTap: seleccionarFechaNacimiento,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: telefonoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: generoSeleccionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Género',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'F',
                                      child: Text('Femenino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'M',
                                      child: Text('Masculino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'O',
                                      child: Text('Otro'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setStatePaciente(
                                      () => generoSeleccionado = value,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: observacionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Observaciones',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed:
                                guardando ? null : () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: guardando ? null : guardarPaciente,
                            child: guardando
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Guardar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            }

            return Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(cita == null ? 'Nueva cita' : 'Editar cita'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                body: SafeArea(
                  child: Form(
                    key: formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          'Paciente',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          color: _theme.bgCard2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FormField<Paciente>(
                                  key: pacienteFieldKey,
                                  builder: (state) {
                                    return TextFormField(
                                      controller:
                                          pacienteAutocompleteController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Paciente',
                                        hintText: 'Selecciona un paciente',
                                        border: const OutlineInputBorder(),
                                        errorText: state.errorText,
                                        suffixIcon:
                                            pacienteSeleccionado == null
                                                ? const Icon(
                                                    Icons.expand_more,
                                                  )
                                                : IconButton(
                                                    tooltip: 'Quitar',
                                                    icon:
                                                        const Icon(Icons.close),
                                                    onPressed: () {
                                                      setStateDialog(() {
                                                        pacienteSeleccionado =
                                                            null;
                                                        pacienteAutocompleteController
                                                            .clear();
                                                      });
                                                      state.didChange(null);
                                                    },
                                                  ),
                                      ),
                                      onTap: abrirSelectorPaciente,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final nuevo = await abrirNuevoPaciente();
                                    if (nuevo == null) return;
                                    setStateDialog(() {
                                      pacienteSeleccionado = nuevo;
                                      pacienteAutocompleteController.text =
                                          nuevo.nombreCompleto;
                                      pacientesDisponibles.insert(0, nuevo);
                                    });
                                    pacienteFieldKey.currentState
                                        ?.didChange(nuevo);
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Registrar paciente'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Datos de la cita',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          color: _theme.bgCard2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                FormField<Especialidad>(
                                  validator: (_) {
                                    if (especialidadSeleccionada == null) {
                                      return 'Selecciona una especialidad';
                                    }
                                    return null;
                                  },
                                  builder: (state) {
                                    return TextFormField(
                                      controller: especialidadController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Especialidad *',
                                        hintText: 'Selecciona una especialidad',
                                        border: const OutlineInputBorder(),
                                        errorText: state.errorText,
                                        suffixIcon:
                                            const Icon(Icons.expand_more),
                                      ),
                                      onTap: () async {
                                        await abrirSelectorEspecialidad();
                                        state.didChange(
                                          especialidadSeleccionada,
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: tipoCita,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de cita *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'CONSULTA',
                                      child: Text('Consulta'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ESTUDIO',
                                      child: Text('Estudio'),
                                    ),
                                  ],
                                  onChanged: especialidadSeleccionada == null
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          setStateDialog(() {
                                            tipoCita = value;
                                            if (tipoCita != 'ESTUDIO') {
                                              estudioSeleccionado = null;
                                              estudioController?.clear();
                                            } else if (especialidadSeleccionada !=
                                                null) {
                                              estudiosDisponibles.clear();
                                              estudiosHasMore = true;
                                              estudiosPage = 1;
                                              unawaited(
                                                cargarEstudios(reset: true),
                                              );
                                            }
                                          });
                                        },
                                ),
                                if (especialidadSeleccionada == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Selecciona una especialidad para habilitar el tipo de cita.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: _theme.grey),
                                      ),
                                    ),
                                  ),
                                if (tipoCita == 'ESTUDIO') ...[
                                  const SizedBox(height: 16),
                                  FormField<Estudio>(
                                    validator: (_) {
                                      if (tipoCita == 'ESTUDIO' &&
                                          estudioSeleccionado == null) {
                                        return 'Selecciona un estudio';
                                      }
                                      return null;
                                    },
                                    builder: (state) {
                                      return TextFormField(
                                        controller: estudioController,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          labelText: 'Estudio *',
                                          hintText:
                                              'Selecciona un estudio',
                                          border: const OutlineInputBorder(),
                                          errorText: state.errorText,
                                          suffixIcon:
                                              const Icon(Icons.expand_more),
                                        ),
                                        onTap: () async {
                                          await abrirSelectorEstudio();
                                          state.didChange(estudioSeleccionado);
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Detalle y agenda',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          color: _theme.bgCard2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: detalleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Detalle',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 12),
                                FormField<PersonalMedico>(
                                  builder: (state) {
                                    return TextFormField(
                                      controller: medicoController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Médico',
                                        hintText:
                                            'Selecciona un médico (opcional)',
                                        border: const OutlineInputBorder(),
                                        errorText: state.errorText,
                                        suffixIcon:
                                            medicoIdSeleccionado == null
                                                ? const Icon(
                                                    Icons.expand_more,
                                                  )
                                                : IconButton(
                                                    tooltip: 'Quitar',
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: () {
                                                      setStateDialog(() {
                                                        medicoSeleccionado =
                                                            null;
                                                        medicoIdSeleccionado =
                                                            null;
                                                        medicoController
                                                            .clear();
                                                      });
                                                      state.didChange(null);
                                                    },
                                                  ),
                                      ),
                                      onTap: () async {
                                        await abrirSelectorMedico();
                                        state.didChange(medicoSeleccionado);
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FechaSelector(
                                        label: 'Fecha *',
                                        value: fechaInicio,
                                        formatter: _dateFormat,
                                        onTap: updateFechaInicioFecha,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FechaSelector(
                                        label: 'Hora *',
                                        value: fechaInicio,
                                        formatter: _timeFormat,
                                        onTap: updateFechaInicioHora,
                                        icon: Icons.schedule,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (cita != null)
                                  DropdownButtonFormField<String?>(
                                    initialValue: estado,
                                    decoration: const InputDecoration(
                                      labelText: 'Estado',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: CitaEstado.values
                                        .map(
                                      (estadoItem) {
                                        final restringido =
                                            estadoItem == 'CONFIRMADA' ||
                                                estadoItem == 'RECHAZADA';
                                        final habilitado = !restringido ||
                                            _puedeAprobarRechazar(cita) ||
                                            estadoItem == cita.estado;
                                        return DropdownMenuItem(
                                          value: estadoItem,
                                          enabled: habilitado,
                                          child: Text(estadoItem),
                                        );
                                      },
                                    ).toList(),
                                    onChanged: (value) {
                                      setStateDialog(() => estado = value);
                                    },
                                  ),
                                if (cita != null) const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  if (fechaInicio == null) {
                                    showSnackBar(
                                      citasMessenger,
                                      'Selecciona fecha y hora de inicio',
                                      state: StatusSnackBar.error,
                                      colorText: _theme.white,
                                    );
                                    return;
                                  }
                                  if (tipoCita == 'ESTUDIO' &&
                                      estudioSeleccionado == null) {
                                    showSnackBar(
                                      citasMessenger,
                                      'Selecciona un estudio',
                                      state: StatusSnackBar.error,
                                      colorText: _theme.white,
                                    );
                                    return;
                                  }
                                  if (especialidadSeleccionada == null) {
                                    showSnackBar(
                                      citasMessenger,
                                      'Selecciona una especialidad',
                                      state: StatusSnackBar.error,
                                      colorText: _theme.white,
                                    );
                                    return;
                                  }
                                  Navigator.pop(context, true);
                                },
                                child: Text(
                                  cita == null ? 'Crear cita' : 'Guardar cambios',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    especialidadesDebounce?.cancel();
    estudiosDebounce?.cancel();
    pacientesDebounce?.cancel();
    medicosDebounce?.cancel();
    if (result != true) return;

    final detalle = detalleController.text.trim();
    final medicoId = (medicoIdSeleccionado ?? '').trim();
    final pacienteId = (pacienteSeleccionado?.id ?? '').trim();
    final especialidadId = especialidadSeleccionada?.id ?? '';

    if (cita == null) {
      // Endpoint REST: POST /citas (creación de cita).
      final response = await _service.crearCita({
        'detalle': detalle,
        'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
        if (medicoId.isNotEmpty) 'idMedico': medicoId,
        if (pacienteSeleccionado != null) 'idPaciente': pacienteSeleccionado?.id,
        'idEspecialidad': especialidadId,
        'tipoCita': tipoCita,
        if (tipoCita == 'ESTUDIO' && estudioSeleccionado != null)
          'idEstudio': estudioSeleccionado!.id,
      });
      final ok = await _handleResponseError(
        response,
        'No se pudo crear la cita.',
      );
      if (!ok) return;
      showSnackBar(
        citasMessenger,
        'Cita enviada al calendario',
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      await _cargarCitasCalendario();
      if (_currentTabIndex == 1) {
        await _cargarCitasListado(page: 1);
      }
      return;
    }

    final updates = <String, dynamic>{};
    if (detalle != cita.detalle) updates['detalle'] = detalle;
    if (medicoId != cita.medicoId) updates['idMedico'] = medicoId;
    if (pacienteId.isNotEmpty && pacienteId != (cita.pacienteId ?? '')) {
      updates['idPaciente'] = pacienteId;
    }
    if (especialidadId != (cita.especialidadId ?? '')) {
      updates['idEspecialidad'] = especialidadId;
    }
    if (tipoCita != (cita.tipoCita ?? '')) updates['tipoCita'] = tipoCita;
    if (tipoCita == 'ESTUDIO' &&
        estudioSeleccionado?.id != (cita.estudioId ?? '')) {
      updates['idEstudio'] = estudioSeleccionado?.id;
    }

    if (updates.isNotEmpty) {
      final response = await _service.actualizarCita(cita.id, updates);
      final ok = await _handleResponseError(
        response,
        'No se pudo actualizar la cita.',
      );
      if (!ok) return;
    }

    if (fechaInicio != cita.fechaInicio) {
      _socketClient.emitReprogramar({
        'id': cita.id,
        'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
        'tipoCita': tipoCita,
        if (tipoCita == 'ESTUDIO' && estudioSeleccionado != null)
          'idEstudio': estudioSeleccionado!.id,
      });
    }

    if (estado != null && estado != cita.estado) {
      final requierePermiso =
          estado == 'CONFIRMADA' || estado == 'RECHAZADA';
      if (requierePermiso && !_puedeAprobarRechazar(cita)) {
        showSnackBar(
          citasMessenger,
          'Solo el médico asignado o supervisores pueden aprobar o rechazar.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
      if (estado == 'CANCELADA') {
        _socketClient.emitCancelar({
          'id': cita.id,
        });
      } else {
        _socketClient.emitEstado({
          'id': cita.id,
          'estado': estado,
        });
      }
    }

    await _cargarCitasCalendario();
    if (_currentTabIndex == 1) {
      await _cargarCitasListado();
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'CONFIRMADA':
        return _theme.success;
      case 'EN_CURSO':
        return _theme.warning;
      case 'COMPLETADA':
        return _theme.primary;
      case 'CANCELADA':
      case 'RECHAZADA':
        return _theme.error;
      case 'NO_ASISTIO':
        return _theme.error.withValues(alpha: 0.7);
      case 'SOLICITADA':
        return _theme.secondary;
      default:
        return _theme.grey.withValues(alpha: 0.6);
    }
  }

  bool _tieneRol(String rol) {
    final normalized = rol.toUpperCase();
    final perfil = Auth.instance.profile;
    final roles = <String>{};
    if ((perfil.rol ?? '').trim().isNotEmpty) {
      roles.add(perfil.rol!.toUpperCase());
    }
    roles.addAll(
      perfil.roles
          .map((rol) => rol.rol.toUpperCase())
          .where((rol) => rol.trim().isNotEmpty),
    );
    return roles.contains(normalized);
  }

  bool _esMedicoAsignado(CitaMedica cita) {
    final idUsuario = Auth.instance.profile.id ?? '';
    return idUsuario.isNotEmpty && cita.medicoId == idUsuario;
  }

  bool _puedeAprobarRechazar(CitaMedica cita) {
    return _esMedicoAsignado(cita) || _tieneRol('SUPERVISOR');
  }

  String _formatoFechaHoraHistorial(DateTime? fecha) {
    if (fecha == null) return '--';
    return _dateTimeFormat.format(fecha);
  }

  String _tituloHistorial(HistorialCita item) {
    final rol = item.rolEjecutor.trim();
    final tieneCambios = item.detalleCambios.isNotEmpty;
    if (tieneCambios) return 'Actualización de cita';
    if (item.estadoAnterior.trim().isNotEmpty) return 'Cambio de estado';
    if (rol.isEmpty || RegExp(r'^\d+$').hasMatch(rol)) {
      return 'Registro de cita';
    }
    return 'Acción de $rol';
  }

  String _normalizarValorHistorial(String raw) {
    var value = raw.trim();
    if (value.startsWith('{') && value.endsWith('}')) {
      value = value.substring(1, value.length - 1);
    }
    value = value.replaceAll('undefined', '').replaceAll('null', '').trim();
    if (value.isEmpty) return '--';
    if (value == 'true') return 'Sí';
    if (value == 'false') return 'No';
    final isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}');
    if (isoPattern.hasMatch(value)) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return _dateTimeFormat.format(parsed.toLocal());
      }
    }
    return value;
  }

  String _formatearCambioId({
    required String label,
    required String before,
    required String after,
  }) {
    final antes = before == '--' ? '' : before;
    final despues = after == '--' ? '' : after;
    if (antes.isEmpty && despues.isNotEmpty) {
      return '$label asignado';
    }
    if (antes.isNotEmpty && despues.isEmpty) {
      return '$label removido';
    }
    return '$label actualizado';
  }

  String _formatearTipoCita(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'ESTUDIO') return 'Estudio';
    if (normalized == 'CONSULTA') return 'Consulta';
    return value;
  }

  String _formatearDetallePersona(HistorialDetallePersona detalle) {
    final nombre = detalle.nombreCompleto;
    final parts = <String>[
      if (nombre.trim().isNotEmpty) nombre,
      if ((detalle.nroDocumento ?? '').trim().isNotEmpty)
        detalle.nroDocumento!.trim(),
      if (detalle.especialidades.isNotEmpty)
        detalle.especialidades.join(', '),
    ];
    return parts.isEmpty ? '--' : parts.join(' · ');
  }

  String _formatearCambioPersona({
    required String label,
    required String beforeValue,
    required String afterValue,
    HistorialDetallePersona? beforeDetalle,
    HistorialDetallePersona? afterDetalle,
  }) {
    final antes = beforeDetalle != null
        ? _formatearDetallePersona(beforeDetalle)
        : beforeValue;
    final despues = afterDetalle != null
        ? _formatearDetallePersona(afterDetalle)
        : afterValue;
    final antesNormalizado = antes == '--' ? '' : antes;
    final despuesNormalizado = despues == '--' ? '' : despues;

    if (antesNormalizado.isEmpty && despuesNormalizado.isNotEmpty) {
      return '$label asignado: $despuesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isEmpty) {
      return '$label removido: $antesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isNotEmpty) {
      return '$label: $antesNormalizado → $despuesNormalizado';
    }
    return 'Actualización de $label';
  }

  String _formatearDetalleEstudio(HistorialDetalleEstudio detalle) {
    final nombre = detalle.nombre.trim();
    return nombre.isNotEmpty ? nombre : '--';
  }

  String _formatearCambioEstudio({
    required String label,
    required String beforeValue,
    required String afterValue,
    HistorialDetalleEstudio? beforeDetalle,
    HistorialDetalleEstudio? afterDetalle,
  }) {
    final antes = beforeDetalle != null
        ? _formatearDetalleEstudio(beforeDetalle)
        : beforeValue;
    final despues = afterDetalle != null
        ? _formatearDetalleEstudio(afterDetalle)
        : afterValue;
    final antesNormalizado = antes == '--' ? '' : antes;
    final despuesNormalizado = despues == '--' ? '' : despues;

    if (antesNormalizado.isEmpty && despuesNormalizado.isNotEmpty) {
      return '$label asignado: $despuesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isEmpty) {
      return '$label removido: $antesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isNotEmpty) {
      return '$label: $antesNormalizado → $despuesNormalizado';
    }
    return 'Actualización de $label';
  }

  String? _formatearDetalleCambioLegacy(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.contains('field:')) {
      return trimmed.contains('{') ? null : trimmed;
    }

    final fieldMatch = RegExp(r'field:\s*([a-zA-Z0-9_]+)').firstMatch(trimmed);
    final field = fieldMatch?.group(1) ?? '';
    if (field.isEmpty) return null;
    final esIdRelacionado = field.toLowerCase().endsWith('id');

    final labels = <String, String>{
      'fechaInicio': 'Fecha inicio',
      'fechaFin': 'Fecha fin',
      'detalle': 'Detalle',
      'estado': 'Estado',
      'tipoCita': 'Tipo de cita',
      'esEstudio': 'Tipo de cita',
      'idEspecialidad': 'Especialidad',
      'idMedico': 'Médico',
      'idPaciente': 'Paciente',
      'idConsultorio': 'Consultorio',
      'idEstudio': 'Estudio',
    };

    final label = labels[field] ?? field;
    final beforeMatch =
        RegExp(r'before:\s*([^,}]+)').firstMatch(trimmed);
    final afterMatch = RegExp(r'after:\s*([^,}]+)').firstMatch(trimmed);
    final beforeValue =
        beforeMatch != null ? _normalizarValorHistorial(beforeMatch.group(1)!) : '';
    final afterValue =
        afterMatch != null ? _normalizarValorHistorial(afterMatch.group(1)!) : '';

    if (esIdRelacionado) {
      return _formatearCambioId(
        label: label,
        before: beforeValue,
        after: afterValue,
      );
    }
    if (field == 'tipoCita') {
      return '$label: ${_formatearTipoCita(beforeValue)} → ${_formatearTipoCita(afterValue)}';
    }
    if (beforeValue.isNotEmpty && afterValue.isNotEmpty) {
      return '$label: $beforeValue → $afterValue';
    }
    return 'Actualización de $label';
  }

  String? _formatearDetalleCambio(HistorialCambio cambio) {
    if (cambio.rawDetalle != null) {
      return _formatearDetalleCambioLegacy(cambio.rawDetalle!);
    }
    final field = cambio.field.trim();
    if (field.isEmpty) return null;
    final esIdRelacionado = field.toLowerCase().endsWith('id');

    final labels = <String, String>{
      'fechaInicio': 'Fecha inicio',
      'fechaFin': 'Fecha fin',
      'detalle': 'Detalle',
      'estado': 'Estado',
      'tipoCita': 'Tipo de cita',
      'esEstudio': 'Tipo de cita',
      'idEspecialidad': 'Especialidad',
      'idMedico': 'Médico',
      'idPaciente': 'Paciente',
      'idConsultorio': 'Consultorio',
      'idEstudio': 'Estudio',
    };

    final label = labels[field] ?? field;
    final beforeValue = _normalizarValorHistorial(cambio.before ?? '');
    final afterValue = _normalizarValorHistorial(cambio.after ?? '');

    if (field == 'idMedico' || field == 'idPaciente') {
      return _formatearCambioPersona(
        label: label,
        beforeValue: beforeValue,
        afterValue: afterValue,
        beforeDetalle: cambio.beforeDetalle,
        afterDetalle: cambio.afterDetalle,
      );
    }
    if (field == 'idEstudio') {
      return _formatearCambioEstudio(
        label: label,
        beforeValue: beforeValue,
        afterValue: afterValue,
        beforeDetalle: cambio.beforeDetalleEstudio,
        afterDetalle: cambio.afterDetalleEstudio,
      );
    }
    if (esIdRelacionado) {
      return _formatearCambioId(
        label: label,
        before: beforeValue,
        after: afterValue,
      );
    }
    if (field == 'tipoCita') {
      return '$label: ${_formatearTipoCita(beforeValue)} → ${_formatearTipoCita(afterValue)}';
    }
    if (beforeValue.isNotEmpty && afterValue.isNotEmpty) {
      return '$label: $beforeValue → $afterValue';
    }
    return 'Actualización de $label';
  }

  DateTime _inicioDia(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _finDia(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  Future<void> _mostrarHistorialCita(CitaMedica cita) async {
    final rolController = TextEditingController();
    final fechaInicioController = TextEditingController();
    final fechaFinController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    String? estadoAnterior;
    int page = 1;
    const limit = 10;
    int total = 0;
    bool loading = false;
    bool loadingMore = false;
    bool initialized = false;
    List<HistorialCita> historial = [];

    Future<void> cargarHistorial(
      StateSetter setStateDialog, {
      bool reset = false,
    }) async {
      if (loading || loadingMore) return;
      if (reset) {
        page = 1;
        historial = [];
      }
      setStateDialog(() {
        if (page == 1) {
          loading = true;
        } else {
          loadingMore = true;
        }
      });
      final filtros = <String, String>{
        if (estadoAnterior != null && estadoAnterior!.trim().isNotEmpty)
          'estadoAnterior': estadoAnterior!.trim(),
        if (rolController.text.trim().isNotEmpty)
          'rolEjecutor': rolController.text.trim(),
        if (fechaInicio != null)
          'fechaInicio': _inicioDia(fechaInicio!).toUtc().toIso8601String(),
        if (fechaFin != null)
          'fechaFin': _finDia(fechaFin!).toUtc().toIso8601String(),
      };
      final result = await _service.obtenerHistorialCita(
        id: cita.id,
        page: page,
        limit: limit,
        filtros: filtros,
      );
      setStateDialog(() {
        if (page == 1) {
          historial = result.historial;
        } else {
          historial = [...historial, ...result.historial];
        }
        total = result.total;
        loading = false;
        loadingMore = false;
        page = page + 1;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (!initialized) {
              initialized = true;
              unawaited(cargarHistorial(setStateDialog, reset: true));
            }
            final hasMore = historial.length < total;
            return AlertDialog(
              title: const Text('Historial de la cita'),
              content: SizedBox(
                width: 520,
                height: 460,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        'Filtros',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: fechaInicioController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Fecha inicio',
                                  border: OutlineInputBorder(),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: fechaInicio ?? DateTime.now(),
                                  );
                                  if (picked == null) return;
                                  setStateDialog(() {
                                    fechaInicio = picked;
                                    fechaInicioController.text =
                                        _dateFormat.format(picked);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: fechaFinController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Fecha fin',
                                  border: OutlineInputBorder(),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: fechaFin ?? DateTime.now(),
                                  );
                                  if (picked == null) return;
                                  setStateDialog(() {
                                    fechaFin = picked;
                                    fechaFinController.text =
                                        _dateFormat.format(picked);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          value: estadoAnterior,
                          decoration: const InputDecoration(
                            labelText: 'Estado anterior',
                            border: OutlineInputBorder(),
                          ),
                          items: CitaEstado.values
                              .map(
                                (estado) => DropdownMenuItem(
                                  value: estado,
                                  child: Text(estado),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setStateDialog(() => estadoAnterior = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: rolController,
                          decoration: const InputDecoration(
                            labelText: 'Rol ejecutor',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setStateDialog(() {
                                  estadoAnterior = null;
                                  fechaInicio = null;
                                  fechaFin = null;
                                  rolController.clear();
                                  fechaInicioController.clear();
                                  fechaFinController.clear();
                                });
                                unawaited(
                                  cargarHistorial(
                                    setStateDialog,
                                    reset: true,
                                  ),
                                );
                              },
                              child: const Text('Limpiar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                unawaited(
                                  cargarHistorial(
                                    setStateDialog,
                                    reset: true,
                                  ),
                                );
                              },
                              child: const Text('Aplicar filtros'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (loading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (historial.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('No hay historial disponible.'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: historial.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == historial.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: loadingMore
                                      ? const CircularProgressIndicator()
                                      : TextButton(
                                          onPressed: () {
                                            unawaited(
                                              cargarHistorial(setStateDialog),
                                            );
                                          },
                                          child: const Text('Cargar más'),
                                        ),
                                ),
                              );
                            }
                            final item = historial[index];
                            final detalles = <String>[
                              if (item.estadoAnterior.trim().isNotEmpty)
                                'Estado anterior: ${item.estadoAnterior}',
                              if (item.comentario.trim().isNotEmpty)
                                'Comentario: ${item.comentario}',
                            ];
                            final cambiosFormateados = item.detalleCambios
                                .map(_formatearDetalleCambio)
                                .whereType<String>()
                                .toList();
                            detalles.addAll(cambiosFormateados);
                            if (detalles.isEmpty) {
                              detalles.add('Sin detalles adicionales');
                            }
                            return CitasHistorialTimelineItem(
                              fecha: _formatoFechaHoraHistorial(
                                item.fechaCreacion,
                              ),
                              titulo: _tituloHistorial(item),
                              subtitulo: item.ejecutorNombre.trim().isNotEmpty
                                  ? item.ejecutorNombre
                                  : 'Sistema',
                              detalles: detalles,
                              theme: _theme,
                              isLast: index == historial.length - 1,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );

    rolController.dispose();
    fechaInicioController.dispose();
    fechaFinController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citasCalendarioFiltradas = _filtrarCitasLocal(_citasCalendario);
    final citasListadoFiltradas = _filtrarCitasLocal(_citasListado);
    final citasSeleccionadas = _selectedDay != null
        ? _citasSeleccionadas
        : citasCalendarioFiltradas;

    return TemplatePage(
      showEnvironmentBanner: false,
      cargando: _loading,
      page: SafeArea(
        child: ScaffoldMessenger(
          key: citasMessenger,
          child: Scaffold(
            backgroundColor: _theme.transparent,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 980;
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CitasHeader(
                            titulo: widget.titulo,
                            subtitulo: widget.soloMisCitas
                                ? 'Agenda personal en tiempo real'
                                : 'Supervisa, crea y edita citas médicas en vivo',
                            isCompact: isCompact,
                            theme: _theme,
                          ),
                          CitasActiveFiltersRibbon(
                            theme: _theme,
                            buscarTexto: _buscarTexto,
                            estadoFiltro: _estadoFiltro,
                            medicoFiltro: _medicoFiltro,
                            fechaInicioFiltro: _fechaInicioFiltro,
                            fechaFinFiltro: _fechaFinFiltro,
                            formatter: _dateFormat,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CitasTabsRow(
                                  tabController: _tabController,
                                  onToggleFilters: _toggleFilters,
                                  theme: _theme,
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      CitasCalendarioPanel(
                                        theme: _theme,
                                        calendarFormat: _calendarFormat,
                                        focusedDay: _focusedDay,
                                        selectedDay: _selectedDay,
                                        citasPorDia: _citasPorDia,
                                        onFormatChanged: (format) {
                                          if (_calendarFormat != format) {
                                            setState(() {
                                              _calendarFormat = format;
                                            });
                                            _cargarCitasCalendario();
                                          }
                                        },
                                        onDaySelected:
                                            (selectedDay, focusedDay) {
                                          setState(() {
                                            _selectedDay = selectedDay;
                                            _focusedDay = focusedDay;
                                          });
                                          _cargarCitasDelDia(
                                            day: selectedDay,
                                          );
                                        },
                                        onPageChanged: (focusedDay) {
                                          _focusedDay = focusedDay;
                                          if (_currentTabIndex == 0) {
                                            _cargarCitasCalendario();
                                          }
                                        },
                                        isCompact: isCompact,
                                        dayLoading: _dayLoading,
                                        listado: CitasListado(
                                          citas: citasSeleccionadas,
                                          theme: _theme,
                                          controller: null,
                                          onRefresh:
                                              isCompact ? null : _refreshCalendario,
                                          embedInScroll: isCompact,
                                          colorEstado: _colorEstado,
                                          colorEspecialidad: _colorEspecialidad,
                                          formatoFecha: _formatoFechaCita,
                                          formatoHorario: _formatoHorarioCita,
                                          tituloCita: _tituloCita,
                                          iconoTipoCita: _iconoTipoCita,
                                          nombreMedico: _nombreMedico,
                                          nombrePaciente: _nombrePaciente,
                                          onVerDetalle: (cita) =>
                                              () => _mostrarDetalleCita(cita),
                                          onEditar: (cita) =>
                                              () => _abrirFormulario(cita: cita),
                                        ),
                                        onRefresh: _refreshCalendario,
                                      ),
                                      CitasListadoTab(
                                        citas: citasListadoFiltradas,
                                        theme: _theme,
                                        controller: _listScrollController,
                                        onRefresh: _refreshListado,
                                        isLoadingMore: _listLoadingMore,
                                        colorEstado: _colorEstado,
                                        colorEspecialidad: _colorEspecialidad,
                                        formatoFecha: _formatoFechaCita,
                                        formatoHorario: _formatoHorarioCita,
                                        tituloCita: _tituloCita,
                                        iconoTipoCita: _iconoTipoCita,
                                        nombreMedico: _nombreMedico,
                                        nombrePaciente: _nombrePaciente,
                                        onVerDetalle: (cita) =>
                                            () => _mostrarDetalleCita(cita),
                                        onEditar: (cita) =>
                                            () => _abrirFormulario(cita: cita),
                                      ),
                                      CitasAgendaSection(
                                        citas: _filtrarCitasLocal(_citasAgenda),
                                        isCompact: isCompact,
                                        theme: _theme,
                                        dateFormat: _dateFormat,
                                        agendaDay: _agendaDay,
                                        agendaFocusedDay: _agendaFocusedDay,
                                        agendaCalendarCollapsed:
                                            _agendaCalendarCollapsed,
                                        citasAgendaPorDia: _citasAgendaPorDia,
                                        onAgendaDaySelected:
                                            (selectedDay, focusedDay) {
                                          setState(
                                            () => _agendaFocusedDay = focusedDay,
                                          );
                                          _seleccionarAgendaDay(selectedDay);
                                        },
                                        onPageChanged: (focusedDay) {
                                          setState(
                                            () => _agendaFocusedDay = focusedDay,
                                          );
                                          _cargarCitasAgendaSemana();
                                        },
                                        onExpandCalendar: () => setState(
                                          () => _agendaCalendarCollapsed = false,
                                        ),
                                        isLoading: _agendaLoading,
                                        scrollController: _agendaScrollController,
                                        formatoHoraAgenda: _formatoHoraAgenda,
                                        formatoHorarioCita: _formatoHorarioCita,
                                        tituloCita: _tituloCita,
                                        nombreMedico: _nombreMedico,
                                        nombrePaciente: _nombrePaciente,
                                        iconoTipoCita: _iconoTipoCita,
                                        colorEspecialidad: _colorEspecialidad,
                                        colorEstado: _colorEstado,
                                        onTapCita: (cita) =>
                                            () => _mostrarDetalleCita(cita),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  String _formatoHoraAgenda(DateTime? inicio, int hour) {
    if (inicio == null) return '${hour.toString().padLeft(2, '0')}:00';
    if (inicio.minute == 0) return '${hour.toString().padLeft(2, '0')}:00';
    return _timeFormat.format(inicio);
  }

  String _formatoFecha(DateTime? fecha) {
    if (fecha == null) return '--';
    return _dateTimeFormat.format(fecha);
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

  String _tituloCita(CitaMedica cita) {
    final estudio = (cita.estudioNombre ?? '').trim();
    if (estudio.isNotEmpty) return estudio;
    final tipo = (cita.tipoCita ?? '').trim().toUpperCase();
    if (tipo == 'CONSULTA') return 'Consulta';
    if (tipo == 'ESTUDIO') return 'Estudio';
    if (tipo.isNotEmpty) return cita.tipoCita!.trim();
    if ((cita.especialidadNombre ?? '').trim().isNotEmpty) return 'Consulta';
    return 'Cita médica';
  }

  IconData _iconoTipoCita(CitaMedica cita) {
    final tipo = (cita.tipoCita ?? '').trim().toUpperCase();
    if (tipo == 'ESTUDIO' ||
        (cita.estudioNombre ?? '').trim().isNotEmpty) {
      return PhosphorIconsRegular.testTube;
    }
    if (tipo == 'CONSULTA' ||
        (cita.especialidadNombre ?? '').trim().isNotEmpty) {
      return PhosphorIconsRegular.stethoscope;
    }
    return PhosphorIconsRegular.calendarCheck;
  }

  String _subtituloCita(CitaMedica cita) {
    final estudio = (cita.estudioNombre ?? cita.estudioId ?? '').trim();
    final especialidad =
        (cita.especialidadNombre ?? cita.especialidadId ?? '').trim();
    final detalle = cita.detalle.trim();
    final parts = <String>[
      if (estudio.isNotEmpty) estudio,
      if (especialidad.isNotEmpty) especialidad,
      if (detalle.isNotEmpty) detalle,
    ];
    return parts.join(' • ');
  }

  Future<void> _mostrarDetalleCita(CitaMedica cita) async {
    final especialidadNombre =
        (cita.especialidadNombre ?? cita.especialidadId)?.trim();
    final estudioNombre = (cita.estudioNombre ?? cita.estudioId)?.trim();
    final especialidadColor = _colorEspecialidad(cita);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tituloCita(cita)),
              if (_subtituloCita(cita).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _subtituloCita(cita),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _theme.grey,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CitasEstadoBadge(
                    estado: cita.estado,
                    color: _colorEstado(cita.estado),
                  ),
                  if (especialidadNombre?.isNotEmpty ?? false)
                    CitasEspecialidadTag(
                      label: especialidadNombre!,
                      color: especialidadColor,
                    ),
                ],
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CitasDetalleSection(
                  title: 'Horario',
                  theme: _theme,
                  children: [
                    CitasDetalleRow(
                      icon: PhosphorIconsRegular.calendar,
                      label: 'Fecha',
                      value: _formatoFechaCita(cita.fechaInicio),
                      theme: _theme,
                    ),
                    CitasDetalleRow(
                      icon: PhosphorIconsRegular.clock,
                      label: 'Hora',
                      value: _formatoHorarioCita(
                        cita.fechaInicio,
                        cita.fechaFin,
                      ),
                      theme: _theme,
                    ),
                  ],
                ),
                CitasDetalleSection(
                  title: 'Información clínica',
                  theme: _theme,
                  children: [
                    if (_nombrePaciente(cita).isNotEmpty)
                      CitasDetalleRow(
                        icon: PhosphorIconsRegular.userCircle,
                        label: 'Paciente',
                        value: _nombrePaciente(cita),
                        theme: _theme,
                      ),
                    if (_nombreMedico(cita).isNotEmpty)
                      CitasDetalleRow(
                        icon: PhosphorIconsRegular.stethoscope,
                        label: 'Médico',
                        value: _nombreMedico(cita),
                        theme: _theme,
                      ),
                    if (especialidadNombre?.isNotEmpty ?? false)
                      CitasDetalleRow(
                        icon: PhosphorIconsRegular.stethoscope,
                        label: 'Especialidad',
                        value: especialidadNombre!,
                        theme: _theme,
                      ),
                    if (cita.tipoCita?.isNotEmpty ?? false)
                      CitasDetalleRow(
                        icon: PhosphorIconsRegular.folder,
                        label: 'Tipo de cita',
                        value: cita.tipoCita!,
                        theme: _theme,
                      ),
                    if (estudioNombre?.isNotEmpty ?? false)
                      CitasDetalleRow(
                        icon: PhosphorIconsRegular.testTube,
                        label: 'Estudio',
                        value: estudioNombre!,
                        theme: _theme,
                      ),
                  ],
                ),
                if (cita.detalle.trim().isNotEmpty)
                  CitasDetalleSection(
                    title: 'Notas',
                    theme: _theme,
                    children: [
                      CitasDetalleRow(
                        icon: PhosphorIconsRegular.note,
                        label: 'Detalle',
                        value: cita.detalle.trim(),
                        theme: _theme,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _mostrarHistorialCita(cita);
              },
              child: const Text('Ver historial'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

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
