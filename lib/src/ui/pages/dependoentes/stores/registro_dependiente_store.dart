import 'dart:io';
import 'package:camino_seguro/src/models/dependiente.dart';
import 'package:flutter/material.dart';

class RegistroDependienteStore with ChangeNotifier {
  RegistroDependienteStore._() : _datosFinalizados = false;

  static final RegistroDependienteStore instance = RegistroDependienteStore._();
  List<Dependiente> _listaDependientes = [];
  bool _cargando = false;
  List<Dependiente> get listaDependientes => _listaDependientes;
  bool get cargando => _cargando;

  set setlistaDependientes(List<Dependiente> value) {
    _listaDependientes = value;
    notifyListeners();
  }

  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  bool _datosFinalizados = false;
  bool get datosFinalizados => _datosFinalizados;
  set datosFinalizados(bool val) {
    _datosFinalizados = val;
    notifyListeners();
  }

  void limpiarDatos() {
    _datosFinalizados = false;
    notifyListeners();
  }
}
