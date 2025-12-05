import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/seguridad/seguridad.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

GlobalKey<ScaffoldMessengerState> modificarPinSeguridadMessenger =
    GlobalKey<ScaffoldMessengerState>();

class ModificarPinSeguridad extends StatefulWidget {
  const ModificarPinSeguridad({super.key});

  @override
  State<ModificarPinSeguridad> createState() => _ModificarPinSeguridadState();
}

class _ModificarPinSeguridadState extends State<ModificarPinSeguridad>
    with FormController {
  late TextEditingController _pinSeguridad;
  late TextEditingController _currentPinSeguridad;
  final GlobalKey<FormState> _scaffoldingFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _pinSeguridad = TextEditingController();
    _currentPinSeguridad = TextEditingController();
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
                showSnackBar(
                  modificarPinSeguridadMessenger,
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
    final theme = ThemeController.instance;
    // final seguridad = Seguridad.instance;
    return ScaffoldMessenger(
      key: modificarPinSeguridadMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(toolbarHeight: 0),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _scaffoldingFormKey,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () {
                        GoRouter.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                  // Align(
                  //   alignment: Alignment.topRight,
                  //   child: IconButton(
                  //       onPressed: logout,
                  //       icon: const Icon(Icons.close_rounded)),
                  // ),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Modificar pin de seguridad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                          SolarIconsOutline.lightbulbMinimalistic,
                          color: theme.secondary,
                        ),
                        title: const Text(
                          style: TextStyle(fontSize: 12, height: 1.4),
                          'Para modificar el pin de seguridad, debes ingresar el pin actual y el nuevo pin, en caso de que no se pueda validar el pin se cerrará la sesión.',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Icon(
                      SolarIconsBold.lockKeyhole,
                      color: theme.secondary,
                      size: 90,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: CustomTextInput(
                      // disable: listener.isLoading,
                      onlyNumbers: true,
                      placeholder: 'Ingresa un número de 6 dígitos',
                      requiredData: true,
                      maxLength: 6,
                      controller: _currentPinSeguridad,
                      title: 'Pin de seguridad actual',
                      onChange: (value) {
                        Logger.info('valor pin actual > $value');
                        // security.store.pin = value;
                        _currentPinSeguridad.text = value;
                      },
                      validate: (value, alias) => validateData(
                        context,
                        value,
                        alias,
                        max: 6,
                        min: 6,
                        regExp: PatternRegexp.number,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: CustomTextInput(
                      // disable: listener.isLoading,
                      onlyNumbers: true,
                      placeholder: 'Ingresa un número de 6 dígitos',
                      requiredData: true,
                      maxLength: 6,
                      controller: _pinSeguridad,
                      title: 'Nuevo pin de seguridad',
                      onChange: (value) {
                        Logger.info('valor pin $value');
                        // security.store.pin = value;
                        _pinSeguridad.text = value;
                      },
                      validate: (value, alias) => validateData(
                        context,
                        value,
                        alias,
                        max: 6,
                        min: 6,
                        regExp: PatternRegexp.number,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // const SizedBox(
                  //   height: 30,
                  // ),
                  SimpleButton(
                    title: 'Guardar',
                    fullWidth: false,
                    onTap: () async {
                      if (validateForm(_scaffoldingFormKey)) {
                        Logger.info(
                          'valor de pin ACTUAL > ${_currentPinSeguridad.text}',
                        );
                        Logger.info(
                          'valor de pin NUEVO > ${_pinSeguridad.text}',
                        );
                        final pinActual =
                            await Seguridad.instance.apiPinSeguridad;
                        Logger.info('pin actual almacenado > $pinActual');
                        if (pinActual != _currentPinSeguridad.text) {
                          showSnackBar(
                            modificarPinSeguridadMessenger,
                            'El pin actual ingresado no es correcto.',
                            state: StatusSnackBar.error,
                            colorText: theme.white,
                          );
                          return;
                        }
                        if (pinActual == _pinSeguridad.text) {
                          showSnackBar(
                            modificarPinSeguridadMessenger,
                            'El nuevo pin debe ser diferente del pin actual',
                            state: StatusSnackBar.error,
                            colorText: theme.white,
                          );
                          return;
                        }
                        await Seguridad.instance.updateSecurityPin(
                          _pinSeguridad.text,
                        );
                        if (context.mounted && !Auth.instance.isLocked) {
                          GoRouter.of(
                            context,
                          ).goNamed(RouteNames.procesarSesion);
                        }
                        // if (await security.hasBiometrics && context.mounted) {
                        //   GoRouter.of(context)
                        //       .goNamed(RouteNames.configurarDesbloqueo);
                        //   return;
                        // }

                        /// registrar el pin e ingresar
                        // security.loginLocalSecurity(fingerprint: false);
                        // Auth.instance.isLocked = false;
                        // GoRouter.of(context).goNamed(RouteNames.home);
                        // GoRouter.of(context).goNamed(RouteNames.splashScreen);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
