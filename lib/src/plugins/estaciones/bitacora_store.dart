import 'dart:convert';
import 'package:red_neuro_app/src/constants/keys.dart';
import 'package:red_neuro_app/src/models/bitacora.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class BitacoraStore with ChangeNotifier {
  Bitacora _bitacora = Bitacora(id: '');

  Bitacora get bitacora => _bitacora;
  set setBitacora(Bitacora value) {
    _bitacora = value;
    notifyListeners();
  }

  BitacoraStore._();
  static final instance = BitacoraStore._();
  final PreferencesService _preferencesService = PreferencesService.instance;

  Future<void> actualizar(Map<String, dynamic> json, DateTime fecha) async {
    final datosBitacora = {
      "id": json['idBitacora'],
      "fecha": fecha.toIso8601String()
    };
    final nuevaBitacora = Bitacora.fromJson(datosBitacora);
    await _preferencesService.setString(
        Keys.bitacora, jsonEncode(nuevaBitacora.toJson()));
    setBitacora = nuevaBitacora;
  }

  Future<Bitacora> bitacoraAsync() async {
    if (_bitacora.id.isNotEmpty) return _bitacora;
    Bitacora antiguaBitacora = Bitacora(id: '');
    try {
      final decode = await _preferencesService.getString(Keys.bitacora);
      if (decode.isNotEmpty) {
        antiguaBitacora = Bitacora.fromJson(jsonDecode(decode));
      }
    } catch (e, stacktrace) {
      Logger.error('exception bitacora -> ${e.toString()}');
      Logger.error('stacktrace $stacktrace');
    }
    setBitacora = antiguaBitacora;
    return antiguaBitacora;
  }
}
