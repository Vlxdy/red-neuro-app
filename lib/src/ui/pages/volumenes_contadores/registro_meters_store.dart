import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/models/registro_meters.dart';

class RegistroMetersStore with ChangeNotifier {
  RegistroMetersStore._();
  static final instance = RegistroMetersStore._();

  List<RegistroMeterStore> _registrosMeters = [];

  List<RegistroMeterStore> get registros => _registrosMeters;

  void guardarRegistro(List<RegistroMeterStore> registros) {
    _registrosMeters = registros;
    notifyListeners();
  }

  void limpiarRegistros() {
    _registrosMeters = [];
    notifyListeners();
  }
}
