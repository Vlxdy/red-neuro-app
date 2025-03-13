import 'dart:io';
import 'package:control_ventas_movil/src/models/volumenes_tanques.dart';
import 'package:flutter/material.dart';

class RegistroVolumenesStore with ChangeNotifier {
  RegistroVolumenesStore._();

  static final RegistroVolumenesStore instance = RegistroVolumenesStore._();
  List<VolumenTanque> _listaVolumenes = [];
  bool _cargando = false;

  List<VolumenTanque> get listaVolumenes => _listaVolumenes;
  bool get cargando => _cargando;

  set setlistaVolumenes(List<VolumenTanque> value) {
    _listaVolumenes = value;
    notifyListeners();
  }

  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  final Map<String, List<String>> _fotos = {};
  late String _tipoMedicion;
  final Map<String, ItemResumen> _datos = {};

  String get tipoMedicion => _tipoMedicion;
  Map<String, ItemResumen> get datos => _datos;
  Map<String, List<String>> get fotos => _fotos;

  set setTipoMedicion(String value) {
    _tipoMedicion = value;
    notifyListeners();
  }

  List<String> obtenerFotos(String index) {
    return _fotos[index] ?? [];
  }

  set setFotos(Map<String, List<String>> value) {
    _fotos.clear();
    _fotos.addAll(value);
    notifyListeners();
  }

  void actualizarFoto(List<String> value, String index) {
    _fotos[index] = List.from(value);
    notifyListeners();
  }

  void eliminarFoto(int indexFoto, String indexLista) {
    if (_fotos.containsKey(indexLista) &&
        indexFoto >= 0 &&
        indexFoto < _fotos[indexLista]!.length) {
      _fotos[indexLista]!.removeAt(indexFoto);
      notifyListeners();
    }
  }

  List<File> obtenerFotografias(String index) {
    return (_fotos[index] ?? []).map((foto) => File(foto)).toList();
  }

  bool tieneFotos(String index) {
    return _fotos[index]?.isNotEmpty ?? false;
  }

  void limpiarDatos() {
    _fotos.clear();
    _datos.clear();
    notifyListeners();
  }

  void actualizarDatos(ItemResumen value, String index) {
    _datos[index] = value;
    notifyListeners();
  }

  ItemResumen? obtenerDatos(String index) {
    return _datos.containsKey(index) ? _datos[index] : null;
  }
}
