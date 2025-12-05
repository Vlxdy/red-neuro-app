import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/global/loading_animation.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/login_account_page.dart';
import 'package:red_neuro_app/src/ui/pages/login/login_store.dart';
import 'package:red_neuro_app/src/ui/pages/recuperar_contrasena/recuperar_contrasena.dart';
import 'package:go_router/go_router.dart';

class LoginService extends ServiceConfig {
  LoginService(super.urlBase, super.context);

  final LoginStore store = LoginStore.instance;
  final ThemeController theme = ThemeController.instance;

  void login() async {
    try {
      LoadingAnimation.instance.showLoading();
      Logger.info("////////////////////////////////////_Iniciar sesion");
      final ResponseApi response = await fetch(
        '/auth',
        type: HttpProtocol.post,
        body: store.form.toJson(),
        withAuthorization: false,
      );
      Logger.success('login -> ${response.data}');
      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          loginAccountMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
        return;
      } else {
        Logger.warning('respuesta ${response.data}');
        await Auth.instance.login(response.data);

        if (context.mounted) {
          // context.goNamed(RouteNames.controlScreen);
          context.goNamed(RouteNames.splashScreen);
        }
        store.clean();
      }
    } catch (e, stacktrace) {
      Logger.error('Ocurrió un error -> $e');
      Logger.error('stacktrace $stacktrace');

      showSnackBar(
        loginAccountMessenger,
        '$e',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> recuperarCuenta(String email, String mensajeCorrecto) async {
    final ThemeController theme = ThemeController.instance;
    try {
      final ResponseApi response = await fetch(
        '/usuarios/recuperar',
        type: HttpProtocol.post,
        body: <String, String>{'correoElectronico': email},
      );

      if (response.status != StatusNetwork.connected) {
        showSnackBar(
          olvideContrasenaMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
      } else {
        showSnackBar(
          olvideContrasenaMessenger,
          mensajeCorrecto,
          state: StatusSnackBar.success,
          colorText: theme.white,
        );
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al recuperar cuenta $e');
      Logger.error('stacktrace $stacktrace');
    }
  }
}
