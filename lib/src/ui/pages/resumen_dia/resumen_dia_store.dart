import 'package:control_ventas_movil/src/models/resumen_dia.dart';
import 'package:flutter/foundation.dart';

class ResumenDiaStore with ChangeNotifier {
  ResumenDiaStore._();
  static final instance = ResumenDiaStore._();

  bool _cargando = false;
  bool get cargando => _cargando;
  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  ResumenDia _resumenDia = ResumenDia(ventas: [], volumenes: []);

  ResumenDia get resumenDia => _resumenDia;

  set setResumenDia(ResumenDia? value) {
    _resumenDia = value ?? ResumenDia(ventas: [], volumenes: []);
    notifyListeners();
  }

  void clean() {
    _resumenDia = ResumenDia(ventas: [], volumenes: []);
    notifyListeners();
  }
}
