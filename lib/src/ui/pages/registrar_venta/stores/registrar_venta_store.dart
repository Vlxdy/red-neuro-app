import 'dart:io';

import 'package:control_ventas_movil/src/models/registrar_venta.dart';
import 'package:flutter/material.dart';

class RegistrarVentaStore with ChangeNotifier {
  RegistrarVentaStore._();
  static final instance = RegistrarVentaStore._();

  bool _cargando = false;
  bool get cargando => _cargando;

  set cargando(bool value) {
    _cargando = value;
    notifyListeners();
  }

  RegistrarVenta form = RegistrarVenta.empty;

  List<String> get fotos => form.fotos;

  set fotos(List<String> value) {
    form.fotos = value;
    notifyListeners();
  }

  void eliminarFoto(int index) {
    if (index >= 0 && index < form.fotos.length) {
      form.fotos.removeAt(index);
      notifyListeners();
    } else {
      throw RangeError('Índice fuera de rango: $index');
    }
  }

  List<File> fotografias() {
    return fotos.map((foto) => File(foto)).toList();
  }

  set observacion(String value) {
    form.observacion = value;
    notifyListeners();
  }

  bool validarFotos() {
    if (fotos.isNotEmpty) {
      return true;
    }
    return false;
  }

  void clean() {
    // form = Conformidad.empty;
    notifyListeners();
  }
}
