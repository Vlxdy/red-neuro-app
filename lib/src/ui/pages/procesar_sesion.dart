import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/seguridad/seguridad.dart';
import 'package:red_neuro_app/src/plugins/utils/local_secure.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/sockets/sockets_provider.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/resources.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

GlobalKey<ScaffoldMessengerState> procesarSesionMessenger =
    GlobalKey<ScaffoldMessengerState>();

class ProcesarSesion extends StatefulWidget {
  const ProcesarSesion({super.key});

  @override
  State<ProcesarSesion> createState() => _ProcesarSesionState();
}

class _ProcesarSesionState extends State<ProcesarSesion> with FormController {
  final Auth auth = Auth.instance;
  final Seguridad seguridad = Seguridad.instance;
  late SocketProvider socketProvider;

  @override
  void initState() {
    super.initState();
    inicializar();
    socketProvider = SocketProvider();
  }

  void inicializar() async {
    Logger.info('Verificar sesión con seguridad del dispositivo');

    BuildContext? ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    try {
      final bool hasFingerprintEnabled = await seguridad.hasFingeprintEnabled;

      ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;

      final bool hasDeviceSecurity = await seguridad.hasDeviceSecurity;

      ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;

      // Si NO hay seguridad del dispositivo, entra directo
      if (!hasDeviceSecurity) {
        await _inicializarSocketUsuario();
        Auth.instance.isLocked = false;
        GoRouter.of(ctx).goNamed(RouteNames.home);
        return;
      }

      // Si existe seguridad del dispositivo, pero NO está habilitada en app, entra directo
      if (!hasFingerprintEnabled) {
        await _inicializarSocketUsuario();
        Auth.instance.isLocked = false;
        GoRouter.of(ctx).goNamed(RouteNames.home);
        return;
      }

      // Hay seguridad del dispositivo y está habilitada -> pedir autenticación
      final bool autenticado = await verificarSeguridadDelDispositivo(ctx);

      ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;

      if (!autenticado) return;

      await _inicializarSocketUsuario();

      ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;

      Logger.info('Autenticación del dispositivo exitosa');
      Auth.instance.isLocked = false;
      GoRouter.of(ctx).goNamed(RouteNames.home);
    } catch (e, st) {
      Logger.error('Error en autenticación del dispositivo: $e\n$st');
    }
  }

  Future<void> _inicializarSocketUsuario() async {
    final String? idUsuario = Auth.instance.profile.id;
    if (idUsuario == null || idUsuario.isEmpty) return;
    await socketProvider.init(idUsuario);
  }

  Future<bool> verificarSeguridadDelDispositivo(BuildContext context) async {
    final bool autenticado = await LocalSecure.autenticar(
      titulo: 'Control de ubicaciones',
      message: 'Desbloquea con el método de verificación configurado en tu dispositivo',
      biometricOnly: false,
    );
    Logger.info('Seguridad del dispositivo autenticada: $autenticado');
    return autenticado;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    return ScaffoldMessenger(
      key: procesarSesionMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(toolbarHeight: 0),
        body: Container(
          decoration: const BoxDecoration(),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.contain,
                    image: AssetImage(
                      Recursos.logoPrincipalFor(isDark: theme.isDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Icon(SolarIconsBold.lockKeyhole, color: theme.warning, size: 80),
              const SizedBox(height: 15),
              SimpleButton(
                fullWidth: false,
                customPreffixicon: Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: Icon(
                    SolarIconsBold.lockKeyhole,
                    size: 15,
                    color: theme.white,
                  ),
                ),
                onTap: () {
                  Logger.info('desbloquear');
                  inicializar();
                },
                title: 'Desbloquear',
              ),
            ],
          ),
        ),
        // CircularProgressIndicator(color: theme.accent100),
      ),
    );
  }
}
