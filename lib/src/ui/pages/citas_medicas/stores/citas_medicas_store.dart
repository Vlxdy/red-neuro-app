import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:flutter/material.dart';

class CitasMedicasStore with ChangeNotifier {
  CitasMedicasStore._();

  static final CitasMedicasStore instance = CitasMedicasStore._();

  Map<DateTime, List<Cita>> _eventosPorDia = {};
  bool _cargandoCalendario = false;
  bool _cargandoAgenda = false;
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _diaEnfocado = DateTime.now();
  Set<CitasEstado> _estadosSeleccionados = {};

  List<Cita> _agenda = [];
  int _totalAgenda = 0;
  int _pagina = 1;
  int _limite = 10;
  String _filtroBusqueda = '';
  DateTime? _fechaFiltroAgenda;

  Map<DateTime, List<Cita>> get eventosPorDia => _eventosPorDia;
  bool get cargandoCalendario => _cargandoCalendario;
  bool get cargandoAgenda => _cargandoAgenda;
  DateTime get diaSeleccionado => _diaSeleccionado;
  DateTime get diaEnfocado => _diaEnfocado;
  Set<CitasEstado> get estadosSeleccionados => _estadosSeleccionados;

  List<Cita> get agenda => _agenda;
  int get totalAgenda => _totalAgenda;
  int get pagina => _pagina;
  int get limite => _limite;
  String get filtroBusqueda => _filtroBusqueda;
  DateTime? get fechaFiltroAgenda => _fechaFiltroAgenda;

  List<Cita> obtenerEventos(DateTime dia) {
    return _eventosPorDia[DateUtils.dateOnly(dia)] ?? [];
  }

  void setEventosCalendario(List<Cita> citas) {
    final Map<DateTime, List<Cita>> agrupados = {};
    for (final cita in citas) {
      final dia = DateUtils.dateOnly(cita.fechaInicio);
      agrupados.putIfAbsent(dia, () => []);
      agrupados[dia]!.add(cita);
    }
    _eventosPorDia = agrupados;
    notifyListeners();
  }

  void setCargandoCalendario(bool value) {
    _cargandoCalendario = value;
    notifyListeners();
  }

  void setCargandoAgenda(bool value) {
    _cargandoAgenda = value;
    notifyListeners();
  }

  void setDiaSeleccionado(DateTime dia) {
    _diaSeleccionado = DateUtils.dateOnly(dia);
    notifyListeners();
  }

  void setDiaEnfocado(DateTime dia) {
    _diaEnfocado = DateUtils.dateOnly(dia);
    notifyListeners();
  }

  void alternarEstado(CitasEstado estado) {
    if (_estadosSeleccionados.contains(estado)) {
      _estadosSeleccionados.remove(estado);
    } else {
      _estadosSeleccionados.add(estado);
    }
    notifyListeners();
  }

  void limpiarEstados() {
    _estadosSeleccionados = {};
    notifyListeners();
  }

  void setEstadosSeleccionados(Set<CitasEstado> estados) {
    _estadosSeleccionados = estados;
    notifyListeners();
  }

  void setAgenda(
    List<Cita> citas,
    int total,
    int pagina,
    int limite,
    String filtro,
    DateTime? fecha,
  ) {
    _agenda = citas;
    _totalAgenda = total;
    _pagina = pagina;
    _limite = limite;
    _filtroBusqueda = filtro;
    _fechaFiltroAgenda = fecha != null ? DateUtils.dateOnly(fecha) : null;
    notifyListeners();
  }

  void setPagina(int nuevaPagina) {
    _pagina = nuevaPagina;
    notifyListeners();
  }

  void setLimite(int nuevoLimite) {
    _limite = nuevoLimite;
    notifyListeners();
  }

  void setFiltroBusqueda(String filtro) {
    _filtroBusqueda = filtro;
    notifyListeners();
  }

  void setFechaFiltroAgenda(DateTime? fecha) {
    _fechaFiltroAgenda = fecha != null ? DateUtils.dateOnly(fecha) : null;
    notifyListeners();
  }

  int get totalPaginas {
    if (_limite <= 0) return 1;
    final paginas = (_totalAgenda / _limite).ceil();
    return paginas == 0 ? 1 : paginas;
  }

  bool get puedeRetroceder => _pagina > 1;

  bool get puedeAvanzar => _pagina < totalPaginas;

  void reset() {
    _eventosPorDia = {};
    _agenda = [];
    _totalAgenda = 0;
    _pagina = 1;
    _limite = 10;
    _filtroBusqueda = '';
    _estadosSeleccionados = {};
    _fechaFiltroAgenda = null;
    _diaSeleccionado = DateTime.now();
    _diaEnfocado = DateTime.now();
    notifyListeners();
  }
}
