import 'package:camino_seguro/src/config/form_controller.dart';
import 'package:camino_seguro/src/config/routes.dart';
import 'package:camino_seguro/src/plugins/auth/auth.dart';
import 'package:camino_seguro/src/plugins/seguridad/seguridad.dart';
import 'package:camino_seguro/src/plugins/utils/local_secure.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/ui/common/buttons/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/constants/resources.dart';
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
  final auth = Auth.instance;
  final seguridad = Seguridad.instance;

  @override
  void initState() {
    super.initState();
    inicializar();
  }

  void inicializar() async {
    Logger.info('Verificar sesión (solo huella)');
    final context = navigatorKey.currentContext!;

    // tengo huella y esa habilitado
    // tengo huella y no habilitado
    // no tengo huella

    try {
      final hasFingerprint = await seguridad.hasFingeprintEnabled;
      if (await seguridad.hasBiometrics) {
        if (hasFingerprint && context.mounted) {
          final autenticado = await verificarHuella(context);
          if (autenticado && context.mounted) {
            Logger.info('Autenticación por huella exitosa');
            Auth.instance.isLocked = false;
            GoRouter.of(context).goNamed(RouteNames.home);
          }
          return;
        }
        return;
      }
      if (!context.mounted) return;
      Auth.instance.isLocked = false;
      GoRouter.of(context).goNamed(RouteNames.home);
    } catch (e) {
      Logger.error('Error en autenticación biométrica: $e');
    }
  }

  Future<bool> verificarHuella(BuildContext context) async {
    final autenticado = await LocalSecure.autenticar(
      titulo: 'Control de ubicaciones',
      message: 'Escanea tu huella dactilar para continuar',
    );
    Logger.info('Biométrico autenticado: $autenticado');
    return autenticado;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return ScaffoldMessenger(
      key: procesarSesionMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          toolbarHeight: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            fit: BoxFit.contain,
                            image: AssetImage(Recursos.logoPrincipal))),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      SolarIconsBold.lockKeyhole,
                      color: theme.warning,
                      size: 80,
                    ),
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
                    const SizedBox(height: 15),
                  ],
                ),
              ),
              // CircularProgressIndicator(color: theme.accent100),
            ],
          ),
        ),
      ),
    );
  }
}
