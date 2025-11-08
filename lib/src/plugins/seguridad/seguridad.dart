import 'package:alimenta_app/src/constants/keys.dart';
import 'package:alimenta_app/src/plugins/utils/local_secure.dart';
import 'package:alimenta_app/src/plugins/utils/preferences.dart';
import 'package:flutter/material.dart';

class SeguridadStore with ChangeNotifier {
  SeguridadStore._();
  static final instance = SeguridadStore._();

  String _pin = '';

  String get pin => _pin;
  set pin(String value) {
    _pin = value;
    notifyListeners();
  }
}

class Seguridad {
  String _pinSeguridad = '';
  bool _fingerprintActive = false;

  Seguridad._();
  static final instance = Seguridad._();

  final store = SeguridadStore.instance;
  final PreferencesService _preferencesService = PreferencesService.instance;

  Future<void> loginLocalSecurity({required bool fingerprint}) async {
    await _preferencesService.setStringSecure(Keys.pinSeguridad, store.pin);
    _pinSeguridad = store.pin;
    await _preferencesService.setBool(Keys.fingerprintActivo, fingerprint);
    _fingerprintActive = fingerprint;
  }

  Future<void> updateSecurityPin(String value) async {
    await _preferencesService.setStringSecure(Keys.pinSeguridad, value);
    _pinSeguridad = value;
  }

  Future<void> updateFingeprint(bool value) async {
    await _preferencesService.setBool(Keys.fingerprintActivo, value);
    _fingerprintActive = value;
  }

  Future<void> clearLocalSecurity() async {
    await _preferencesService.setStringSecure(Keys.pinSeguridad, '');
    _pinSeguridad = '';
  }

  Future<String> get apiPinSeguridad async {
    try {
      if (_pinSeguridad.isEmpty) {
        _pinSeguridad =
            await _preferencesService.getStringSecure(Keys.pinSeguridad);
      }
      return _pinSeguridad;
    } catch (e) {
      return '';
    }
  }

  Future<bool> get apiFingerprint async {
    try {
      if (!_fingerprintActive) {
        _fingerprintActive =
            await _preferencesService.getBool(Keys.fingerprintActivo);
      }
      return _fingerprintActive;
    } catch (e) {
      return false;
    }
  }

  Future<bool> get hasSecurityPin async {
    final pin = await apiPinSeguridad;
    return pin.isNotEmpty;
  }

  Future<bool> get hasFingeprintEnabled async {
    return await apiFingerprint;
  }

  Future<bool> get hasBiometrics async {
    final biometricoDisponible = await LocalSecure.getAvailableBiometrics();
    return biometricoDisponible.isNotEmpty;
  }
}
