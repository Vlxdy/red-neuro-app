import 'package:control_ventas_movil/src/config/providers.dart';
import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/keys.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/preferences.dart';
import 'package:go_router/go_router.dart';

class InitAppController {
  InitAppController._();

  static InitAppController instance = InitAppController._();
  final auth = Auth.instance;
  final PreferencesService _preferencesService = PreferencesService.instance;

  Future<void> initTheme() async {
    await ThemeController.instance.initTheme();
  }

  Future<void> initApp() async {
    final context = navigatorKey.currentState!.context;
    final token = await auth.apiToken;
    await auth.updateAppInfo();
    await auth.validateFirstTime();

    if (token.isEmpty) {
      await auth.logout();
      if (context.mounted) {
        GoRouter.of(context).goNamed(RouteNames.loginAccount);
      }
      return;
    }

    await auth.loginSuccess();
    resetProviders(); // Reset valores mas importantes de providers
    final pinSeguridad =
        await _preferencesService.getStringSecure(Keys.pinSeguridad);

    if (!context.mounted) return;

    if (pinSeguridad.isEmpty) {
      GoRouter.of(context).goNamed(RouteNames.configurarPinSeguridad);
      return;
    }
    GoRouter.of(context).goNamed(RouteNames.home);
  }
}
