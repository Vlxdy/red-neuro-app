import 'package:flutter/material.dart';

class CambiarContrasenaStore with ChangeNotifier {
  CambiarContrasenaStore._();

  static final instance = CambiarContrasenaStore._();

  double _calificacion = 0;
  double get calificacion => _calificacion;

  set calificacion(double value) {
    _calificacion = value;
    notifyListeners();
  }

  // ------------- contrasenas --------------
  String _contrasena = '';
  String get contrasena => _contrasena;

  set contrasena(String value) {
    _contrasena = value;
    notifyListeners();
  }

  String _nuevaContrasena = '';
  String get nuevaContrasena => _nuevaContrasena;

  set nuevaContrasena(String value) {
    _nuevaContrasena = value;
    notifyListeners();
  }

  String _repiteContrasena = '';
  String get repiteContrasena => _repiteContrasena;

  set repiteContrasena(String value) {
    _repiteContrasena = value;
    notifyListeners();
  }

  //----------------------------------------
  bool _cargando = false;
  bool get cargando => _cargando;

  set cargando(bool value) {
    _cargando = value;
    notifyListeners();
  }
}
