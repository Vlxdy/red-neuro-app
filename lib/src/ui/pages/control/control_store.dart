import 'package:camino_seguro/src/models/estacion_servicio.dart';
import 'package:camino_seguro/src/models/horario.dart';
import 'package:flutter/foundation.dart';

class ControlStore with ChangeNotifier {
  ControlStore._();
  static final instance = ControlStore._();

  bool _cargando = false;
  bool get cargando => _cargando;
  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  List<EstacionServicio> _estaciones = [];
  List<Horario> _horarios = [];

  String? _estacionSeleccionada;
  String? _horarioSeleccionado;

  List<EstacionServicio> get estaciones => _estaciones;
  List<Horario> get horarios => _horarios;
  String? get estacionSeleccionada => _estacionSeleccionada;
  String? get horarioSeleccionado => _horarioSeleccionado;

  set estaciones(List<EstacionServicio> value) {
    _estaciones = value;
    notifyListeners();
  }

  set horarios(List<Horario> value) {
    _horarios = value;
    notifyListeners();
  }

  set estacionSeleccionada(String? value) {
    _estacionSeleccionada = value;
    notifyListeners();
  }

  set horarioSeleccionado(String? value) {
    _horarioSeleccionado = value;
    notifyListeners();
  }

  void clean() {
    _estacionSeleccionada = null;
    _horarioSeleccionado = null;
  }
}
