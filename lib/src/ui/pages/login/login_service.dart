import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/global/loading_animation.dart';
import 'package:red_neuro_app/src/ui/pages/login/login_store.dart';
import 'package:red_neuro_app/src/ui/pages/recuperar_contrasena/recuperar_contrasena.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:go_router/go_router.dart';

class LoginService extends ServiceConfig {
  LoginService(super.urlBase, super.context);

  final LoginStore store = LoginStore.instance;

  void login() async {
    try {
      store.clearFeedback();
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
        store.setFeedback(response.message);
        return;
      } else {
        Logger.warning('respuesta ${response.data}');
        await Auth.instance.login(response.data);

        if (context.mounted) {
          context.goNamed(RouteNames.splashScreen);
        }
        store.clean();
      }
    } catch (e, stacktrace) {
      Logger.error('Ocurrió un error -> $e');
      Logger.error('stacktrace $stacktrace');
      store.setFeedback('$e');
    } finally {
      LoadingAnimation.instance.hideLoading();
    }
  }

  Future<void> recuperarCuenta(String email, String mensajeCorrecto) async {
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
        );
      } else {
        showSnackBar(
          olvideContrasenaMessenger,
          mensajeCorrecto,
          state: StatusSnackBar.success,
        );
      }
    } catch (e, stacktrace) {
      Logger.error('Exception al recuperar cuenta $e');
      Logger.error('stacktrace $stacktrace');
    }
  }
}
