import 'package:camino_seguro/src/constants/enums.dart';
import 'package:camino_seguro/src/models/area.dart';
import 'package:flutter/material.dart';

class RegistroAreasStore with ChangeNotifier {
  RegistroAreasStore._() : _datosFinalizados = false;

  static final RegistroAreasStore instance = RegistroAreasStore._();
  List<Area> _listaAreas = [];
  bool _cargando = false;
  late List<TipoMedicion> tiposMedicionTanques = TipoMedicion.values.toList();
  List<Area> get listaAreas => _listaAreas;
  bool get cargando => _cargando;

  set setlistaAreas(List<Area> value) {
    _listaAreas = value;
    notifyListeners();
  }

  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  bool? _fotosCompletas;
  bool? get fotosCompletas => _fotosCompletas;
  set fotosCompletas(bool? val) {
    _fotosCompletas = val;
    notifyListeners();
  }

  bool _datosFinalizados = false;
  bool get datosFinalizados => _datosFinalizados;
  set datosFinalizados(bool val) {
    _datosFinalizados = val;
    notifyListeners();
  }

  late String _tipoMedicion;

  String get tipoMedicion => _tipoMedicion;
  set setTipoMedicion(String value) {
    _tipoMedicion = value;
    notifyListeners();
  }

  void limpiarDatos() {
    _datosFinalizados = false;
    _fotosCompletas = null;
    notifyListeners();
  }
}
