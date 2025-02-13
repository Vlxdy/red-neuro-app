import 'package:flutter/foundation.dart';

class ControlStore with ChangeNotifier {
  ControlStore._();
  static final instance = ControlStore._();

  List<String> _estaciones = [];
  List<String> _horarios = [];

  String? _estacionSeleccionada;
  String? _horarioSeleccionado;

  List<String> get estaciones => _estaciones;
  List<String> get horarios => _horarios;
  String? get estacionSeleccionada => _estacionSeleccionada;
  String? get horarioSeleccionado => _horarioSeleccionado;

  set estaciones(List<String> value) {
    _estaciones = value;
    notifyListeners();
  }

  set horarios(List<String> value) {
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
