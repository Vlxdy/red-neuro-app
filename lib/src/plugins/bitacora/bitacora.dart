import 'dart:convert';
import 'package:control_ventas_movil/src/constants/keys.dart';
import 'package:control_ventas_movil/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class BitacoraStore with ChangeNotifier {
  BitacoraStore._();
  static final instance = BitacoraStore._();

  String _idBitacora = '';
  DateTime? _fechaBitacora;

  // Método para obtener la bitácora como un mapa
  Map<String, dynamic> get bitacora => {
        "id": _idBitacora,
        "fecha": _fechaBitacora?.toIso8601String(),
      };

  // Método para actualizar la bitácora
  void setBitacora(String id, DateTime fecha) {
    _idBitacora = id;
    _fechaBitacora = fecha;
    notifyListeners();
  }
}

class Bitacora {
  String _idBitacora = '';
  DateTime? _fechaBitacora;

  Bitacora._();
  static final instance = Bitacora._();

  final store = BitacoraStore.instance;
  final PreferencesService _preferencesService = PreferencesService.instance;

  // Obtener la bitácora almacenada
  Future<Map<String, dynamic>> get bitacora async {
    try {
      if (_idBitacora.isEmpty) {
        String? data = await _preferencesService.getStringSecure(Keys.bitacora);
        if (data.isNotEmpty) {
          Map<String, dynamic> bitacoraMap = json.decode(data);
          _idBitacora = bitacoraMap['id'];
          _fechaBitacora = DateTime.parse(bitacoraMap['fecha']);
        }
      }
      return {
        "id": _idBitacora,
        "fecha": _fechaBitacora?.toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  // Método para actualizar la bitácora en el almacenamiento
  Future<void> updateBitacora(
      {required String id, required DateTime fecha}) async {
    _idBitacora = id;
    _fechaBitacora = fecha;

    // Guardar en almacenamiento seguro como JSON
    Map<String, dynamic> bitacoraData = {
      "id": _idBitacora,
      "fecha": _fechaBitacora?.toIso8601String(),
    };

    await _preferencesService.setStringSecure(
        Keys.bitacora, json.encode(bitacoraData));

    // También actualizar en el store y notificar cambios
    store.setBitacora(id, fecha);
  }

  // Método para borrar la bitácora
  Future<void> clearBitacora() async {
    _idBitacora = '';
    _fechaBitacora = DateTime.now();

    await _preferencesService.setStringSecure(Keys.bitacora, '');

    // También actualizar en el store y notificar cambios
    store.setBitacora('', DateTime.now());
  }
}
