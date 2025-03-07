import 'dart:convert';

import 'package:control_ventas_movil/src/constants/constants.dart';
import 'package:control_ventas_movil/src/models/combustible.dart';
import 'package:control_ventas_movil/src/plugins/auth/ciudadania.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/bitacora_store.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/combustibles_store.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/estacion_servicio.dart';
import 'package:control_ventas_movil/src/plugins/estaciones/regimiento_store.dart';
import 'package:control_ventas_movil/src/plugins/seguridad/seguridad.dart';
import 'package:control_ventas_movil/src/plugins/utils/connection.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/constants/keys.dart';
import 'package:control_ventas_movil/src/models/user.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/plugins/utils/preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AuthStore with ChangeNotifier {
  AuthStore._();
  static final instance = AuthStore._();

  final _isLogged = ValueNotifier<bool>(false);

  bool get isLogged => _isLogged.value;
  set isLogged(bool value) {
    _isLogged.value = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _isLogged.removeListener(notifyListeners);
    super.dispose();
  }
}

class Auth {
  Usuario _user = Usuario.empty;
  String _token = '';
  String _refreshToken = '';

  Auth._();
  static final instance = Auth._();

  final _store = AuthStore.instance;
  final seguridad = Seguridad.instance;
  final regimiento = RegimientoStore.instance;
  final estacionServicio = EstacionServicioStore.instance;
  final bitacora = BitacoraStore.instance;
  final combustibles = CombustiblesStore.instance;
  PackageInfo _info = PackageInfo(
      appName: '',
      buildNumber: '',
      packageName: '',
      version: '',
      buildSignature: '',
      installerStore: '');

  bool _firstTime = false;
  bool _localAuth = false;
  bool isLocked = true;

  final PreferencesService _preferencesService = PreferencesService.instance;
  final ciudadania = CiudadaniaAuth.instance;

  Future<void> login(Map<String, dynamic> json) async {
    final user = Usuario.fromJson(json);
    final String token = json[Keys.accessToken] ?? '';
    final String refreshToken = json[Keys.refreshToken] ?? '';

    if (token.isNotEmpty) {
      await _preferencesService.setStringSecure(
          Keys.accessToken, jsonEncode(token.replaceAll('"', '')));
      _token = token;
    }

    await _preferencesService.setString(
        Keys.profile, jsonEncode(user.toJson()));
    _user = user;

    Logger.sesion(_user.toJson().toString());

    if (refreshToken.isNotEmpty) {
      await _preferencesService.setStringSecure(
          Keys.refreshToken, jsonEncode(refreshToken.replaceAll('"', '')));
      _refreshToken = refreshToken;
    }

    _store.isLogged = true;
  }

  Future<void> updateUser(Usuario user) async {
    await _preferencesService.setString(
        Keys.profile, jsonEncode(user.toJson()));
    _user = user;
  }

  Future<String?> logout() async {
    try {
      //TODO: add logout methods for providers
      await ciudadania.cerrarSesion();
      await clearCredentials();
      // await clearLocalSecurity()
      await seguridad.clearLocalSecurity();
      _store.isLogged = false;
    } catch (e) {
      Logger.error(e.toString());
    }
    return null;
  }

  Future<void> _actualizarSesion() async {
    Logger.sesion('Rotacion de token');
    final refreshT = await refreshToken;
    final Map<String, dynamic> body = {
      'jid': refreshT.replaceAll('"', ''),
      'token': _token.replaceAll('"', '')
    };
    Logger.info('Ejecutando>>>> ${Constantes.apiUrl}/token-app, body: $body');
    final response = await http.post(
        Uri.parse('${Constantes.apiUrl}/token-app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    if (response.statusCode == 200) {
      Logger.sesion('Rotacion de token exitosa');
      final decode = jsonDecode(response.body);
      await login(decode['datos']);
    } else {
      Logger.sesion('Rotacion de token fallida - ${response.statusCode}');
      await logout();
    }
  }

  Future<void> loginSuccess() async {
    _user = await profileAsync();
    _store.isLogged = true;
    await regimiento.regimientoAsync();
    await bitacora.bitacoraAsync();
    await estacionServicio.estacionServicioAsync();
    await combustibles.combustiblesAsync();
  }

  Future<void> clearCredentials() async {
    await _preferencesService.setStringSecure(Keys.accessToken, '');
    await _preferencesService.setStringSecure(Keys.refreshToken, '');
    await _preferencesService.setString(Keys.profile, '');
    _token = '';
  }

  Future<String> get apiToken async {
    try {
      if (_token.isEmpty) {
        _token = await _preferencesService.getStringSecure(Keys.accessToken);
      }
      var hasInternet = await Connection.hasInternetConnected();
      if (_token.isNotEmpty && hasInternet) {
        if (JwtDecoder.isExpired(_token)) {
          Logger.error('> token expirado');
          await _actualizarSesion();
        }
      }
      return _token;
    } catch (e) {
      return '';
    }
  }

  Future<String> get refreshToken async {
    if (_refreshToken.isNotEmpty) return _refreshToken;
    return await _preferencesService.getStringSecure(Keys.refreshToken);
  }

  Usuario get profile => _user;
  Future<String?> get idUsuario async => (await profileAsync()).id;

  Future<Usuario> profileAsync() async {
    if (_user.correoElectronico.isNotEmpty) return _user;
    Usuario user = Usuario.empty;
    try {
      final decode = await _preferencesService.getString(Keys.profile);
      if (decode.isNotEmpty) {
        user = Usuario.fromJson(jsonDecode(decode));
      }
    } catch (e, stacktrace) {
      Logger.error('exception user -> ${e.toString()}');
      Logger.error('stacktrace $stacktrace');
    }
    return user;
  }

  // ------------------ sesion -------------
  Future<bool> get hasSesion async {
    final token = await apiToken;
    return token.isNotEmpty;
  }

  // ---------------------- info app
  Future<void> updateAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _info = packageInfo;
  }

  PackageInfo get appInfo => _info;

  Future<void> validateFirstTime() async {
    final value = await _preferencesService.getBool(Keys.firstTime);
    _firstTime = value;
  }

  Future<void> updateFirstTime() async {
    await _preferencesService.setBool(Keys.firstTime, false);
    _firstTime = false;
  }

  bool get firstTime => _firstTime;

  // -------------------------------
  bool get localAuth => _localAuth;
  set localAuth(bool value) {
    _localAuth = value;
  }
}
