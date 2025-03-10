import 'dart:convert';

import 'package:control_ventas_movil/src/constants/keys.dart';
import 'package:control_ventas_movil/src/models/combustible.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class CombustiblesStore with ChangeNotifier {
  List<Combustible> _combustibles = [];

  CombustiblesStore._();
  static final instance = CombustiblesStore._();
  final PreferencesService _preferencesService = PreferencesService.instance;

  List<Combustible> get combustibles => _combustibles;
  
  set setCombustibles(List<Combustible> value) {
    _combustibles = value;
    notifyListeners();
  }

  /// Ahora recibe una lista en lugar de un `Map<String, dynamic>`
  Future<void> actualizar(List<dynamic> jsonList) async {
    Logger.info(jsonList.toString());

    try {
      final nuevosCombustibles = jsonList.map((item) => Combustible.fromJson(item)).toList();

      await _preferencesService.setString(
        Keys.combustibles,
        jsonEncode(nuevosCombustibles.map((e) => e.toJson()).toList()),
      );

      setCombustibles = nuevosCombustibles;
    } catch (e, stacktrace) {
      Logger.error('Error al actualizar combustibles: $e');
      Logger.error('Stacktrace: $stacktrace');
    }
  }

  Future<List<Combustible>> combustiblesAsync() async {
    if (_combustibles.isNotEmpty) return _combustibles;
    
    List<Combustible> antiguosCombustibles = [];
    try {
      final decode = await _preferencesService.getString(Keys.combustibles);
      if (decode.isNotEmpty) {
        antiguosCombustibles = (jsonDecode(decode) as List)
            .map((item) => Combustible.fromJson(item))
            .toList();
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al obtener combustibles -> ${e.toString()}');
      Logger.error('Stacktrace: $stacktrace');
    }
    
    setCombustibles = antiguosCombustibles;
    return antiguosCombustibles;
  }
}
