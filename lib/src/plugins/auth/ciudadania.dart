import 'dart:convert';
import 'dart:io';

import 'package:control_ventas_movil/src/constants/constants.dart';
import 'package:control_ventas_movil/src/constants/keys.dart';
import 'package:control_ventas_movil/src/models/ciudadano.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/plugins/utils/preferences.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_appauth/flutter_appauth.dart';

class CiudadaniaAuth {
  CiudadaniaAuth._();
  static final instance = CiudadaniaAuth._();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final PreferencesService _preferencesService = PreferencesService.instance;

  String _accessToken = '';
  set accessToken(value) => _accessToken = value;

  String _idToken = '';
  set idToken(value) => _idToken = value;

  Future<String> get accessToken async {
    if (_accessToken.isNotEmpty) return _accessToken;
    return await _preferencesService.getString(Keys.ciudadaniaAccessToken);
  }

  Future<String> get idToken async {
    if (_idToken.isNotEmpty) return _idToken;
    return await _preferencesService.getString(Keys.ciudadaniaidToken);
  }

  Future<void> _saveCredentials(String token, String idToken) async {
    await _preferencesService.setStringSecure(Keys.accessToken, token);
    await _preferencesService.setStringSecure(Keys.ciudadaniaidToken, idToken);
    _accessToken = token;
    _idToken = idToken;
  }

  Future<void> _clearCredentials() async {
    await _preferencesService.setStringSecure(Keys.ciudadaniaAccessToken, '');
    await _preferencesService.setStringSecure(Keys.ciudadaniaidToken, '');
    _accessToken = '';
    _idToken = '';
  }

  Future<bool> signInWithCodeExchange() async {
    try {
      final AuthorizationServiceConfiguration serviceConfiguration =
          AuthorizationServiceConfiguration(
        authorizationEndpoint: '${Constantes.oidcIssuer}/auth',
        tokenEndpoint: '${Constantes.oidcIssuer}/token',
        endSessionEndpoint: '${Constantes.oidcIssuer}/session/end',
      );

      // bool preferEphemeralSession = true;
      final AuthorizationTokenResponse resultadoAuth =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          serviceConfiguration: serviceConfiguration,
          scopes: _scopes,
          promptValues: Platform.isAndroid ? ['consent', 'login'] : ['consent'],
          discoveryUrl:
              '${Constantes.oidcIssuer}/.well-known/openid-configuration',
          allowInsecureConnections: true,
        ),
      );
      Logger.info(
          "Resultado provider - accessToken > ${resultadoAuth.accessToken}");
      Logger.info(
          "Resultado provider - authorizationAdditionalParameters > ${resultadoAuth.authorizationAdditionalParameters}");
      Logger.info(
          "Resultado provider - accessTokenExpirationDateTime > ${resultadoAuth.accessTokenExpirationDateTime}");

      if (resultadoAuth.accessToken != null && resultadoAuth.idToken != null) {
        await _saveCredentials(
            resultadoAuth.accessToken!, resultadoAuth.idToken!);
        return true;
      }
      return false;
    } catch (err) {
      Logger.error('Error al obtener credenciales..... ${err.toString()}');
      return false;
    }
  }

  Future<Ciudadano>? getUser(String accessToken) async {
    Uri uri = Uri.parse("${Constantes.oidcIssuer}/me");
    // Uri uri = Uri.https(Constantes.oidcIssuer, '/me');
    Logger.info("uri > $uri");
    final http.Response response = await http.get(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      final decode = jsonDecode(response.body);
      Logger.info("decode responsse me > $decode");
      final Ciudadano ciudadano = Ciudadano.fromJson(decode);
      Logger.info(ciudadano.toString());
      return ciudadano;
      // final Map<String, dynamic> dataPersona = {
      //   "numero_documento": decode['profile']['documento_identidad']
      //       ['numero_documento'],
      //   "fecha_nacimiento": decode['fecha_nacimiento'],
      //   "celular": decode['celular']
      // };
      // return dataPersona;
    } else {
      throw Exception('Failed to get user details');
    }
  }

  Future<bool> cerrarSesion() async {
    Logger.sesion('Cerrando sesión con ciudadania');
    try {
      final AuthorizationServiceConfiguration serviceConfiguration =
          AuthorizationServiceConfiguration(
              authorizationEndpoint: "${Constantes.oidcIssuer}/auth",
              endSessionEndpoint: "${Constantes.oidcIssuer}/session/end",
              tokenEndpoint: "${Constantes.oidcIssuer}/token");

      String token = await idToken;

      await _appAuth.endSession(EndSessionRequest(
          idTokenHint: token,
          postLogoutRedirectUrl: Constantes.oidcRedirectUri,
          discoveryUrl:
              '${Constantes.oidcIssuer}/.well-known/openid-configuration',
          // preferEphemeralSession: true,
          serviceConfiguration: serviceConfiguration));
      await _clearCredentials();
      return true;
    } catch (error) {
      //TODO: verificar con ciudadania o libreria

      Logger.error("error al cerrar sesión 🔒: $error");
      return false;
    }
  }

  // --------------------------------------------------------
  //Datos de Configuración
  final String _clientId = Constantes.oidcClientId;
  final String _redirectUrl = Constantes.oidcRedirectUri;

  final List<String> _scopes = <String>[
    'openid',
    'profile',
    'fecha_nacimiento',
    'email',
    'celular',
    'offline_access'
  ];
}
