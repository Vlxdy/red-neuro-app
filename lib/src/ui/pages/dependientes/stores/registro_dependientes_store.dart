import 'package:alimenta_app/src/constants/enums.dart';
import 'package:alimenta_app/src/models/dependiente.dart';
import 'package:flutter/material.dart';

class RegistroDependientesStore with ChangeNotifier {
  RegistroDependientesStore._() : _datosFinalizados = false;

  static final RegistroDependientesStore instance =
      RegistroDependientesStore._();
  List<Dependiente> _listaDependientes = [];
  List<DependienteRuta> _listaDependientesRuta = [];
  bool _cargando = false;
  late List<TipoMedicion> tiposMedicionTanques = TipoMedicion.values.toList();
  List<Dependiente> get listaDependientes => _listaDependientes;
  List<DependienteRuta> get listaDependientesRuta => _listaDependientesRuta;
  bool get cargando => _cargando;

  set setlistaDependientes(List<Dependiente> value) {
    _listaDependientes = value;
    notifyListeners();
  }

  set setlistaDependientesRuta(List<DependienteRuta> value) {
    _listaDependientesRuta = value;
    notifyListeners();
  }

  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  bool _datosFinalizados = false;
  bool get datosFinalizados => _datosFinalizados;
  set datosFinalizados(bool val) {
    _datosFinalizados = val;
    notifyListeners();
  }

  void limpiarDatos() {
    _datosFinalizados = false;
    notifyListeners();
  }
}
