import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/seguridad/seguridad.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
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
              icon: SolarIconsOutline.shieldWarning,
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
              child: Column(
            children: <Widget>[
              const SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                    onPressed: logout, icon: const Icon(Icons.close_rounded)),
              ),
              const SizedBox(
                height: 30,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Desbloqueo de la aplicación',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
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
                      leading: Icon(SolarIconsOutline.lightbulbMinimalistic,
                          color: theme.secondary),
                      title: const Text(
                          style: TextStyle(fontSize: 12, height: 1.4),
                          'Utiliza el sensor de huella para desbloquear la aplicación en lugar de ingresar el pin de seguridad.'),
                    )),
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
              // Text(security.store.pin),
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
                          'La seguridad biométrica es gestionada por tu dispositivo, si presenta algún problema se solicitará el pin de seguridad'),
                    )),
              ),
              const SizedBox(
                height: 30,
              ),
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
              )
            ],
          ))),
    );
  }
}
