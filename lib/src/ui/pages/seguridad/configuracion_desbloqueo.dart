import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/seguridad/seguridad.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
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
  bool usarSeguridadDispositivo = true;

  @override
  void initState() {
    super.initState();
  }

  void logout() {
    final ThemeController theme = ThemeController.instance;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ConfirmationDialog(
            title: 'Alerta',
            icon: SolarIconsOutline.clockCircle,
            color: theme.warning,
            textConfirm: 'Aceptar',
            text: '¿Estás segura(o) de cancelar el inicio de sesión?',
            onConfirm: () async {
              String? error = await Auth.instance.logout();
              if (error != null) {
                showSnackBar(
                  configuracionDesbloqueoMessenger,
                  error,
                  state: StatusSnackBar.error,
                  colorText: theme.white,
                );
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    return ScaffoldMessenger(
      key: configuracionDesbloqueoMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(toolbarHeight: 0),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 10),
                  const SizedBox(height: 30),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Icon(
                      Icons.shield_outlined,
                      color: theme.secondary,
                      size: 90,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        const Text('Usar seguridad del dispositivo'),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch.adaptive(
                            activeThumbColor: theme.primary,
                            activeTrackColor: theme.primary.withValues(
                              alpha: 0.3,
                            ),
                            inactiveThumbColor: theme.grey,
                            inactiveTrackColor: theme.grey.withValues(
                              alpha: 0.3,
                            ),
                            value: usarSeguridadDispositivo,
                            onChanged: (bool value) {
                              Logger.info(
                                'usar seguridad del dispositivo ? > $value',
                              );
                              setState(() {
                                usarSeguridadDispositivo = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(
                          SolarIconsOutline.shieldWarning,
                          color: theme.grey,
                        ),
                        title: const Text(
                          style: TextStyle(fontSize: 12, height: 1.4),
                          'Puedes desbloquear con el método de verificación que tengas configurado en tu dispositivo.',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        SimpleButton(
                          title: 'Empezar',
                          fullWidth: false,
                          onTap: () {
                            Logger.info('empezar');
                            Seguridad.instance.loginLocalSecurity(
                              fingerprint: usarSeguridadDispositivo,
                            );
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
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
