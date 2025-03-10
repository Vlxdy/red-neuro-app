import 'dart:io';

import 'package:flutter/material.dart';

class RegistroVolumenesStore with ChangeNotifier {
  RegistroVolumenesStore._();
  static final instance = RegistroVolumenesStore._();
  List<String> _fotos = [];
  List<String> get fotos => _fotos;

  set fotos(List<String> value) {
    _fotos = value;
    notifyListeners();
  }

  void eliminarFoto(int index) {
    if (index >= 0 && index < fotos.length) {
      _fotos.removeAt(index);
      notifyListeners();
    } else {
      throw RangeError('Índice fuera de rango: $index');
    }
  }

  List<File> fotografias() {
    return fotos.map((foto) => File(foto)).toList();
  }

  bool validarFotos() {
    if (fotos.isNotEmpty) {
      return true;
    }
    return false;
  }
}
