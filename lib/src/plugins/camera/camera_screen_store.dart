
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CameraScreenStore with ChangeNotifier {
  CameraScreenStore._();
  static final instance = CameraScreenStore._();

  Position? _posicion;

  Position? get posicion => _posicion;
  set posicion(Position? posicion) {
    _posicion = posicion;
    notifyListeners();
  }

  bool _cargando = false;
  bool get cargando => _cargando;
  set cargando(bool value) {
    _cargando = value;
    notifyListeners();
  }

  void clean() {
    _posicion = null;
    notifyListeners();
  }
}
