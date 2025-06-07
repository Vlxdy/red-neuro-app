import 'dart:convert';
import 'package:camino_seguro/src/constants/keys.dart';
import 'package:camino_seguro/src/models/estacion_servicio.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class EstacionServicioStore with ChangeNotifier {
  EstacionServicio _estacionServicio = EstacionServicio(
      id: '', estado: '', latitud: '', longitud: '', nombre: '');

  EstacionServicioStore._();
  static final instance = EstacionServicioStore._();
  final PreferencesService _preferencesService = PreferencesService.instance;

  EstacionServicio get estacionServicio => _estacionServicio;
  set setEstacionServicio(EstacionServicio value) {
    _estacionServicio = value;
    notifyListeners();
  }

  Future<void> actualizar(Map<String, dynamic> json) async {
    final nuevaEstacionServicio = EstacionServicio.fromJson(json);
    await _preferencesService.setString(
        Keys.estacionServicio, jsonEncode(nuevaEstacionServicio.toJson()));
    setEstacionServicio = nuevaEstacionServicio;
    notifyListeners();
  }

  Future<EstacionServicio> estacionServicioAsync() async {
    if (_estacionServicio.nombre.isNotEmpty) return _estacionServicio;
    EstacionServicio antiguaEstacion = EstacionServicio(
        id: '', nombre: '', estado: '', latitud: '', longitud: '');
    try {
      final decode = await _preferencesService.getString(Keys.estacionServicio);
      if (decode.isNotEmpty) {
        antiguaEstacion = EstacionServicio.fromJson(jsonDecode(decode));
      }
    } catch (e, stacktrace) {
      Logger.error('exception bitacora -> ${e.toString()}');
      Logger.error('stacktrace $stacktrace');
    }
    setEstacionServicio = antiguaEstacion;
    return antiguaEstacion;
  }
}
