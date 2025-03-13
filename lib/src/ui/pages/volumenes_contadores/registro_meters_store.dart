import 'package:control_ventas_movil/src/constants/enums.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/models/registro_meters.dart';

class RegistroMetersStore with ChangeNotifier {
  RegistroMetersStore._();
  static final instance = RegistroMetersStore._();
  late List<TipoMedicion> tiposMedicionMeters = TipoMedicion.values.toList();

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

  DataListadoMeters _dataListadoMeters = DataListadoMeters(volumenes: []);
  DataListadoMeters get dataListadoMeters => _dataListadoMeters;

  set dataListadoMeters(DataListadoMeters? value) {
    _dataListadoMeters = value ?? DataListadoMeters(volumenes: []);
    notifyListeners();
  }

  void limpiarDataListado() {
    _dataListadoMeters = DataListadoMeters(volumenes: []);
    notifyListeners();
  }

  void getTipoMedicionMeters() {
    if (_dataListadoMeters.volumenes.isNotEmpty) {
      var tipoMedicion = _dataListadoMeters
          .volumenes.first.dispensadores[0].mangueras[0].tipoMedicion
          .toString();
      if (tipoMedicion == TipoMedicion.inicialJornada.info) {
        tiposMedicionMeters.remove(
            TipoMedicion.values.firstWhere((e) => e.info == tipoMedicion));
      } else if (tipoMedicion == TipoMedicion.finJornada.info) {
        tiposMedicionMeters = [];
      }
    }
  }
}
//para el formulario de guardar 
 //   EstadoRegistroStore.instance.actualizarMeters(_tipoSeleccionado!);
//  void _guardarFormulario() { //en control meters form