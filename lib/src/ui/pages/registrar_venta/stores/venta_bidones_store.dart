import 'package:control_ventas_movil/src/models/venta.dart';
import 'package:flutter/foundation.dart';

class VentaBidonesStore with ChangeNotifier {
  VentaBidonesStore._();
  static final instance = VentaBidonesStore._();

  bool _cargando = false;
  bool get cargando => _cargando;
  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  List<Venta> _ventas = [];
  List<Venta> get ventas => _ventas;
  set ventas(List<Venta> val) {
    _ventas = val;
    notifyListeners();
  }

  void clean() {
    _ventas = [];
    notifyListeners();
  }
}
