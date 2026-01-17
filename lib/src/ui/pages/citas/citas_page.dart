import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/active_filter_chip.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/fecha_selector.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/filtro_fecha.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/info_pill.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:table_calendar/table_calendar.dart';

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

  List<CitaMedica> _citasCalendario = [];
  List<CitaMedica> _citasListado = [];
  List<CitaMedica> _citasSeleccionadas = [];

  bool _loading = false;
  bool _dayLoading = false;
  int _dayRequestId = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  late final TabController _tabController;
  int _currentTabIndex = 0;

  String _buscarTexto = '';
  late final TextEditingController _buscarController;
  late final TextEditingController _medicoFiltroController;
  final ScrollController _filtersScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  String? _estadoFiltro;
  String? _medicoFiltro;
  DateTime? _fechaInicioFiltro;
  DateTime? _fechaFinFiltro;
  bool get _hasActiveFilters =>
      _buscarTexto.trim().isNotEmpty ||
      (_estadoFiltro?.isNotEmpty ?? false) ||
      (_medicoFiltro?.isNotEmpty ?? false) ||
      _fechaInicioFiltro != null ||
      _fechaFinFiltro != null;

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
    _buscarController = TextEditingController();
    _medicoFiltroController = TextEditingController();
    _service = CitasService(context);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _listScrollController.addListener(_handleListScroll);
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
          comentario: data['comentario']?.toString(),
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
          comentario: data['comentario']?.toString(),
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
          comentario: data['comentario']?.toString(),
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
    });
  }

  void _actualizarCitaLocal(
    String id,
    CitaMedica Function(CitaMedica) updater,
  ) {
    setState(() {
      _citasCalendario = _actualizarCitaEnLista(_citasCalendario, id, updater);
      _citasListado = _actualizarCitaEnLista(_citasListado, id, updater);
    });
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
    final now = DateTime.now();
    return DateTime(
      baseDay.year,
      baseDay.month,
      baseDay.day,
      now.hour,
      now.minute,
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
                            child: _buildFiltersFields(isCompact: true),
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
    } else {
      _cargarCitasListado();
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

  Future<DateTime?> _seleccionarFechaHora(DateTime? actual) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return null;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(actual ?? DateTime.now()),
    );
    if (hora == null) return null;

    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
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
    } else {
      _cargarCitasListado(page: 1);
    }
  }

  void _aplicarFiltros() {
    if (_currentTabIndex == 0) {
      _cargarCitasCalendario();
    } else {
      _listPage = 1;
      _listLoadingMore = false;
      if (_listScrollController.hasClients) {
        _listScrollController.jumpTo(0);
      }
      _cargarCitasListado(page: 1);
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

  Future<void> _abrirFormulario({CitaMedica? cita, DateTime? fechaBase}) async {
    final formKey = GlobalKey<FormState>();
    final detalleController = TextEditingController(text: cita?.detalle ?? '');
    final medicoController = TextEditingController(
      text: cita?.medicoId ?? Auth.instance.profile.id ?? '',
    );
    final comentarioController = TextEditingController();
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
        colorHex: '#64748b',
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
    bool especialidadesLoading = false;
    bool estudiosLoading = false;
    bool especialidadesHasMore = true;
    bool estudiosHasMore = true;
    int especialidadesPage = 1;
    int estudiosPage = 1;
    String especialidadesFiltro = '';
    String estudiosFiltro = '';
    Timer? especialidadesDebounce;
    Timer? estudiosDebounce;
    bool inicializado = false;

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

            if (!inicializado) {
              inicializado = true;
              unawaited(cargarEspecialidades(reset: true));
              if (tipoCita == 'ESTUDIO' &&
                  especialidadSeleccionada != null) {
                unawaited(cargarEstudios(reset: true));
              }
            }

            void updateFechaInicio() async {
              final picked = await _seleccionarFechaHora(fechaInicio);
              if (picked != null) {
                setStateDialog(() {
                  fechaInicio = picked;
                });
              }
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
                          'Datos de la cita',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
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
                                labelText: 'Especialidad',
                                hintText: 'Selecciona una especialidad',
                                border: const OutlineInputBorder(),
                                errorText: state.errorText,
                                suffixIcon: const Icon(Icons.expand_more),
                              ),
                              onTap: () async {
                                await abrirSelectorEspecialidad();
                                state.didChange(especialidadSeleccionada);
                              },
                            );
                          },
                        ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: tipoCita,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de cita',
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
                                            ?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
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
                                          labelText: 'Estudio',
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
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                CustomTextInput(
                                  title: 'Detalle',
                                  controller: detalleController,
                                  requiredData: true,
                                  validate: _validarRequerido,
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  title: 'Médico (ID)',
                                  controller: medicoController,
                                  requiredData: true,
                                  validate: _validarRequerido,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FechaSelector(
                                        label: 'Inicio',
                                        value: fechaInicio,
                                        formatter: _dateTimeFormat,
                                        onTap: updateFechaInicio,
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
                                          (estado) => DropdownMenuItem(
                                            value: estado,
                                            child: Text(estado),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setStateDialog(() => estado = value);
                                    },
                                  ),
                                if (cita != null) const SizedBox(height: 12),
                                CustomTextInput(
                                  title: 'Comentario',
                                  controller: comentarioController,
                                  lines: 2,
                                ),
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
    if (result != true) return;

    final detalle = detalleController.text.trim();
    final medicoId = medicoController.text.trim();
    final especialidadId = especialidadSeleccionada?.id ?? '';

    if (cita == null) {
      _socketClient.emitCreate({
        'detalle': detalle,
        'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
        'idMedico': medicoId,
        'idEspecialidad': especialidadId,
        'tipoCita': tipoCita,
        if (tipoCita == 'ESTUDIO' && estudioSeleccionado != null)
          'idEstudio': estudioSeleccionado!.id,
      });
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
        if (comentarioController.text.trim().isNotEmpty)
          'comentario': comentarioController.text.trim(),
      });
    }

    if (estado != null && estado != cita.estado) {
      if (estado == 'CANCELADA') {
        _socketClient.emitCancelar({
          'id': cita.id,
          if (comentarioController.text.trim().isNotEmpty)
            'comentario': comentarioController.text.trim(),
        });
      } else {
        _socketClient.emitEstado({
          'id': cita.id,
          'estado': estado,
          if (comentarioController.text.trim().isNotEmpty)
            'comentario': comentarioController.text.trim(),
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
        return Colors.green.shade600;
      case 'EN_CURSO':
        return Colors.orange.shade600;
      case 'COMPLETADA':
        return Colors.blue.shade600;
      case 'CANCELADA':
      case 'RECHAZADA':
        return Colors.red.shade600;
      case 'NO_ASISTIO':
        return Colors.red.shade400;
      case 'SOLICITADA':
        return Colors.amber.shade700;
      case 'BORRADOR':
        return Colors.grey.shade500;
      default:
        return Colors.grey.shade400;
    }
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
            backgroundColor: Colors.transparent,
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
                          _buildHeader(isCompact: isCompact),
                          _buildActiveFiltersRibbon(),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTabsRow(),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildCalendario(
                                        citasSeleccionadas,
                                        isCompact: isCompact,
                                      ),
                                      _buildListadoTab(citasListadoFiltradas),
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
                        child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildHeader({required bool isCompact}) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isCompact ? double.infinity : 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _theme.primary,
                ),
              ),
              Text(
                widget.soloMisCitas
                    ? 'Agenda personal en tiempo real'
                    : 'Supervisa, crea y edita citas médicas en vivo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (isCompact == false)
          Text('Agenda médica', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildFiltersFields({required bool isCompact}) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        SizedBox(
          width: isCompact ? double.infinity : 180,
          child: CustomTextInput(
            title: 'Buscar',
            controller: _buscarController,
            onChange: (value) {
              setState(() => _buscarTexto = value);
            },
          ),
        ),
        SizedBox(
          width: isCompact ? double.infinity : 160,
          child: DropdownButtonFormField<String?>(
            initialValue: _estadoFiltro,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...CitaEstado.values.map(
                (estado) =>
                    DropdownMenuItem(value: estado, child: Text(estado)),
              ),
            ],
            onChanged: (value) => setState(() => _estadoFiltro = value),
          ),
        ),
        if (widget.mostrarFiltroMedico)
          SizedBox(
            width: isCompact ? double.infinity : 160,
            child: CustomTextInput(
              title: 'Médico ID',
              controller: _medicoFiltroController,
              onChange: (value) {
                setState(() => _medicoFiltro = value);
              },
            ),
          ),
        FiltroFecha(
          label: 'Desde',
          value: _fechaInicioFiltro,
          formatter: _dateFormat,
          onTap: () => _seleccionarFecha(inicio: true),
        ),
        FiltroFecha(
          label: 'Hasta',
          value: _fechaFinFiltro,
          formatter: _dateFormat,
          onTap: () => _seleccionarFecha(inicio: false),
        ),
      ],
    );
  }

  Widget _buildTabsRow() {
    return Row(
      children: [
        Expanded(
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: _theme.primary,
            indicatorColor: _theme.primary,
            tabs: const [
              Tab(text: 'Calendario'),
              Tab(text: 'Listado'),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _toggleFilters,
          icon: const Icon(PhosphorIconsRegular.funnel),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersRibbon() {
    if (!_hasActiveFilters) return const SizedBox.shrink();

    final chips = <Widget>[];
    if (_buscarTexto.trim().isNotEmpty) {
      chips.add(ActiveFilterChip(label: 'Buscar: ${_buscarTexto.trim()}'));
    }
    if (_estadoFiltro?.isNotEmpty ?? false) {
      chips.add(ActiveFilterChip(label: 'Estado: $_estadoFiltro'));
    }
    if (_medicoFiltro?.isNotEmpty ?? false) {
      chips.add(ActiveFilterChip(label: 'Médico: $_medicoFiltro'));
    }
    if (_fechaInicioFiltro != null || _fechaFinFiltro != null) {
      final inicio = _fechaInicioFiltro != null
          ? _dateFormat.format(_fechaInicioFiltro!)
          : '--';
      final fin = _fechaFinFiltro != null
          ? _dateFormat.format(_fechaFinFiltro!)
          : '--';
      chips.add(ActiveFilterChip(label: 'Rango: $inicio → $fin'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.funnel,
                  size: 16,
                  color: _theme.primary,
                ),
                const SizedBox(width: 8),
                Wrap(spacing: 8, children: chips),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendario(
    List<CitaMedica> citasSeleccionadas, {
    required bool isCompact,
  }) {
    final listado = _dayLoading
        ? Center(
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(color: _theme.primary),
            ),
          )
        : _buildListado(
            citasSeleccionadas,
            compact: true,
            onRefresh: isCompact ? null : _refreshCalendario,
            embedInScroll: isCompact,
          );
    final calendario = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar<CitaMedica>(
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            sixWeekMonthsEnforced: true,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mes',
              CalendarFormat.week: 'Semana',
            },
            headerStyle: HeaderStyle(
              titleTextStyle: Theme.of(context).textTheme.titleSmall ??
                  const TextStyle(fontWeight: FontWeight.w600),
              titleCentered: false,
              formatButtonVisible: true,
              formatButtonDecoration: BoxDecoration(
                color: _theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              formatButtonTextStyle: TextStyle(
                color: _theme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
                _cargarCitasCalendario();
              }
            },
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return _citasPorDia[key] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _cargarCitasDelDia(day: selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              if (_currentTabIndex == 0) {
                _cargarCitasCalendario();
              }
            },
            availableGestures: AvailableGestures.all,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: _theme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: _theme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: _theme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) =>
                  DateFormat.E(locale).format(date)[0].toUpperCase(),
              weekdayStyle:
                  TextStyle(color: _theme.primary, fontWeight: FontWeight.w600),
              weekendStyle: const TextStyle(color: Colors.black54),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = DateFormat.E('es_ES')
                    .format(day)
                    .substring(0, 1)
                    .toUpperCase();
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: _theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return RefreshIndicator(
        onRefresh: _refreshCalendario,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              calendario,
              const SizedBox(height: 16),
              listado,
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: calendario),
        const SizedBox(width: 16),
        Expanded(child: listado),
      ],
    );
  }

  Widget _buildListadoTab(List<CitaMedica> citas) {
    return Column(
      children: [
        Expanded(
          child: _buildListado(
            citas,
            controller: _listScrollController,
            onRefresh: _refreshListado,
          ),
        ),
        if (_listLoadingMore) const SizedBox(height: 12),
        if (_listLoadingMore)
          Center(
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(color: _theme.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildListado(
    List<CitaMedica> citas, {
    bool compact = false,
    ScrollController? controller,
    Future<void> Function()? onRefresh,
    bool embedInScroll = false,
  }) {
    if (citas.isEmpty) {
      final emptyState = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.calendarBlank,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay citas registradas',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      );

      if (embedInScroll) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(child: emptyState),
        );
      }

      final emptyList = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(child: emptyState),
        ],
      );

      return onRefresh != null
          ? RefreshIndicator(onRefresh: onRefresh, child: emptyList)
          : Center(child: emptyState);
    }

    final listView = ListView.separated(
      controller: controller,
      physics: embedInScroll
          ? const NeverScrollableScrollPhysics()
          : onRefresh != null
              ? const AlwaysScrollableScrollPhysics()
              : null,
      padding: const EdgeInsets.only(top: 8),
      shrinkWrap: embedInScroll,
      itemCount: citas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cita = citas[index];
        final estadoColor = _colorEstado(cita.estado);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: estadoColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cita.detalle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cita.estado,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  InfoPill(
                    icon: PhosphorIconsRegular.clock,
                    label:
                        '${_formatoFecha(cita.fechaInicio)} - ${_formatoFecha(cita.fechaFin)}',
                  ),
                  InfoPill(
                    icon: PhosphorIconsRegular.user,
                    label: 'Médico: ${cita.medicoId}',
                  ),
                  if ((cita.especialidadNombre ?? cita.especialidadId)
                          ?.isNotEmpty ??
                      false)
                    InfoPill(
                      icon: PhosphorIconsRegular.stethoscope,
                      label:
                          'Especialidad: ${cita.especialidadNombre ?? cita.especialidadId}',
                    ),
                  if (cita.tipoCita?.isNotEmpty ?? false)
                    InfoPill(
                      icon: PhosphorIconsRegular.folderNotch,
                      label: 'Tipo: ${cita.tipoCita}',
                    ),
                  if ((cita.estudioNombre ?? cita.estudioId)?.isNotEmpty ??
                      false)
                    InfoPill(
                      icon: PhosphorIconsRegular.testTube,
                      label:
                          'Estudio: ${cita.estudioNombre ?? cita.estudioId}',
                    ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _abrirFormulario(cita: cita),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );

    if (onRefresh == null) {
      return listView;
    }

    return RefreshIndicator(onRefresh: onRefresh, child: listView);
  }

  String _formatoFecha(DateTime? fecha) {
    if (fecha == null) return '--';
    return _dateTimeFormat.format(fecha);
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
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('connect', (_) => connectionNotifier.value = true);
    _socket!.on('disconnect', (_) => connectionNotifier.value = false);

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
    _socket?.disconnect();
    _socket = null;
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}
