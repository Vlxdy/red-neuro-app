import 'dart:convert';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/plugins/seguridad/seguridad.dart';
import 'package:red_neuro_app/src/plugins/utils/connection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/constants/keys.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/plugins/utils/preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  Usuario _user = Usuario.empty();
  String _token = '';
  String _refreshToken = '';

  final ValueNotifier<Usuario> _profileNotifier = ValueNotifier<Usuario>(
    Usuario.empty(),
  );

  Auth._();
  static final instance = Auth._();

  final _store = AuthStore.instance;
  final seguridad = Seguridad.instance;
  PackageInfo _info = PackageInfo(
    appName: '',
    buildNumber: '',
    packageName: '',
    version: '',
    buildSignature: '',
    installerStore: '',
  );

  bool _firstTime = false;
  bool _localAuth = false;
  bool isLocked = true;

  final PreferencesService _preferencesService = PreferencesService.instance;

  Future<void> login(Map<String, dynamic> json) async {
    final user = Usuario.fromJson(json);
    final String token =
        json[Keys.accessToken] ?? json['accessToken'] ?? json['token'] ?? '';
    final String refreshToken =
        json[Keys.refreshToken] ?? json['refreshToken'] ?? '';

    if (token.isNotEmpty) {
      await _preferencesService.setStringSecure(
        Keys.accessToken,
        jsonEncode(token.replaceAll('"', '')),
      );
      _token = token;
    }

    await _preferencesService.setString(
      Keys.profile,
      jsonEncode(user.toJson()),
    );
    _user = user;
    _profileNotifier.value = user;

    Logger.sesion(_user.toJson().toString());

    if (refreshToken.isNotEmpty) {
      await _preferencesService.setStringSecure(
        Keys.refreshToken,
        jsonEncode(refreshToken.replaceAll('"', '')),
      );
      _refreshToken = refreshToken;
    }

    _store.isLogged = true;

    // 🔹 Registra el token FCM una vez autenticado
    // await _registrarTokenFCM();
  }

  Future<void> updateUser(Usuario user) async {
    await _preferencesService.setString(
      Keys.profile,
      jsonEncode(user.toJson()),
    );
    _user = user;
    _profileNotifier.value = user;
  }

  Future<String?> logout() async {
    try {
      await clearCredentials();
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
      'token': _token.replaceAll('"', ''),
    };
    Logger.info('Ejecutando>>>> ${Constantes.apiUrl}/token-app, body: $body');
    final response = await http.post(
      Uri.parse('${Constantes.apiUrl}/token-app'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
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
  }

  Future<void> clearCredentials() async {
    await _preferencesService.setStringSecure(Keys.accessToken, '');
    await _preferencesService.setStringSecure(Keys.refreshToken, '');
    await _preferencesService.setString(Keys.profile, '');
    _token = '';
    _user = Usuario.empty();
    _profileNotifier.value = _user;
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
    Usuario user = Usuario.empty();
    try {
      final decode = await _preferencesService.getString(Keys.profile);
      if (decode.isNotEmpty) {
        user = Usuario.fromJson(jsonDecode(decode));
      }
    } catch (e, stacktrace) {
      Logger.error('exception user -> ${e.toString()}');
      Logger.error('stacktrace $stacktrace');
    }
    _user = user;
    return user;
  }

  ValueListenable<Usuario> get profileListenable => _profileNotifier;

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

  Future<void> registrarTokenFCM() async {
    try {
      Logger.info("🔐 Verificando inicialización de Firebase...");
      await Firebase.initializeApp(); // 🔹 Asegura la inicialización

      Logger.info("🔐 Solicitando permisos FCM...");
      await FirebaseMessaging.instance.requestPermission();

      final tokenFCM = await FirebaseMessaging.instance.getToken();
      Logger.info("📱 Token FCM obtenido: $tokenFCM");

      if (tokenFCM != null && tokenFCM.isNotEmpty) {
        final userId = await idUsuario;
        Logger.info("🧾 ID Usuario: $userId");

        final url = '${Constantes.apiUrl}/notificaciones/registrar-token';
        Logger.info("📡 Enviando token a $url");

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await apiToken}',
          },
          body: jsonEncode({'token': tokenFCM, 'idUsuario': userId}),
        );

        Logger.info("✅ Token enviado. Status: ${response.statusCode}");
        Logger.info("🧾 Respuesta: ${response.body}");
      } else {
        Logger.error("❌ Token FCM vacío o null.");
      }
    } catch (e, stacktrace) {
      Logger.error("❌ Error registrando token FCM: $e");
      Logger.error("📌 Stacktrace:\n$stacktrace");
    }
  }
}
