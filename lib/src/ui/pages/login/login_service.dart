import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/service_config.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/keys.dart';
import 'package:control_ventas_movil/src/constants/network.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/auth/ciudadania.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';
import 'package:control_ventas_movil/src/ui/pages/login/componentes/login_account_page.dart';
import 'package:control_ventas_movil/src/ui/pages/login/login_store.dart';
import 'package:control_ventas_movil/src/ui/pages/recuperar_contrasena/recuperar_contrasena.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginService extends ServiceConfig {
  LoginService(super.urlBase, super.context);

  final store = LoginStore.instance;
  final theme = ThemeController.instance;
  final ciudadania = CiudadaniaAuth.instance;

  void loginCiudadania() async {
    LoadingAnimation.instance.showLoading(mensaje: 'Procesando sesión...');
    try {
      final response = await ciudadania.signInWithCodeExchange();
      if (response) {
        final accessToken = await ciudadania.accessToken;
        final response = await fetch('/auth/cid-app',
            type: HttpProtocol.post,
            withAuthorization: false,
            body: {
              "accessToken": accessToken,
            });
        if (response.status != StatusNetwork.connected) {
          throw ErrorDescription(response.message);
        }
        Logger.info("respuesta login ciudadania > ${response.data}");
        final accessTokenAuth = response.data['access_token'];
        final refreshTokenAuth = response.data['refreshToken'];
        final responsePerfil = await fetch(
          '/usuarios/cuenta/perfil',
          type: HttpProtocol.get,
          customToken: accessTokenAuth,
        );
        Logger.info("respuesta perfil lince > ${responsePerfil.data}");
        final respuestaPerfil = responsePerfil.data;
        await Auth.instance.login({
          "ciudadania_digital": respuestaPerfil['ciudadaniaDigital'],
          "correoElectronico": respuestaPerfil['correoElectronico'],
          "celular": respuestaPerfil['persona']['telefono'],
          "estado": respuestaPerfil['estado'],
          "id": respuestaPerfil['id'],
          "usuario": respuestaPerfil['usuario'],
          "persona": {
            "fechaNacimiento": respuestaPerfil['persona']['fechaNacimiento'],
            "nombres": respuestaPerfil['persona']['nombres'],
            "nroDocumento": respuestaPerfil['persona']['nroDocumento'],
            "primerApellido": respuestaPerfil['persona']['primerApellido'],
            "segundoApellido": respuestaPerfil['persona']['segundoApellido'],
            "tipoDocumento": respuestaPerfil['persona']['tipoDocumento'],
          },
          Keys.accessToken: accessTokenAuth,
          Keys.refreshToken: refreshTokenAuth,
        });

        if (context.mounted) {
          context.goNamed(RouteNames.splashScreen);
        }
        store.clean();
      }
    } catch (e, stacktrace) {
      Logger.error('Ocurrió un error -> $e');
      Logger.error('stacktrace $stacktrace');
      showSnackBar(loginAccountMessenger, '$e',
          state: StatusSnackBar.error, colorText: theme.white);
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  void login() async {
    try {
      LoadingAnimation.instance.showLoading();
      final response = await fetch('/auth-app-control',
          type: HttpProtocol.post,
          body: store.form.toJson(),
          withAuthorization: false);
      Logger.success('login -> ${response.data}');
      if (response.status != StatusNetwork.connected) {
        showSnackBar(loginAccountMessenger, response.message,
            state: StatusSnackBar.error, colorText: theme.white);
        return;
      } else {
        // Logger.warning('respuesta ${response.data}');
        await Auth.instance.login(response.data);

        if (context.mounted) {
          context.goNamed(RouteNames.controlScreen);
          // context.goNamed(RouteNames.splashScreen);
        }
        store.clean();
      }
    } catch (e, stacktrace) {
      Logger.error('Ocurrió un error -> $e');
      Logger.error('stacktrace $stacktrace');
      showSnackBar(loginAccountMessenger, '$e',
          state: StatusSnackBar.error, colorText: theme.white);
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> recuperarCuenta(String email, String mensajeCorrecto) async {
    final theme = ThemeController.instance;
    try {
      final response = await fetch('/usuarios/recuperar',
          type: HttpProtocol.post, body: {'correoElectronico': email});

      if (response.status != StatusNetwork.connected) {
        showSnackBar(olvideContrasenaMessenger, response.message,
            state: StatusSnackBar.error, colorText: theme.white);
      } else {
        showSnackBar(olvideContrasenaMessenger, mensajeCorrecto,
            state: StatusSnackBar.success, colorText: theme.white);
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al recuperar cuenta $e');
      Logger.error('stacktrace $stacktrace');
    }
  }
}
