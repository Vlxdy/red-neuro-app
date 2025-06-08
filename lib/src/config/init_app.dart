// ignore: depend_on_referenced_packages
import 'package:camino_seguro/src/config/routes.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/constants/keys.dart';
import 'package:camino_seguro/src/plugins/auth/auth.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/plugins/utils/preferences.dart';
import 'package:camino_seguro/src/ui/pages/areas/services/areas_service.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/services/dependientes.dart';
import 'package:go_router/go_router.dart';

class InitAppController {
  InitAppController._();

  static InitAppController instance = InitAppController._();
  final auth = Auth.instance;
  final PreferencesService _preferencesService = PreferencesService.instance;
  late AreasService areaService;
  late DependientesService dependientesService;

  Future<void> initTheme() async {
    await ThemeController.instance.initTheme();
  }

  Future<void> initApp() async {
    final context = navigatorKey.currentState!.context;
    final token = await auth.apiToken;

    if (!context.mounted) return;
    areaService = AreasService('', context);
    dependientesService = DependientesService('', context);

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
    await areaService.fetchData().whenComplete(() {
      Logger.info('Areas traidas');
    });
    await dependientesService.fetchData().whenComplete(() {
      Logger.info('Dependientes traidos');
    });
    final fingerprintActivo =
        await _preferencesService.getStringSecure(Keys.fingerprintActivo);

    if (!context.mounted) return;
    if (fingerprintActivo.isEmpty) {
      GoRouter.of(context).goNamed(RouteNames.configurarDesbloqueo);
      return;
    }
    GoRouter.of(context).goNamed(RouteNames.procesarSesion);
  }
}
