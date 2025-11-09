import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/constants/citas_estado.dart';
import 'package:alimenta_app/src/models/cita.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/citas_medicas_keys.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/services/citas_medicas_service.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/stores/citas_medicas_store.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/widgets/cita_detalle_sheet.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/widgets/cita_form_sheet.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/widgets/estado_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CitasMedicasPage extends StatefulWidget {
  const CitasMedicasPage({super.key});

  @override
  State<CitasMedicasPage> createState() => _CitasMedicasPageState();
}

class _CitasMedicasPageState extends State<CitasMedicasPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late final CitasMedicasService _service;
  late final TabController _tabController;
  final ThemeController _theme = ThemeController.instance;
  final TextEditingController _busquedaController = TextEditingController();
  final ScrollController _agendaScrollController = ScrollController();
  final DateFormat _fechaLarga = DateFormat('EEEE d MMMM yyyy', 'es');
  final DateFormat _horaCorta = DateFormat('HH:mm', 'es');
  final DateTime _hoy = DateUtils.dateOnly(DateTime.now());

  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _service = CitasMedicasService('', context);
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = CitasMedicasStore.instance;
      _busquedaController.text = store.filtroBusqueda;
      _refrescarCalendario(store);
      _refrescarAgenda(store, pagina: store.pagina);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaController.dispose();
    _agendaScrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _refrescarCalendario(CitasMedicasStore store) async {
    final estados = store.estadosSeleccionados.isEmpty
        ? null
        : store.estadosSeleccionados.toList();
    final diaEnfocado = store.diaEnfocado;
    final inicioMes = DateTime(diaEnfocado.year, diaEnfocado.month, 1);
    final finMes =
        DateTime(diaEnfocado.year, diaEnfocado.month + 1, 0, 23, 59, 59, 999);
    await _service.obtenerCitasPorRango(
      fechaInicio: inicioMes,
      fechaFin: finMes,
      estados: estados,
    );
  }

  Future<void> _refrescarAgenda(
    CitasMedicasStore store, {
    int? pagina,
    bool resetScroll = false,
  }) async {
    final estados = store.estadosSeleccionados.isEmpty
        ? null
        : store.estadosSeleccionados.toList();
    await _service.obtenerAgenda(
      pagina: pagina ?? store.pagina,
      limite: store.limite,
      filtro: store.filtroBusqueda.isEmpty ? null : store.filtroBusqueda,
      fecha: store.fechaFiltroAgenda,
      estados: estados,
    );
    if (resetScroll && _agendaScrollController.hasClients) {
      _agendaScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _alternarEstado(CitasMedicasStore store, CitasEstado estado) {
    store.alternarEstado(estado);
    store.setPagina(1);
    _refrescarCalendario(store);
    _refrescarAgenda(store, pagina: 1, resetScroll: true);
  }

  void _limpiarEstados(CitasMedicasStore store) {
    store.limpiarEstados();
    store.setPagina(1);
    _refrescarCalendario(store);
    _refrescarAgenda(store, pagina: 1, resetScroll: true);
  }

  Future<void> _seleccionarFecha(CitasMedicasStore store) async {
    final ahora = DateTime.now();
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: store.fechaFiltroAgenda ?? ahora,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
    );

    if (fechaSeleccionada != null) {
      store.setFechaFiltroAgenda(fechaSeleccionada);
      store.setPagina(1);
      _refrescarAgenda(store, pagina: 1, resetScroll: true);
    }
  }

  void _limpiarFecha(CitasMedicasStore store) {
    store.setFechaFiltroAgenda(null);
    store.setPagina(1);
    _refrescarAgenda(store, pagina: 1, resetScroll: true);
  }

  void _aplicarBusqueda(CitasMedicasStore store) {
    store.setFiltroBusqueda(_busquedaController.text.trim());
    store.setPagina(1);
    _refrescarAgenda(store, pagina: 1, resetScroll: true);
  }

  void _cambiarLimite(CitasMedicasStore store, int nuevoLimite) {
    if (store.limite == nuevoLimite) return;
    store.setLimite(nuevoLimite);
    store.setPagina(1);
    _refrescarAgenda(store, pagina: 1, resetScroll: true);
  }

  void _cambiarPagina(CitasMedicasStore store, int nuevaPagina) {
    if (nuevaPagina == store.pagina) return;
    store.setPagina(nuevaPagina);
    _refrescarAgenda(store, pagina: nuevaPagina, resetScroll: true);
  }

  void _abrirDetalle(Cita cita) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => CitaDetalleSheet(
        cita: cita,
        service: _service,
        onRefresh: () => _recargarTodo(resetScrollAgenda: false),
      ),
    );
  }

  Future<void> _recargarTodo({required bool resetScrollAgenda}) async {
    final store = CitasMedicasStore.instance;
    await _refrescarCalendario(store);
    await _refrescarAgenda(
      store,
      pagina: store.pagina,
      resetScroll: resetScrollAgenda,
    );
  }

  Future<void> _abrirFormularioNuevaCita() async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => CitaFormSheet(service: _service),
    );

    if (resultado == true) {
      final store = CitasMedicasStore.instance;
      store.setPagina(1);
      await _refrescarCalendario(store);
      await _refrescarAgenda(
        store,
        pagina: 1,
        resetScroll: true,
      );
    }
  }

  Widget _buildDiaCalendario(
    BuildContext context,
    DateTime day,
    CitasMedicasStore store, {
    required bool esSeleccionado,
    required bool esHoy,
    required bool esFueraMes,
  }) {
    final eventos = store.obtenerEventos(day);
    final textoBase = Theme.of(context).textTheme.bodySmall;
    final colorTexto = esSeleccionado
        ? _theme.white
        : esFueraMes
            ? _theme.monochromatic500
            : _theme.fontColor;

    final fondo = esSeleccionado ? _theme.primary : Colors.transparent;

    final bordeHoy = esHoy && !esSeleccionado
        ? Border.all(color: _theme.primary.withValues(alpha: 0.5), width: 1.2)
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(0.5),
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(esSeleccionado ? 20 : 10),
        border: bordeHoy,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: textoBase?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color: colorTexto,
                height: 1.0,
              ),
            ),
            if (eventos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: eventos.length == 1
                    ? Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: esSeleccionado
                              ? _theme.white
                              : _theme.secondary.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: esSeleccionado
                              ? _theme.white.withValues(alpha: 0.2)
                              : _theme.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${eventos.length}',
                          style: textoBase?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colorTexto,
                            height: 1.0,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarioTab(CitasMedicasStore store) {
    final eventosDia = store.obtenerEventos(store.diaSeleccionado);
    return RefreshIndicator(
      onRefresh: () => _refrescarCalendario(store),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          EstadoFilterChips(
            estadosSeleccionados: store.estadosSeleccionados,
            onToggle: (estado) => _alternarEstado(store, estado),
            onClear: store.estadosSeleccionados.isEmpty
                ? null
                : () => _limpiarEstados(store),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy', 'es')
                              .format(store.diaEnfocado)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _calendarFormat =
                                  _calendarFormat == CalendarFormat.month
                                      ? CalendarFormat.week
                                      : CalendarFormat.month;
                            });
                          },
                          icon: Icon(
                            _calendarFormat == CalendarFormat.month
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: _theme.primary,
                          ),
                          label: Text(
                            _calendarFormat == CalendarFormat.month
                                ? 'Ver semana'
                                : 'Ver mes',
                            style: TextStyle(color: _theme.primary),
                          ),
                        ),
                      ],
                    ),
                    TableCalendar<Cita>(
                      locale: 'es',
                      firstDay: DateTime.utc(2015, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: store.diaEnfocado,
                      calendarFormat: _calendarFormat,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Mes',
                        CalendarFormat.week: 'Semana',
                      },
                      rowHeight:
                          _calendarFormat == CalendarFormat.month ? 72 : 48,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, store.diaSeleccionado),
                      onDaySelected: (selectedDay, focusedDay) {
                        store.setDiaSeleccionado(selectedDay);
                        store.setDiaEnfocado(focusedDay);
                        setState(() {
                          _calendarFormat = CalendarFormat.week;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        store.setDiaEnfocado(focusedDay);
                        _refrescarCalendario(store);
                      },
                      headerVisible: false,
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(),
                        selectedDecoration: BoxDecoration(),
                        markersMaxCount: 0,
                      ),
                      eventLoader: (day) => store.obtenerEventos(day),
                      calendarBuilders: CalendarBuilders<Cita>(
                        defaultBuilder: (context, day, focusedDay) =>
                            _buildDiaCalendario(
                          context,
                          day,
                          store,
                          esSeleccionado: isSameDay(day, store.diaSeleccionado),
                          esHoy: isSameDay(day, _hoy),
                          esFueraMes: day.month != focusedDay.month,
                        ),
                        outsideBuilder: (context, day, focusedDay) =>
                            _buildDiaCalendario(
                          context,
                          day,
                          store,
                          esSeleccionado: isSameDay(day, store.diaSeleccionado),
                          esHoy: isSameDay(day, _hoy),
                          esFueraMes: true,
                        ),
                        todayBuilder: (context, day, focusedDay) =>
                            _buildDiaCalendario(
                          context,
                          day,
                          store,
                          esSeleccionado: isSameDay(day, store.diaSeleccionado),
                          esHoy: true,
                          esFueraMes: day.month != focusedDay.month,
                        ),
                        selectedBuilder: (context, day, focusedDay) =>
                            _buildDiaCalendario(
                          context,
                          day,
                          store,
                          esSeleccionado: true,
                          esHoy: isSameDay(day, _hoy),
                          esFueraMes: day.month != focusedDay.month,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(
              height: 1, color: _theme.monochromatic500.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Citas del ${_fechaLarga.format(store.diaSeleccionado)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (store.cargandoCalendario)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (eventosDia.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No hay citas registradas para este día.'),
              ),
            )
          else
            ...eventosDia.map((cita) => _buildCitaCard(cita)),
        ],
      ),
    );
  }

  Widget _buildAgendaTab(CitasMedicasStore store) {
    return RefreshIndicator(
      onRefresh: () => _refrescarAgenda(store),
      child: ListView(
        controller: _agendaScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          EstadoFilterChips(
            estadosSeleccionados: store.estadosSeleccionados,
            onToggle: (estado) => _alternarEstado(store, estado),
            onClear: store.estadosSeleccionados.isEmpty
                ? null
                : () => _limpiarEstados(store),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _busquedaController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _aplicarBusqueda(store),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Buscar por paciente, detalle o nutricionista',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busquedaController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _busquedaController.clear();
                        _aplicarBusqueda(store);
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _seleccionarFecha(store),
                  icon: const Icon(Icons.event),
                  label: Text(
                    store.fechaFiltroAgenda != null
                        ? DateFormat('dd/MM/yyyy')
                            .format(store.fechaFiltroAgenda!)
                        : 'Filtrar por fecha específica',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (store.fechaFiltroAgenda != null)
                IconButton(
                  onPressed: () => _limpiarFecha(store),
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpiar fecha',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Resultados por página:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: store.limite,
                items: const [10, 20, 50]
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _cambiarLimite(store, value);
                  }
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _aplicarBusqueda(store),
                icon: const Icon(Icons.search),
                label: const Text('Aplicar filtros'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (store.cargandoAgenda)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (store.agenda.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child:
                  Center(child: Text('No se encontraron citas en la agenda.')),
            )
          else
            ...store.agenda.map((cita) => _buildCitaCard(cita)),
          const SizedBox(height: 16),
          _buildPaginacion(store),
        ],
      ),
    );
  }

  Widget _buildCitaCard(Cita cita) {
    final fecha = _fechaLarga.format(cita.fechaInicio);
    final horaInicio = _horaCorta.format(cita.fechaInicio);
    final horaFin = _horaCorta.format(cita.fechaFin);
    final estadoColor = cita.estado.color(_theme);
    final estadoTextColor = cita.estado.textColor(_theme);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        onTap: () => _abrirDetalle(cita),
        title:
            Text(cita.detalle.isNotEmpty ? cita.detalle : 'Cita sin detalle'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$fecha • $horaInicio - $horaFin'),
            const SizedBox(height: 4),
            Text(
                'Nutricionista: ${cita.medico.nombreCompleto.isNotEmpty ? cita.medico.nombreCompleto : 'Sin asignar'}'),
            Text(
                'Paciente: ${cita.paciente.nombreCompleto.isNotEmpty ? cita.paciente.nombreCompleto : 'Sin asignar'}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: estadoColor.withValues(alpha: _theme.isLight ? 0.8 : 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            cita.estado.label,
            style: TextStyle(
              color: estadoTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginacion(CitasMedicasStore store) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: store.puedeRetroceder
              ? () => _cambiarPagina(store, store.pagina - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Página ${store.pagina} de ${store.totalPaginas}'),
        IconButton(
          onPressed: store.puedeAvanzar
              ? () => _cambiarPagina(store, store.pagina + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldMessenger(
      key: citasMedicasMessenger,
      child: Scaffold(
        backgroundColor: _theme.background,
        appBar: AppBar(
          title: const Text('Citas médicas'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Calendario'),
              Tab(text: 'Agenda'),
            ],
          ),
        ),
        body: Consumer<CitasMedicasStore>(
          builder: (context, store, _) {
            return TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCalendarioTab(store),
                _buildAgendaTab(store),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_nueva_cita',
          onPressed: _abrirFormularioNuevaCita,
          backgroundColor: _theme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
