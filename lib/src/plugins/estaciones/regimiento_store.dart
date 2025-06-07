import 'dart:convert';

import 'package:camino_seguro/src/constants/keys.dart';
import 'package:camino_seguro/src/models/regimiento.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class RegimientoStore with ChangeNotifier {
  Regimiento _regimiento = Regimiento(id: '', nombre: '', tipoFuerza: '');

  RegimientoStore._();
  static final instance = RegimientoStore._();
  final PreferencesService _preferencesService = PreferencesService.instance;

  Regimiento get regimiento => _regimiento;
  set setRegimiento(Regimiento value) {
    _regimiento = value;
    notifyListeners();
  }

  Future<void> actualizar(Map<String, dynamic> json) async {
    final nuevoRegimiento = Regimiento.fromJson(json);
    await _preferencesService.setString(
        Keys.regimiento, jsonEncode(nuevoRegimiento.toJson()));
    setRegimiento = nuevoRegimiento;
  }

  Future<Regimiento> regimientoAsync() async {
    if (_regimiento.id.isNotEmpty) return _regimiento;
    Regimiento antiguoRegimiento =
        Regimiento(id: '', nombre: '', tipoFuerza: '');
    try {
      final decode = await _preferencesService.getString(Keys.regimiento);
      if (decode.isNotEmpty) {
        antiguoRegimiento = Regimiento.fromJson(jsonDecode(decode));
      }
    } catch (e, stacktrace) {
      Logger.error('exception bitacora -> ${e.toString()}');
      Logger.error('stacktrace $stacktrace');
    }
    setRegimiento = antiguoRegimiento;
    return antiguoRegimiento;
  }
}
