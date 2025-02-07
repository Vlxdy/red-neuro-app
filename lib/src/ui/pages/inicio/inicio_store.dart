import 'package:flutter/material.dart';

class CodigoPinStore with ChangeNotifier {
  CodigoPinStore._();
  static final instance = CodigoPinStore._();

  
  bool _cargando = false;
  bool get cargando => _cargando;
  set cargando(bool val) {
    _cargando = val;
    notifyListeners();
  }

  List<int> _pin = [0, 0, 0, 0];
  List<int> get pin => _pin;
  set pin(List<int> value) {
    _pin = value;
    notifyListeners();
  }

  String _secret = "";
  String get secret => _secret;
  set secret(String val) {
    _secret = val;
    notifyListeners();
  }

  int _serverTime = 0;
  int get serverTime => _serverTime;
  set serverTime(int val) {
    _serverTime = val;
    notifyListeners();
  }
}
