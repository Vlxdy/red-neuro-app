import 'package:flutter/foundation.dart';

class VentaBidon {
  final String codigo;
  final int cantidadVentas;

  VentaBidon({
    required this.codigo,
    required this.cantidadVentas,
  });

  factory VentaBidon.fromJson(Map<String, dynamic> json) {
    return VentaBidon(
      codigo: json['codigo'] ?? 'Desconocido',
      cantidadVentas: int.tryParse(json['cantidadVentas']?.toString() ?? '0') ?? 0,
    );
  }
}

class VentaBidonesStore with ChangeNotifier {
  VentaBidonesStore._();
  static final instance = VentaBidonesStore._();

  bool _cargando = false;
  bool get cargando => _cargando;
  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  List<VentaBidon> _ventas = [];
  List<VentaBidon> get ventas => _ventas;
  set ventas(List<VentaBidon> val) {
    _ventas = val;
    notifyListeners();
  }

  void clean() {
    _ventas = [];
    notifyListeners();
  }
}
