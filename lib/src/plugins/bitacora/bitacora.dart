import 'dart:convert';
import 'package:control_ventas_movil/src/constants/keys.dart';
import 'package:control_ventas_movil/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class BitacoraStore with ChangeNotifier {
  BitacoraStore._();
  static final instance = BitacoraStore._();

  Bitacora _bitacora = Bitacora.empty();

  Bitacora get bitacora => _bitacora;

  void setBitacora(String id, DateTime? fecha) {
    _bitacora = Bitacora(id, fecha);
    notifyListeners();
  }
}

class Bitacora {
  final String id;
  final DateTime? fecha;

  Bitacora(this.id, this.fecha);

  factory Bitacora.empty() {
    return Bitacora('', null);
  }

  factory Bitacora.fromJson(Map<String, dynamic> json) {
    return Bitacora(
      json['id'] ?? '',
      json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "fecha": fecha?.toIso8601String(),
    };
  }
}

class BitacoraService {
  static final BitacoraService instance = BitacoraService._();
  BitacoraService._();

  final PreferencesService _preferencesService = PreferencesService.instance;
  final BitacoraStore store = BitacoraStore.instance;

  Future<Bitacora> getBitacora() async {
    try {
      String? data = await _preferencesService.getStringSecure(Keys.bitacora);
      if (data != null && data.isNotEmpty) {
        Map<String, dynamic> bitacoraMap = json.decode(data);
        return Bitacora.fromJson(bitacoraMap);
      }
    } catch (e) {
      debugPrint("Error al obtener bitácora: $e");
    }
    return Bitacora.empty();
  }

  Future<void> updateBitacora(
      {required String id, required DateTime fecha}) async {
    Bitacora nuevaBitacora = Bitacora(id, fecha);

    await _preferencesService.setStringSecure(
        Keys.bitacora, json.encode(nuevaBitacora.toJson()));

    store.setBitacora(id, fecha);
  }

  Future<void> clearBitacora() async {
    await _preferencesService.setStringSecure(Keys.bitacora, '');
    store.setBitacora('', null);
  }
}
