import 'package:camino_seguro/src/config/routes.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/plugins/auth/auth.dart';
import 'package:camino_seguro/src/plugins/seguridad/seguridad.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:camino_seguro/src/ui/common/buttons/simple_button.dart';
import 'package:camino_seguro/src/ui/common/snackbar/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

GlobalKey<ScaffoldMessengerState> configuracionDesbloqueoMessenger =
    GlobalKey<ScaffoldMessengerState>();

class ConfiguracionDesbloqueo extends StatefulWidget {
  const ConfiguracionDesbloqueo({super.key});

  @override
  State<ConfiguracionDesbloqueo> createState() =>
      _ConfiguracionDesbloqueoState();
}

class _ConfiguracionDesbloqueoState extends State<ConfiguracionDesbloqueo> {
  bool usarSensor = true;

  @override
  void initState() {
    super.initState();
  }

  void logout() {
    final theme = ThemeController.instance;
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: ConfirmationDialog(
              title: 'Alerta',
              icon: SolarIconsOutline.clockCircle,
              color: theme.warning,
              textConfirm: 'Aceptar',
              text: '¿Estás segura(o) de cancelar el inicio de sesión?',
              onConfirm: () async {
                var error = await Auth.instance.logout();
                if (error != null) {
                  showSnackBar(configuracionDesbloqueoMessenger, error,
                      state: StatusSnackBar.error, colorText: theme.white);
                }
              },
            ),
          );
        });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return ScaffoldMessenger(
      key: configuracionDesbloqueoMessenger,
      child: Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            toolbarHeight: 0,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      height: 10,
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Icon(
                        Icons.fingerprint,
                        color: theme.secondary,
                        size: 90,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const Text('Usar el sensor de huella'),
                            Transform.scale(
                              scale: 0.7,
                              child: Switch.adaptive(
                                  activeColor: theme.primary,
                                  activeTrackColor:
                                      theme.primary.withValues(alpha: 0.3),
                                  inactiveThumbColor: theme.grey,
                                  inactiveTrackColor:
                                      theme.grey.withValues(alpha: 0.3),
                                  value: usarSensor,
                                  onChanged: (value) {
                                    Logger.info(
                                        'usar el sensor de huella ? > $value');
                                    setState(() {
                                      usarSensor = value;
                                    });
                                  }),
                            )
                          ],
                        )),
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(SolarIconsOutline.shieldWarning,
                                color: theme.grey),
                            title: const Text(
                                style: TextStyle(fontSize: 12, height: 1.4),
                                'La seguridad biométrica es administrada por tu dispositivo.'),
                          )),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SimpleButton(
                            title: 'Empezar',
                            fullWidth: false,
                            onTap: () {
                              Logger.info('empezar');
                              Seguridad.instance
                                  .loginLocalSecurity(fingerprint: usarSensor);
                              Auth.instance.isLocked = false;
                              GoRouter.of(context).goNamed(RouteNames.home);
                            },
                          ),
                          SimpleButton(
                            title: 'Salir',
                            fullWidth: false,
                            onTap: logout,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
