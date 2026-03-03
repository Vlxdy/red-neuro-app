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
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/form_stepper/step_form_dialog_layout.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_active_filters.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_agenda.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_badges.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_calendario_panel.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_widgets.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_filters_fields.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_listado.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_autocomplete_selector_field.dart';
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

class _CitasPageState extends State<CitasPage> {
  static const _viewPreferenceKey = 'citas_view_index';
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
  bool _dayLoading = false;
  bool _agendaLoading = false;
  int _dayRequestId = 0;
  int _agendaRequestId = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late DateTime _agendaDay;
  late DateTime _agendaFocusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  CalendarFormat _agendaCalendarFormat = CalendarFormat.week;
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
  String? _medicoFiltroNombre;
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
    _socketClient.dispose();
    super.dispose();
  }

  Future<void> _cargarInicial() async {
    final savedIndex = await PreferencesService.instance.getInt(
      _viewPreferenceKey,
    );
    final resolvedIndex = savedIndex.clamp(0, 2).toInt();
    if (resolvedIndex != _currentTabIndex) {
      setState(() => _currentTabIndex = resolvedIndex);
    }
    await _socketClient.connect();
    if (resolvedIndex == 0) {
      await _cargarCitasAgendaSemana();
      await _cargarCitasAgendaDay(day: _agendaDay);
    } else if (resolvedIndex == 1) {
      await _cargarCitasCalendario();
    } else {
      await _cargarCitasListado(page: 1);
    }
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
    if (widget.soloMisCitas) {
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
    if (widget.soloMisCitas) {
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

  Future<String?> _seleccionarAccionCreacionCita() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Finalizar registro de cita'),
          content: const Text(
            '¿Deseas guardar la cita como borrador o enviarla ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'GUARDAR'),
              child: const Text('Guardar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'ENVIAR'),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _seleccionarAccionEdicionBorrador() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Finalizar edición de borrador'),
          content: const Text(
            '¿Deseas guardar los cambios en borrador o enviar la cita?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'GUARDAR'),
              child: const Text('Guardar borrador'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'ENVIAR'),
              child: const Text('Enviar cita'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmarEnvioCita() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar envío de cita'),
          content: const Text(
            'Una vez enviada la cita ya no se puede editar directamente. '
            '¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sí, enviar'),
            ),
          ],
        );
      },
    );
    return confirmar == true;
  }

  Future<bool> _aplicarCambioEstadoCita(
    CitaMedica cita,
    String estado,
  ) async {
    if (estado == 'CANCELADA') {
      return _handleResponseError(
        await _service.cancelarCita(cita.id),
        'No se pudo cancelar la cita.',
      );
    }
    if (estado == 'COMPLETADA') {
      return _handleResponseError(
        await _service.completarCita(cita.id),
        'No se pudo completar la cita.',
      );
    }
    if (estado == 'CONFIRMADA') {
      return _handleResponseError(
        await _service.confirmarCita(cita.id),
        'No se pudo confirmar la cita.',
      );
    }
    if (estado == 'RECHAZADA') {
      final motivo = await _solicitarMotivoRechazo();
      if (motivo == null) return false;
      return _handleResponseError(
        await _service.rechazarCita(cita.id, motivoRechazo: motivo),
        'No se pudo rechazar la cita.',
      );
    }

    return _handleResponseError(
      await _service.actualizarCita(cita.id, {'estado': estado}),
      'No se pudo actualizar el estado de la cita.',
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
    return DateTime(baseDay.year, baseDay.month, baseDay.day, 8, 0);
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
                              medicoIdSeleccionado: _medicoFiltro,
                              onTapMedico: () async {
                                await _abrirSelectorMedicoFiltro();
                                setStateModal(() {});
                              },
                              onClearMedico: () {
                                setState(() {
                                  _medicoFiltro = null;
                                  _medicoFiltroNombre = null;
                                  _medicoFiltroController.clear();
                                });
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

  Future<void> _setViewIndex(int index) async {
    if (_currentTabIndex == index) return;
    setState(() => _currentTabIndex = index);
    await PreferencesService.instance.setInt(_viewPreferenceKey, index);
    if (index == 0) {
      _cargarCitasAgendaSemana();
      _cargarCitasAgendaDay(day: _agendaDay);
    } else if (index == 1) {
      _cargarCitasCalendario();
    } else {
      _cargarCitasListado();
    }
  }

  void _handleListScroll() {
    if (_currentTabIndex != 2 || _listLoadingMore || !_listHasNext) return;
    if (_listScrollController.position.pixels >=
        _listScrollController.position.maxScrollExtent - 240) {
      setState(() => _listLoadingMore = true);
      _cargarCitasListado(page: _listPage + 1);
    }
  }

  void _handleAgendaScroll() {
    if (_currentTabIndex != 0 || !_agendaScrollController.hasClients) return;
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

  Future<void> _refreshAgenda() async {
    await Future.wait<void>([
      _cargarCitasAgendaSemana(),
      _cargarCitasAgendaDay(day: _agendaDay),
      _recargarConteoCitasCalendario(),
    ]);
  }

  Future<void> _refreshListado() async {
    _listPage = 1;
    _listLoadingMore = false;
    if (_listScrollController.hasClients) {
      _listScrollController.jumpTo(0);
    }
    await Future.wait<void>([
      _cargarCitasListado(page: 1),
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

  Future<void> _abrirSelectorMedicoFiltro() async {
    final List<PersonalMedico> medicosDisponibles = [];
    bool medicosLoading = false;
    bool medicosHasMore = true;
    int medicosPage = 1;
    int total = 0;
    String medicosFiltro = '';
    Timer? medicosDebounce;

    Future<void> cargarMedicos({
      required bool reset,
      VoidCallback? onUpdated,
    }) async {
      if (medicosLoading) return;
      medicosLoading = true;
      onUpdated?.call();
      if (reset) {
        medicosPage = 1;
        medicosHasMore = true;
        total = 0;
        medicosDisponibles.clear();
      }
      final result = await _service.obtenerPersonalMedico(
        page: medicosPage,
        limit: 10,
        filtro: medicosFiltro,
      );
      if (!mounted) return;
      if (result.items.isNotEmpty) {
        medicosDisponibles.addAll(result.items);
      }
      total = result.total;
      medicosHasMore = medicosDisponibles.length < total;
      medicosPage += 1;
      medicosLoading = false;
      onUpdated?.call();
    }

    await cargarMedicos(reset: true);
    if (!mounted) return;

    final seleccionado = await showModalBottomSheet<PersonalMedico>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final searchController = TextEditingController(text: medicosFiltro);
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            Future<void> cargar({required bool reset}) async {
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'Selecciona un médico',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          if (medicosDisponibles.isEmpty && medicosLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (medicosDisponibles.isEmpty) {
                            return const Center(child: Text('Sin resultados'));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount:
                                medicosDisponibles.length +
                                (medicosHasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == medicosDisponibles.length &&
                                  medicosHasMore) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Center(
                                    child: TextButton.icon(
                                      onPressed: medicosLoading
                                          ? null
                                          : () => cargar(reset: false),
                                      icon: const Icon(Icons.expand_more),
                                      label: const Text('Cargar más'),
                                    ),
                                  ),
                                );
                              }
                              final option = medicosDisponibles[index];
                              return ListTile(
                                title: Text(option.nombreCompleto),
                                subtitle:
                                    (option.nroDocumento?.isNotEmpty ?? false)
                                    ? Text('Documento: ${option.nroDocumento}')
                                    : null,
                                onTap: () => Navigator.pop(context, option),
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

    medicosDebounce?.cancel();
    if (seleccionado == null) return;
    setState(() {
      _medicoFiltro = seleccionado.id;
      _medicoFiltroNombre = seleccionado.nombreCompleto;
      _medicoFiltroController.text = seleccionado.nombreCompleto;
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
      _listLoadingMore = false;
    });
    if (_currentTabIndex == 0) {
      _cargarCitasAgendaDay(day: _agendaDay);
    } else if (_currentTabIndex == 1) {
      _cargarCitasCalendario();
    } else {
      _cargarCitasListado(page: 1);
    }
  }

  void _aplicarFiltros() {
    if (_currentTabIndex == 0) {
      _cargarCitasAgendaDay(day: _agendaDay);
    } else if (_currentTabIndex == 1) {
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

  Future<void> _abrirFormulario({CitaMedica? cita, DateTime? fechaBase}) async {
    final formKey = GlobalKey<FormState>();
    final detalleController = TextEditingController(text: cita?.detalle ?? '');
    final medicoController = TextEditingController(
      text: (cita?.medicoNombre ?? '').trim().isNotEmpty
          ? cita!.medicoNombre!
          : cita?.medicoId ?? '',
    );
    String? medicoIdSeleccionado = (cita?.medicoId.isNotEmpty ?? false)
        ? cita?.medicoId
        : null;
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
    String tipoCita = (cita?.tipoCita?.isNotEmpty ?? false)
        ? cita!.tipoCita!
        : 'CONSULTA';
    Especialidad? especialidadSeleccionada;
    Servicio? servicioSeleccionado;
    if (cita?.especialidadId != null && cita!.especialidadId!.isNotEmpty) {
      especialidadSeleccionada = Especialidad(
        id: cita.especialidadId!,
        nombre:
            cita.especialidadNombre ?? 'Especialidad ${cita.especialidadId}',
        descripcion: null,
        estado: 'ACTIVO',
        colorHex: cita.especialidadColorHex ?? '#64748b',
        estudios: const [],
      );
    }
    if (cita?.servicioId != null && cita!.servicioId!.isNotEmpty) {
      servicioSeleccionado = Servicio(
        id: cita.servicioId!,
        nombre: cita.servicioNombre ?? 'Servicio ${cita.servicioId}',
        descripcion: '',
        duracionMinutos: Constantes.citasDuracionDefectoMinutos,
        estado: 'ACTIVO',
        especialidades: const [],
      );
    }
    final especialidadController = TextEditingController(
      text: especialidadSeleccionada?.nombre ?? '',
    );
    final servicioController = TextEditingController(
      text: servicioSeleccionado?.nombre ?? '',
    );
    final List<Especialidad> especialidadesDisponibles = [];
    final List<Servicio> serviciosDisponibles = [];
    final List<Paciente> pacientesDisponibles = [];
    final List<PersonalMedico> medicosDisponibles = [];
    bool especialidadesLoading = false;
    bool serviciosLoading = false;
    bool pacientesLoading = false;
    bool medicosLoading = false;
    bool especialidadesHasMore = true;
    bool serviciosHasMore = true;
    bool pacientesHasMore = true;
    bool medicosHasMore = true;
    int especialidadesPage = 1;
    int serviciosPage = 1;
    int pacientesPage = 1;
    int medicosPage = 1;
    String especialidadesFiltro = '';
    String serviciosFiltro = '';
    String pacientesFiltro = '';
    String medicosFiltro = '';
    Timer? especialidadesDebounce;
    Timer? serviciosDebounce;
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

    int currentStep = 0;
    String? modalErrorText;
    String? accionCreacion;
    String? accionEdicionBorrador;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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

            Future<void> cargarServicios({
              bool reset = false,
              void Function()? onUpdated,
            }) async {
              if (serviciosLoading) return;
              final especialidadId = especialidadSeleccionada?.id ?? '';
              setStateDialog(() => serviciosLoading = true);
              if (reset) {
                serviciosPage = 1;
                serviciosHasMore = true;
                serviciosDisponibles.clear();
              }
              final result = especialidadId.isNotEmpty
                  ? await _service.obtenerServiciosPorEspecialidad(
                      especialidadId: especialidadId,
                      tipo: tipoCita,
                      page: serviciosPage,
                      limit: 10,
                      filtro: serviciosFiltro,
                    )
                  : await _service.obtenerServicios(
                      tipo: tipoCita,
                      page: serviciosPage,
                      limit: 10,
                      filtro: serviciosFiltro,
                    );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  serviciosDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  serviciosDisponibles.addAll(result.items);
                }
                final total = result.total;
                serviciosHasMore = serviciosDisponibles.length < total;
                serviciosPage += 1;
                serviciosLoading = false;
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
              unawaited(cargarServicios(reset: true));
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
              final horaActual = TimeOfDay.fromDateTime(fechaInicio ?? base);
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
                if (!context.mounted) return;
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
                      Future<void> cargar({required bool reset}) async {
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: CustomTextInput(
                                  controller: searchController,
                                  title: 'Buscar paciente',
                                  onChange: (value) {
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
                                      itemCount:
                                          pacientesDisponibles.length +
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
                                                    : () =>
                                                          cargar(reset: false),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option =
                                            pacientesDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombreCompleto),
                                          subtitle:
                                              (option
                                                      .nroDocumento
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
                if (!context.mounted) return;
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
                      Future<void> cargar({required bool reset}) async {
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: CustomTextInput(
                                  controller: searchController,
                                  title: 'Buscar médico',
                                  onChange: (value) {
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
                                      itemCount:
                                          medicosDisponibles.length +
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
                                                    : () =>
                                                          cargar(reset: false),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option =
                                            medicosDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombreCompleto),
                                          subtitle:
                                              (option
                                                      .nroDocumento
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
                if (!context.mounted) return;
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
                      Future<void> cargar({required bool reset}) async {
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: CustomTextInput(
                                  controller: searchController,
                                  title: 'Buscar especialidad',
                                  onChange: (value) {
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
                                                    : () =>
                                                          cargar(reset: false),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text('Cargar más'),
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
                servicioSeleccionado = null;
                servicioController.clear();
                serviciosFiltro = '';
                serviciosDisponibles.clear();
                serviciosHasMore = true;
                serviciosPage = 1;
              });
              unawaited(cargarServicios(reset: true));
            }

            Future<void> abrirSelectorServicio() async {
              if (serviciosDisponibles.isEmpty && !serviciosLoading) {
                await cargarServicios(reset: true);
                if (!context.mounted) return;
              }
              final seleccion = await showModalBottomSheet<Servicio>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  final searchController = TextEditingController(
                    text: serviciosFiltro,
                  );
                  return StatefulBuilder(
                    builder: (context, setStateSheet) {
                      Future<void> cargar({required bool reset}) async {
                        await cargarServicios(
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
                                  'Selecciona un servicio',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: CustomTextInput(
                                  controller: searchController,
                                  title: 'Buscar servicio',
                                  onChange: (value) {
                                    serviciosFiltro = value;
                                    serviciosDebounce?.cancel();
                                    serviciosDebounce = Timer(
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
                                    if (serviciosDisponibles.isEmpty &&
                                        serviciosLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (serviciosDisponibles.isEmpty) {
                                      return const Center(
                                        child: Text('Sin resultados'),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          serviciosDisponibles.length +
                                          (serviciosHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                                serviciosDisponibles.length &&
                                            serviciosHasMore) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: serviciosLoading
                                                    ? null
                                                    : () =>
                                                          cargar(reset: false),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text('Cargar más'),
                                              ),
                                            ),
                                          );
                                        }
                                        final option =
                                            serviciosDisponibles[index];
                                        return ListTile(
                                          title: Text(option.nombre),
                                          subtitle:
                                              option.descripcion.isNotEmpty
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
                servicioSeleccionado = seleccion;
                servicioController.text = seleccion.nombre;
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
                          fechaNacimientoController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        });
                      }

                      Future<void> guardarPaciente() async {
                        if (!formKeyPaciente.currentState!.validate()) return;
                        setStatePaciente(() => guardando = true);
                        final body = <String, dynamic>{
                          'nombres': nombresController.text.trim(),
                          if (primerApellidoController.text.trim().isNotEmpty)
                            'primerApellido': primerApellidoController.text
                                .trim(),
                          if (segundoApellidoController.text.trim().isNotEmpty)
                            'segundoApellido': segundoApellidoController.text
                                .trim(),
                          if (nroDocumentoController.text.trim().isNotEmpty)
                            'nroDocumento': nroDocumentoController.text.trim(),
                          if (fechaNacimiento != null)
                            'fechaNacimiento': DateFormat(
                              'yyyy-MM-dd',
                            ).format(fechaNacimiento!),
                          if (telefonoController.text.trim().isNotEmpty)
                            'telefono': telefonoController.text.trim(),
                          if (generoSeleccionado?.trim().isNotEmpty ?? false)
                            'genero': generoSeleccionado,
                          if (observacionController.text.trim().isNotEmpty)
                            'observacion': observacionController.text.trim(),
                        };
                        final response = await _service.crearPaciente(body);
                        if (!context.mounted) return;
                        final ok = await _handleResponseError(
                          response,
                          'No se pudo registrar el paciente.',
                        );
                        if (!context.mounted) return;
                        if (!ok) {
                          setStatePaciente(() => guardando = false);
                          return;
                        }
                        final raw =
                            response.data['datos'] ??
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
                                CustomTextInput(
                                  controller: nombresController,
                                  title: 'Nombres',
                                  requiredData: true,
                                  validate: (value, alias) =>
                                      _validarRequerido(value, alias),
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: primerApellidoController,
                                  title: 'Primer apellido',
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: segundoApellidoController,
                                  title: 'Segundo apellido',
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: nroDocumentoController,
                                  title: 'Número de documento',
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: fechaNacimientoController,
                                  readOnly: true,
                                  decoration: CustomTextInputStyles.decoration(
                                    label: 'Fecha de nacimiento',
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.event),
                                      onPressed: seleccionarFechaNacimiento,
                                    ),
                                  ),
                                  onTap: seleccionarFechaNacimiento,
                                ),
                                const SizedBox(height: 12),
                                CustomTextInput(
                                  controller: telefonoController,
                                  title: 'Teléfono',
                                  onlyNumbers: true,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: generoSeleccionado,
                                  decoration: CustomTextInputStyles.decoration(
                                    label: 'Género',
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
                                CustomTextInput(
                                  controller: observacionController,
                                  title: 'Observaciones',
                                  lines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: guardando
                                ? null
                                : () => Navigator.pop(context),
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

            String? validarPasoActual() {
              if (currentStep == 1 && servicioSeleccionado == null) {
                return 'Selecciona el servicio de la cita.';
              }
              if (currentStep == 2 && fechaInicio == null) {
                return 'Selecciona fecha y hora de inicio.';
              }
              return null;
            }

            Widget buildResumenCard() {
              final resumenStyle = Theme.of(context).textTheme.bodyMedium;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _theme.primary.withValues(alpha: .08),
                  border: Border.all(
                    color: _theme.primary.withValues(alpha: .2),
                  ),
                ),
                child: Wrap(
                  runSpacing: 8,
                  children: [
                    Text(
                      'Paciente: ${pacienteSeleccionado?.nombreCompleto.isNotEmpty == true ? pacienteSeleccionado!.nombreCompleto : 'Pendiente'}',
                      style: resumenStyle,
                    ),
                    Text(
                      'Servicio: ${servicioSeleccionado?.nombre ?? 'Pendiente'}',
                      style: resumenStyle,
                    ),
                    Text(
                      'Fecha: ${fechaInicio != null ? _dateTimeFormat.format(fechaInicio!) : 'Pendiente'}',
                      style: resumenStyle,
                    ),
                  ],
                ),
              );
            }

            Widget stepContent() {
              if (currentStep == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildResumenCard(),
                    const SizedBox(height: 12),
                    FormField<Paciente>(
                      key: pacienteFieldKey,
                      builder: (state) {
                        return CitasAutocompleteSelectorField(
                          controller: pacienteAutocompleteController,
                          labelText: 'Paciente (opcional)',
                          hintText: 'Selecciona un paciente si aplica',
                          errorText: state.errorText,
                          onClear: pacienteSeleccionado == null
                              ? null
                              : () {
                                  setStateDialog(() {
                                    pacienteSeleccionado = null;
                                    pacienteAutocompleteController.clear();
                                  });
                                  state.didChange(null);
                                },
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
                        pacienteFieldKey.currentState?.didChange(nuevo);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Registrar paciente en el momento'),
                    ),
                  ],
                );
              }

              if (currentStep == 1) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildResumenCard(),
                    const SizedBox(height: 12),
                    FormField<Especialidad>(
                      builder: (state) {
                        return CitasAutocompleteSelectorField(
                          controller: especialidadController,
                          labelText: 'Especialidad (opcional)',
                          hintText: 'Selecciona una especialidad',
                          errorText: state.errorText,
                          onTap: () async {
                            await abrirSelectorEspecialidad();
                            state.didChange(especialidadSeleccionada);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          text: 'Tipo de servicio',
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    RadioGroup<String>(
                      groupValue: tipoCita,
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() {
                          tipoCita = value;
                          servicioSeleccionado = null;
                          servicioController.clear();
                          serviciosDisponibles.clear();
                          serviciosHasMore = true;
                          serviciosPage = 1;
                          unawaited(cargarServicios(reset: true));
                        });
                      },
                      child: const Column(
                        children: [
                          RadioListTile<String>(
                            title: Text('Consulta'),
                            value: 'CONSULTA',
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<String>(
                            title: Text('Estudio'),
                            value: 'ESTUDIO',
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    CitasAutocompleteSelectorField(
                      controller: servicioController,
                      labelText: 'Servicio',
                      requiredData: true,
                      hintText: 'Selecciona un servicio',
                      onTap: abrirSelectorServicio,
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildResumenCard(),
                  const SizedBox(height: 12),
                  CustomTextInput(
                    controller: detalleController,
                    title: 'Detalle',
                    lines: 2,
                  ),
                  const SizedBox(height: 12),
                  FormField<PersonalMedico>(
                    builder: (state) {
                      return CitasAutocompleteSelectorField(
                        controller: medicoController,
                        labelText: 'Médico',
                        hintText: 'Selecciona un médico (opcional)',
                        errorText: state.errorText,
                        onClear: medicoIdSeleccionado == null
                            ? null
                            : () {
                                setStateDialog(() {
                                  medicoSeleccionado = null;
                                  medicoIdSeleccionado = null;
                                  medicoController.clear();
                                });
                                state.didChange(null);
                              },
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
                          label: 'Fecha',
                          requiredData: true,
                          value: fechaInicio,
                          formatter: _dateFormat,
                          onTap: updateFechaInicioFecha,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FechaSelector(
                          label: 'Hora',
                          requiredData: true,
                          value: fechaInicio,
                          formatter: _timeFormat,
                          onTap: updateFechaInicioHora,
                          icon: Icons.schedule,
                        ),
                      ),
                    ],
                  ),
                  if (cita != null &&
                      (cita.estado == 'SOLICITADA' ||
                          cita.estado == 'CONFIRMADA'))
                    const SizedBox(height: 12),
                  if (cita != null &&
                      (cita.estado == 'SOLICITADA' ||
                          cita.estado == 'CONFIRMADA'))
                    DropdownButtonFormField<String?>(
                      initialValue: estado,
                      decoration: CustomTextInputStyles.decoration(
                        label: 'Estado',
                      ),
                      items: [
                        cita.estado,
                        if (cita.estado == 'SOLICITADA') ...[
                          'CONFIRMADA',
                          'RECHAZADA',
                        ],
                        if (cita.estado == 'CONFIRMADA') 'CANCELADA',
                      ].toSet().map((estadoItem) {
                        final requierePermiso =
                            estadoItem == 'CONFIRMADA' ||
                            estadoItem == 'RECHAZADA';
                        final habilitado =
                            !requierePermiso ||
                            _puedeGestionarSolicitada(cita) ||
                            estadoItem == cita.estado;
                        return DropdownMenuItem(
                          value: estadoItem,
                          enabled: habilitado,
                          child: Text(estadoItem),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() => estado = value);
                      },
                    ),
                ],
              );
            }

            return Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * .92,
                    ),
                    decoration: BoxDecoration(
                      color: _theme.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: PopScope(
                      canPop: true,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          MediaQuery.of(context).viewInsets.bottom + 16,
                        ),
                        child: Form(
                          key: formKey,
                          child: StepFormDialogLayout(
                            title: cita == null
                                ? 'Registro rápido de cita'
                                : 'Actualizar cita en 3 pasos',
                            totalSteps: 3,
                            currentStep: currentStep,
                            stepErrorText: modalErrorText,
                            submitErrorText: null,
                            isSubmitting: false,
                            onClose: () => Navigator.pop(context, false),
                            onBack: currentStep > 0
                                ? () {
                                    setStateDialog(() {
                                      currentStep -= 1;
                                      modalErrorText = null;
                                    });
                                  }
                                : null,
                            nextLabel: currentStep == 2
                                ? (cita == null
                                      ? 'Finalizar'
                                      : (cita.estado == 'BORRADOR'
                                            ? 'Finalizar'
                                            : 'Guardar cambios'))
                                : 'Siguiente',
                            stepContent: stepContent(),
                            onNext: () async {
                              final error = validarPasoActual();
                              if (error != null) {
                                setStateDialog(() => modalErrorText = error);
                                return;
                              }
                              if (currentStep < 2) {
                                setStateDialog(() {
                                  currentStep += 1;
                                  modalErrorText = null;
                                });
                                return;
                              }
                              if (cita == null) {
                                final accion =
                                    await _seleccionarAccionCreacionCita();
                                if (accion == null) return;
                                if (accion == 'ENVIAR') {
                                  final confirmado = await _confirmarEnvioCita();
                                  if (!confirmado) return;
                                }
                                accionCreacion = accion;
                              } else if (cita.estado == 'BORRADOR') {
                                final accion =
                                    await _seleccionarAccionEdicionBorrador();
                                if (accion == null) return;
                                if (accion == 'ENVIAR') {
                                  final confirmado = await _confirmarEnvioCita();
                                  if (!confirmado) return;
                                }
                                accionEdicionBorrador = accion;
                              }
                              Navigator.pop(context, true);
                            },
                          ),
                        ),
                      ),
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
    serviciosDebounce?.cancel();
    pacientesDebounce?.cancel();
    medicosDebounce?.cancel();
    if (result != true) return;

    final detalle = detalleController.text.trim();
    final medicoId = (medicoIdSeleccionado ?? '').trim();
    final pacienteId = (pacienteSeleccionado?.id ?? '').trim();
    final especialidadId = especialidadSeleccionada?.id ?? '';

    if (cita == null) {
      final accion = accionCreacion ?? 'GUARDAR';
      final response = await _service.crearCita({
        'accion': accion,
        'detalle': detalle,
        'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
        if (medicoId.isNotEmpty) 'idMedico': medicoId,
        if (pacienteSeleccionado != null)
          'idPaciente': pacienteSeleccionado?.id,
        if (especialidadId.isNotEmpty) 'idEspecialidad': especialidadId,
        'tipoCita': tipoCita,
        if (servicioSeleccionado != null)
          'idServicio': servicioSeleccionado!.id,
      });
      final ok = await _handleResponseError(response, 'No se pudo crear la cita.');
      if (!ok) return;

      showSnackBar(
        citasMessenger,
        accion == 'GUARDAR'
            ? 'Cita guardada en borrador'
            : 'Cita enviada al calendario',
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      await _cargarCitasCalendario();
      if (_currentTabIndex == 2) {
        await _cargarCitasListado(page: 1);
      }
      return;
    }

    final estadoActual = cita.estado;
    final estadoSeleccionado = estado;
    final cambioDetalle = detalle != cita.detalle;
    final cambioFecha = fechaInicio != cita.fechaInicio;
    final cambioMedico = medicoId != cita.medicoId;
    final cambioPaciente = pacienteId != (cita.pacienteId ?? '');
    final cambioEspecialidad = especialidadId != (cita.especialidadId ?? '');
    final cambioTipoCita = tipoCita != (cita.tipoCita ?? '');
    final cambioServicio = servicioSeleccionado?.id != (cita.servicioId ?? '');

    if (estadoActual == 'BORRADOR') {
      final updates = <String, dynamic>{};
      if (cambioDetalle) updates['detalle'] = detalle;
      if (cambioMedico) updates['idMedico'] = medicoId;
      if (cambioPaciente) {
        updates['idPaciente'] = pacienteId.isEmpty ? null : pacienteId;
      }
      if (cambioEspecialidad) {
        updates['idEspecialidad'] = especialidadId;
      }
      if (cambioTipoCita) updates['tipoCita'] = tipoCita;
      if (cambioServicio) {
        updates['idServicio'] = servicioSeleccionado?.id;
      }
      if (cambioFecha) {
        updates['fechaInicio'] = fechaInicio!.toUtc().toIso8601String();
      }

      if (updates.isNotEmpty) {
        final ok = await _handleResponseError(
          await _service.editarBorradorCita(cita.id, updates),
          'No se pudo actualizar la cita borrador.',
        );
        if (!ok) return;
      }

      if (accionEdicionBorrador == 'ENVIAR') {
        final ok = await _handleResponseError(
          await _service.enviarCita(cita.id, idMedico: medicoId),
          'No se pudo enviar la cita.',
        );
        if (!ok) return;
      }
    } else if (estadoActual == 'SOLICITADA') {
      if (cambioMedico ||
          cambioPaciente ||
          cambioEspecialidad ||
          cambioTipoCita ||
          cambioServicio) {
        showSnackBar(
          citasMessenger,
          'En SOLICITADA solo puedes ajustar hora y detalle.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
      if (!_puedeGestionarSolicitada(cita)) {
        showSnackBar(
          citasMessenger,
          'Solo el profesional asignado o el administrador pueden gestionar una cita solicitada.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }

      final ajuste = <String, dynamic>{};
      if (cambioDetalle) ajuste['detalle'] = detalle;
      if (cambioFecha) {
        ajuste['fechaInicio'] = fechaInicio!.toUtc().toIso8601String();
      }

      if (estadoSeleccionado == null || estadoSeleccionado == estadoActual) {
        if (ajuste.isNotEmpty) {
          showSnackBar(
            citasMessenger,
            'En SOLICITADA debes confirmar o rechazar para aplicar cambios.',
            state: StatusSnackBar.error,
            colorText: _theme.white,
          );
        }
        return;
      }

      if (estadoSeleccionado == 'CANCELADA') {
        showSnackBar(
          citasMessenger,
          'Una cita solicitada no puede cancelarse directamente.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }

      if (estadoSeleccionado == 'CONFIRMADA') {
        final ok = await _handleResponseError(
          await _service.confirmarCita(cita.id, body: ajuste),
          'No se pudo confirmar la cita.',
        );
        if (!ok) return;
      } else if (estadoSeleccionado == 'RECHAZADA') {
        final motivo = await _solicitarMotivoRechazo();
        if (motivo == null) return;
        final ok = await _handleResponseError(
          await _service.rechazarCita(cita.id, motivoRechazo: motivo),
          'No se pudo rechazar la cita.',
        );
        if (!ok) return;
      } else {
        showSnackBar(
          citasMessenger,
          'En SOLICITADA solo puedes confirmar o rechazar.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
    } else if (estadoActual == 'CONFIRMADA') {
      if (cambioDetalle ||
          cambioMedico ||
          cambioPaciente ||
          cambioEspecialidad ||
          cambioTipoCita ||
          cambioServicio) {
        showSnackBar(
          citasMessenger,
          'La cita confirmada no es editable.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
      if (estadoSeleccionado == 'CANCELADA') {
        final ok = await _handleResponseError(
          await _service.cancelarCita(cita.id),
          'No se pudo cancelar la cita.',
        );
        if (!ok) return;
      } else if (cambioFecha) {
        final ok = await _handleResponseError(
          await _service.reprogramarCita(cita.id, {
            'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
            'tipoCita': tipoCita,
            if (servicioSeleccionado != null)
              'idServicio': servicioSeleccionado!.id,
          }),
          'No se pudo reprogramar la cita.',
        );
        if (!ok) return;
      } else if (estadoSeleccionado != null && estadoSeleccionado != estadoActual) {
        showSnackBar(
          citasMessenger,
          'En CONFIRMADA solo puedes cancelar o reprogramar.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
    } else if (estadoActual == 'CANCELADA' || estadoActual == 'NO_ASISTIO') {
      if (cambioDetalle ||
          cambioMedico ||
          cambioPaciente ||
          cambioEspecialidad ||
          cambioTipoCita ||
          cambioServicio ||
          (estadoSeleccionado != null && estadoSeleccionado != estadoActual)) {
        showSnackBar(
          citasMessenger,
          'En este estado solo está permitida la reprogramación.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
      if (cambioFecha) {
        final ok = await _handleResponseError(
          await _service.reprogramarCita(cita.id, {
            'fechaInicio': fechaInicio!.toUtc().toIso8601String(),
            'tipoCita': tipoCita,
            if (servicioSeleccionado != null)
              'idServicio': servicioSeleccionado!.id,
          }),
          'No se pudo reprogramar la cita.',
        );
        if (!ok) return;
      } else {
        showSnackBar(
          citasMessenger,
          'En este estado solo está permitida la reprogramación.',
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
        return;
      }
    } else {
      showSnackBar(
        citasMessenger,
        'La cita no es editable en su estado actual.',
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
      return;
    }

    await _cargarCitasCalendario();
    if (_currentTabIndex == 2) {
      await _cargarCitasListado();
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'BORRADOR':
        return _theme.grey.withValues(alpha: 0.7);
      case 'CONFIRMADA':
        return _theme.success;
      case 'COMPLETADA':
      case 'REPROGRAMADA':
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

  String _normalizarRol(String rol) {
    final normalized = rol.toUpperCase();
    switch (normalized) {
      case 'ADMIN':
        return 'ADMINISTRADOR';
      case 'MEDICO':
      case 'PERSONAL_MEDICO':
      case 'SUPERVISOR':
        return 'PERSONAL_SALUD';
      default:
        return normalized;
    }
  }

  bool _tieneRol(String rol) {
    final normalized = _normalizarRol(rol);
    final perfil = Auth.instance.profile;
    final roles = <String>{};
    if ((perfil.rol ?? '').trim().isNotEmpty) {
      roles.add(_normalizarRol(perfil.rol!));
    }
    roles.addAll(
      perfil.roles
          .map((rol) => _normalizarRol(rol.rol))
          .where((rol) => rol.trim().isNotEmpty),
    );
    return roles.contains(normalized);
  }

  bool _esAdministrador() => _tieneRol('ADMINISTRADOR');

  bool _esPersonalSaludSupervisor() {
    return _tieneRol('PERSONAL_SALUD') && Auth.instance.profile.esSupervisor;
  }

  bool _esMedicoAsignado(CitaMedica cita) {
    final medicoId = cita.medicoId.trim();
    final idUsuarioRol = (Auth.instance.profile.idUsuarioRol ?? '').trim();
    if (medicoId.isEmpty || idUsuarioRol.isEmpty) return false;
    return medicoId == idUsuarioRol;
  }

  bool _puedeAprobarRechazar(CitaMedica cita) {
    return _esMedicoAsignado(cita) ||
        _esAdministrador() ||
        _esPersonalSaludSupervisor();
  }

  bool _puedeGestionarSolicitada(CitaMedica cita) {
    return _esMedicoAsignado(cita) || _esAdministrador();
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
    if (normalized == 'ESTUDIO') return 'Servicio';
    if (normalized == 'CONSULTA') return 'Consulta';
    return value;
  }

  String _formatearDetallePersona(HistorialDetallePersona detalle) {
    final nombre = detalle.nombreCompleto;
    final parts = <String>[
      if (nombre.trim().isNotEmpty) nombre,
      if ((detalle.nroDocumento ?? '').trim().isNotEmpty)
        detalle.nroDocumento!.trim(),
      if (detalle.especialidades.isNotEmpty) detalle.especialidades.join(', '),
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

  String _formatearDetalleServicio(HistorialDetalleEstudio detalle) {
    final nombre = detalle.nombre.trim();
    return nombre.isNotEmpty ? nombre : '--';
  }

  String _formatearCambioServicio({
    required String label,
    required String beforeValue,
    required String afterValue,
    HistorialDetalleEstudio? beforeDetalle,
    HistorialDetalleEstudio? afterDetalle,
  }) {
    final antes = beforeDetalle != null
        ? _formatearDetalleServicio(beforeDetalle)
        : beforeValue;
    final despues = afterDetalle != null
        ? _formatearDetalleServicio(afterDetalle)
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
      'tipoCita': 'Tipo de servicio',
      'esEstudio': 'Tipo de servicio',
      'idEspecialidad': 'Especialidad',
      'idMedico': 'Médico',
      'idPaciente': 'Paciente',
      'idConsultorio': 'Consultorio',
      'idServicio': 'Servicio',
      'idEstudio': 'Servicio',
    };

    final label = labels[field] ?? field;
    final beforeMatch = RegExp(r'before:\s*([^,}]+)').firstMatch(trimmed);
    final afterMatch = RegExp(r'after:\s*([^,}]+)').firstMatch(trimmed);
    final beforeValue = beforeMatch != null
        ? _normalizarValorHistorial(beforeMatch.group(1)!)
        : '';
    final afterValue = afterMatch != null
        ? _normalizarValorHistorial(afterMatch.group(1)!)
        : '';

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
      'tipoCita': 'Tipo de servicio',
      'esEstudio': 'Tipo de servicio',
      'idEspecialidad': 'Especialidad',
      'idMedico': 'Médico',
      'idPaciente': 'Paciente',
      'idConsultorio': 'Consultorio',
      'idServicio': 'Servicio',
      'idEstudio': 'Servicio',
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
    if (field == 'idServicio' || field == 'idEstudio') {
      return _formatearCambioServicio(
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
                                    fechaInicioController.text = _dateFormat
                                        .format(picked);
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
                                    fechaFinController.text = _dateFormat
                                        .format(picked);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: estadoAnterior,
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
                                  cargarHistorial(setStateDialog, reset: true),
                                );
                              },
                              child: const Text('Limpiar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                unawaited(
                                  cargarHistorial(setStateDialog, reset: true),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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


  List<PopupMenuEntry<int>> _buildViewItems(TextStyle? textStyle) {
    const labels = ['Agenda diaria', 'Calendario', 'Listado'];
    return List.generate(
      labels.length,
      (index) => CheckedPopupMenuItem<int>(
        value: index,
        checked: index == _currentTabIndex,
        child: Text(labels[index], style: textStyle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final citasCalendarioFiltradas = _filtrarCitasLocal(_citasCalendario);
    final citasListadoFiltradas = _filtrarCitasLocal(_citasListado);
    final citasSeleccionadas = _selectedDay != null
        ? _citasSeleccionadas
        : citasCalendarioFiltradas;
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
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _theme.white.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: PopupMenuButton<int>(
                    tooltip: 'Vista',
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    onSelected: (value) {
                      if (value == _currentTabIndex) return;
                      _setViewIndex(value);
                    },
                    itemBuilder: (context) => _buildViewItems(
                      Theme.of(context).textTheme.bodySmall,
                    ),
                    icon: Icon(
                      Icons.view_list_rounded,
                      color: _theme.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _toggleFilters,
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: _theme.white,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  side: BorderSide(
                    color: _theme.white.withValues(alpha: 0.35),
                  ),
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
                                  child: IndexedStack(
                                    index: _currentTabIndex,
                                    children: [
                                      CitasAgendaSection(
                                        citas: _filtrarCitasLocal(_citasAgenda),
                                        isCompact: isCompact,
                                        theme: _theme,
                                        dateFormat: _dateFormat,
                                        agendaDay: _agendaDay,
                                        agendaFocusedDay: _agendaFocusedDay,
                                        agendaCalendarFormat:
                                            _agendaCalendarFormat,
                                        agendaCalendarCollapsed:
                                            _agendaCalendarCollapsed,
                                        citasAgendaPorDia: _citasAgendaPorDia,
                                        onAgendaDaySelected:
                                            (selectedDay, focusedDay) {
                                              setState(
                                                () => _agendaFocusedDay =
                                                    focusedDay,
                                              );
                                              _seleccionarAgendaDay(
                                                selectedDay,
                                              );
                                            },
                                        onPageChanged: (focusedDay) {
                                          setState(
                                            () =>
                                                _agendaFocusedDay = focusedDay,
                                          );
                                          _cargarCitasAgendaSemana();
                                        },
                                        onAgendaFormatChanged: (format) {
                                          if (_agendaCalendarFormat != format) {
                                            setState(
                                              () => _agendaCalendarFormat =
                                                  format,
                                            );
                                            _cargarCitasAgendaSemana();
                                          }
                                        },
                                        onExpandCalendar: () => setState(
                                          () =>
                                              _agendaCalendarCollapsed = false,
                                        ),
                                        isLoading: _agendaLoading,
                                        onRefresh: _refreshAgenda,
                                        scrollController:
                                            _agendaScrollController,
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
                                      CitasCalendarioPanel(
                                        theme: _theme,
                                        calendarFormat: _calendarFormat,
                                        focusedDay: _focusedDay,
                                        selectedDay: _selectedDay,
                                        citasPorDia:
                                            _cantidadCitasCalendarioPorDia,
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
                                                _agendaDay = DateTime(
                                                  selectedDay.year,
                                                  selectedDay.month,
                                                  selectedDay.day,
                                                );
                                                _agendaFocusedDay = _agendaDay;
                                              });
                                              _cargarCitasDelDia(
                                                day: selectedDay,
                                              );
                                            },
                                        onPageChanged: (focusedDay) {
                                          setState(
                                            () => _focusedDay = focusedDay,
                                          );
                                          if (_currentTabIndex == 1) {
                                            _cargarCitasCalendario();
                                          }
                                        },
                                        isCompact: isCompact,
                                        dayLoading: _dayLoading,
                                        listado: CitasListado(
                                          citas: citasSeleccionadas,
                                          theme: _theme,
                                          controller: null,
                                          onRefresh: isCompact
                                              ? null
                                              : _refreshCalendario,
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
                                              () =>
                                                  _abrirFormulario(cita: cita),
                                          puedeEditar: _puedeEditarCita,
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
                                        puedeEditar: _puedeEditarCita,
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

  String _subtituloCita(CitaMedica cita) {
    final estudio = (cita.servicioNombre ?? cita.servicioId ?? '').trim();
    final especialidad = (cita.especialidadNombre ?? cita.especialidadId ?? '')
        .trim();
    final detalle = cita.detalle.trim();
    final parts = <String>[
      if (estudio.isNotEmpty) estudio,
      if (especialidad.isNotEmpty) especialidad,
      if (detalle.isNotEmpty) detalle,
    ];
    return parts.join(' • ');
  }


  bool _puedeEditarCita(CitaMedica cita) {
    final estado = cita.estado;
    return estado == 'BORRADOR' || estado == 'RECHAZADA';
  }

  Future<bool> _confirmarAccionCita({
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
    final confirmar = await _confirmarAccionCita(
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
    final nuevaFecha = await _seleccionarFechaHoraReprogramacion(cita.fechaInicio);
    if (nuevaFecha == null) return;
    final confirmar = await _confirmarAccionCita(
      titulo: 'Reprogramar cita',
      mensaje: '¿Confirmas reprogramar la cita para ${_dateTimeFormat.format(nuevaFecha)}?',
      accion: 'Sí, reprogramar',
    );
    if (!confirmar) return;
    final ok = await _handleResponseError(
      await _service.reprogramarCita(cita.id, {
        'fechaInicio': nuevaFecha.toUtc().toIso8601String(),
        'tipoCita': cita.tipoCita,
        if ((cita.servicioId ?? '').trim().isNotEmpty) 'idServicio': cita.servicioId,
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
    final confirmar = await _confirmarAccionCita(
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
    final confirmar = await _confirmarAccionCita(
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
    final confirmar = await _confirmarAccionCita(
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
    final controller = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Motivo de rechazo'),
        content: TextFormField(
          controller: controller,
          maxLines: 3,
          maxLength: 255,
          decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return motivo;
  }

  Future<bool> _rechazarCitaSolicitadaConConfirmacion(CitaMedica cita) async {
    if (!_puedeGestionarSolicitada(cita)) return false;
    final motivo = await _solicitarMotivoRechazo();
    if (motivo == null) return false;
    final ok = await _handleResponseError(
      await _service.rechazarCita(cita.id, motivoRechazo: motivo),
      'No se pudo rechazar la cita.',
    );
    if (!ok) return false;
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
                  decoration: const InputDecoration(
                    labelText: 'Detalle (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: seleccionarFechaHora,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    fechaSeleccionada == null
                        ? 'Ajustar hora (opcional)'
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

  Future<void> _mostrarDetalleCita(CitaMedica cita) async {
    final especialidadNombre = (cita.especialidadNombre ?? cita.especialidadId)
        ?.trim();
    final estudioNombre = (cita.servicioNombre ?? cita.servicioId)?.trim();
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _theme.grey),
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
                        label: 'Tipo de servicio',
                        value: cita.tipoCita!,
                        theme: _theme,
                      ),
                    if (estudioNombre?.isNotEmpty ?? false)
                      CitasDetalleRow(
                        icon: PhosphorIconsRegular.testTube,
                        label: 'Servicio',
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
            if (_puedeEditarCita(cita))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _abrirFormulario(cita: cita);
                },
                child: const Text('Editar'),
              ),
            if (cita.estado == 'SOLICITADA' && _puedeGestionarSolicitada(cita))
              TextButton(
                onPressed: () async {
                  final ok = await _rechazarCitaSolicitadaConConfirmacion(cita);
                  if (ok && mounted) Navigator.of(context).pop();
                },
                child: const Text('Rechazar'),
              ),
            if (cita.estado == 'SOLICITADA' && _puedeGestionarSolicitada(cita))
              TextButton(
                onPressed: () async {
                  final ok = await _confirmarCitaSolicitadaConOpciones(cita);
                  if (ok && mounted) Navigator.of(context).pop();
                },
                child: const Text('Confirmar'),
              ),
            if (cita.estado == 'BORRADOR')
              TextButton(
                onPressed: () async {
                  await _eliminarBorradorConConfirmacion(cita);
                },
                child: const Text('Eliminar'),
              ),
            if (cita.estado == 'CONFIRMADA' && _citaYaIniciada(cita))
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _marcarNoAsistioCitaConConfirmacion(cita);
                },
                child: const Text('No asistió'),
              ),
            if (cita.estado == 'CONFIRMADA' && _citaYaIniciada(cita))
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _completarCitaConConfirmacion(cita);
                },
                child: const Text('Completar'),
              ),
            if (cita.estado == 'CONFIRMADA')
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _cancelarCitaConConfirmacion(cita);
                },
                child: const Text('Cancelar'),
              ),
            if (cita.estado == 'CONFIRMADA' ||
                cita.estado == 'CANCELADA' ||
                cita.estado == 'NO_ASISTIO')
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _reprogramarCitaConConfirmacion(cita);
                },
                child: const Text('Reprogramar'),
              ),
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
