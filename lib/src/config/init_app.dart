// ignore: depend_on_referenced_packages
import 'package:camino_seguro/src/config/routes.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/plugins/auth/auth.dart';
import 'package:camino_seguro/src/plugins/seguridad/seguridad.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/sockets/sockets_provider.dart';
import 'package:camino_seguro/src/ui/pages/areas/services/areas_service.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/services/dependientes.dart';
import 'package:go_router/go_router.dart';

class InitAppController {
  InitAppController._();

  static InitAppController instance = InitAppController._();
  final auth = Auth.instance;
  final security = Seguridad.instance;
  late AreasService areaService;
  late DependientesService dependientesService;
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
    dependientesService = DependientesService('', context);
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
    await dependientesService.fetchData().whenComplete(() {
      Logger.info('Dependientes traidos');
    });

    final idUsuario = await Auth.instance.idUsuario;
    if (idUsuario != null) {
      await socketProvider.init(idUsuario, context);
    } else {
      Logger.error('idUsuario is null');
    }
    if (!context.mounted) return;
    GoRouter.of(context).goNamed(RouteNames.procesarSesion);
  }
}
