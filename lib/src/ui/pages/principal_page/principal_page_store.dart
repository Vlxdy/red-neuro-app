import 'package:control_ventas_movil/src/models/conductor.dart';
import 'package:control_ventas_movil/src/models/vehiculo.dart';
import 'package:flutter/material.dart';

class PrincipalPageStore with ChangeNotifier {
  PrincipalPageStore._();
  static final instance = PrincipalPageStore._();

  
  bool _cargando = false;
  bool get cargando => _cargando;
  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  List<Vehiculo> _vehiculos = [];
  List<Vehiculo> get vehiculos => _vehiculos;
  set vehiculos(List<Vehiculo> value) {
    _vehiculos = value;
    notifyListeners();
  }

  Vehiculo _vehiculoActivo = Vehiculo.empty;
  Vehiculo get vehiculoActivo => _vehiculoActivo;
  set vehiculoActivo(Vehiculo vehiculo) {
    _vehiculoActivo = vehiculo;
    notifyListeners();
  }

  // List<CargaCombustible> _historialCargas = [];
  // List<CargaCombustible> get historialCargas => _historialCargas;
  // set historialCargas(List<CargaCombustible> value) {
  //   _historialCargas = value;
  //   notifyListeners();
  // }

  List<ConductorVehiculo> _conductores = [];
  List<ConductorVehiculo> get conductores => _conductores;
  set conductores(List<ConductorVehiculo> value) {
    _conductores = value;
    notifyListeners();
  }
}
