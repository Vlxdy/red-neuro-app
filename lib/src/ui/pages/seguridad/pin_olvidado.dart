import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

GlobalKey<ScaffoldMessengerState> pinOlvidadoMessenger =
    GlobalKey<ScaffoldMessengerState>();

class PinOlvidado extends StatefulWidget {
  const PinOlvidado({super.key});

  @override
  State<PinOlvidado> createState() => _PinOlvidadoState();
}

class _PinOlvidadoState extends State<PinOlvidado> {
  void logout() {
    final theme = ThemeController.instance;
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: ConfirmationDialog(
              title: 'Cerrar sesión',
              onConfirm: () async {
                var error = await Auth.instance.logout();
                if (error != null) {
                  showSnackBar(pinOlvidadoMessenger, error,
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
      key: pinOlvidadoMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          toolbarHeight: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.clear),
                    )
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  '¿No recuerdas tu pin?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(
                  height: 40,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const ListTile(
                      leading: Icon(SolarIconsOutline.shieldWarning),
                      title: Text(
                        'Si cambiaste el pin de seguridad y no lo recuerdas, tendrás que cerrar sesión y volver a ingresar para configurar un nuevo pin de seguridad.',
                        style: TextStyle(fontSize: 12, height: 1.2),
                      )),
                ),
                const SizedBox(
                  height: 40,
                ),
                SimpleButton(
                  outlined: true,
                  fullWidth: false,
                  background: theme.error,
                  preffixicon: SolarIconsOutline.logout_3,
                  title: 'Cerrar sesión',
                  onTap: logout,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
