import 'package:alimenta_app/src/config/routes.dart';
import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:alimenta_app/src/plugins/seguridad/seguridad.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:alimenta_app/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:alimenta_app/src/ui/common/buttons/simple_button.dart';
import 'package:alimenta_app/src/ui/common/snackbar/snackbar.dart';
import 'package:alimenta_app/src/ui/common/text_inputs/text_input.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:alimenta_app/src/config/form_controller.dart';

GlobalKey<ScaffoldMessengerState> configuracionPinMessenger =
    GlobalKey<ScaffoldMessengerState>();

class ConfiguracionPinSeguridad extends StatefulWidget {
  const ConfiguracionPinSeguridad({super.key});

  @override
  State<ConfiguracionPinSeguridad> createState() =>
      _ConfiguracionPinSeguridadState();
}

class _ConfiguracionPinSeguridadState extends State<ConfiguracionPinSeguridad>
    with FormController {
  late TextEditingController _pinSeguridad;
  final GlobalKey<FormState> _scaffoldingFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _pinSeguridad = TextEditingController();
    // inicializar();
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
                  showSnackBar(configuracionPinMessenger, error,
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
    final security = Seguridad.instance;
    return ScaffoldMessenger(
      key: configuracionPinMessenger,
      child: Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            toolbarHeight: 0,
          ),
          body: SafeArea(
              child: SingleChildScrollView(
            child: Form(
              key: _scaffoldingFormKey,
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                        onPressed: logout,
                        icon: const Icon(Icons.close_rounded)),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Pin de seguridad',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                              'Configura tu pin de seguridad, te servirá para desbloquear la aplicación, podrás cambiarlo en cualquier momento.'),
                        )),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Icon(
                      SolarIconsBold.lockKeyhole,
                      color: theme.secondary,
                      size: 90,
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: CustomTextInput(
                        // disable: listener.isLoading,
                        onlyNumbers: true,
                        placeholder: 'Ingresa un número de 6 dígitos',
                        requiredData: true,
                        maxLength: 6,
                        controller: _pinSeguridad,
                        title: 'Pin de seguridad',
                        onChange: (value) {
                          Logger.info('valor pin $value');
                          security.store.pin = value;
                          // service.store.form.username = value,
                        },
                        validate: (value, alias) => validateData(
                              context,
                              value,
                              alias,
                              max: 6,
                              min: 6,
                              // regExp: RegExp(r'^\d+$')
                              regExp: PatternRegexp.number,
                            )),
                  ),
                  const SizedBox(
                    height: 40,
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
                          leading: Icon(SolarIconsOutline.infoCircle,
                              color: theme.secondary),
                          title: const Text(
                              style: TextStyle(fontSize: 12, height: 1.4),
                              'Recuerda ingresar una combinación de números para tu pin de seguridad que solo tú conozcas.'),
                        )),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  SimpleButton(
                    title: 'Continuar',
                    fullWidth: false,
                    onTap: () async {
                      if (validateForm(_scaffoldingFormKey)) {
                        // service.login();
                        Logger.info('continuar para configurar huella');
                        Logger.info('valor de pin > ${security.store.pin}');
                        if (await security.hasBiometrics && context.mounted) {
                          GoRouter.of(context)
                              .goNamed(RouteNames.configurarDesbloqueo);
                          return;
                        }

                        /// registrar el pin e ingresar
                        security.loginLocalSecurity(fingerprint: false);
                        Auth.instance.isLocked = false;
                        GoRouter.of(context).goNamed(RouteNames.home);
                        // GoRouter.of(context).goNamed(RouteNames.splashScreen);
                      }
                    },
                  )
                ],
              ),
            ),
          ))),
    );
  }
}
