// ignore: depend_on_referenced_packages
import 'package:alimenta_app/src/config/routes.dart';
import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:alimenta_app/src/plugins/seguridad/seguridad.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:alimenta_app/src/sockets/sockets_provider.dart';
import 'package:alimenta_app/src/ui/pages/areas/services/areas_service.dart';
import 'package:go_router/go_router.dart';

class InitAppController {
  InitAppController._();

  static InitAppController instance = InitAppController._();
  final auth = Auth.instance;
  final security = Seguridad.instance;
  late AreasService areaService;
  late SocketProvider socketProvider;

  // final socketService = SocketService();

  Future<void> initTheme() async {
    await ThemeController.instance.initTheme();
  }

  Future<void> initApp() async {
    final context = navigatorKey.currentState!.context;
    final token = await auth.apiToken;

    if (!context.mounted) return;
    areaService = AreasService('', context);
    socketProvider = SocketProvider();

    await auth.updateAppInfo();
    await auth.validateFirstTime();
    await Auth.instance.registrarTokenFCM();

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

    if (!context.mounted) return;
    GoRouter.of(context).goNamed(RouteNames.procesarSesion);
  }
}
