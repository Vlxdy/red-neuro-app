import 'package:control_ventas_movil/src/config/form_controller.dart';
import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/constants/constants.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/seguridad/seguridad.dart';
import 'package:control_ventas_movil/src/plugins/utils/local_secure.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:control_ventas_movil/src/ui/common/dialogs/custom_dialog.dart';
import 'package:control_ventas_movil/src/ui/common/dialogs/dialogos.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/pages/seguridad/pin_olvidado.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/resources.dart';
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
  late TextEditingController _pinSeguridad;

  @override
  void initState() {
    super.initState();
    _pinSeguridad = TextEditingController();
    inicializar();
  }

  void inicializar() async {
    Logger.info('Verificar sesion');
    final context = navigatorKey.currentContext!;
    bool localAuthentication = false;
    final seguridad = Seguridad.instance;

    try {
      if (await seguridad.hasFingeprintEnabled) {
        Logger.info('autenticar con huella!!');
        localAuthentication = await LocalSecure.autenticar(
          titulo: 'Control Ventas Movil',
          message: 'Escanea tu huella dactilar para continuar',
        );
        Logger.info('Biometrico autenticado $localAuthentication');
        if (!localAuthentication) {
          if (context.mounted) {
            final resultadoPin = await formPinSeguridad(context);
            if (resultadoPin != null && resultadoPin) {
              if (resultadoPin != null && resultadoPin) {
                Logger.info('redirigir a home!!! ${_pinSeguridad.text}');
                final pinAlmacenado = await Seguridad.instance.apiPinSeguridad;
                if (pinAlmacenado == _pinSeguridad.text) {
                  if (context.mounted) {
                    Auth.instance.isLocked = false;
                    GoRouter.of(context).goNamed(RouteNames.home);
                  }
                } else {
                  showSnackBar(procesarSesionMessenger,
                      'El pin ingresado es incorrecto.',
                      state: StatusSnackBar.error, colorText: Colors.white);
                  _pinSeguridad.text = "";
                }
                return;
              }
            }
          }
          Logger.info('Seguir bloqueado!!!');
          return;
        }
      } else {
        if (context.mounted) {
          final resultadoPin = await formPinSeguridad(context);
          if (resultadoPin != null && resultadoPin) {
            Logger.info('redirigir a home!!! ${_pinSeguridad.text}');
            final pinAlmacenado = await Seguridad.instance.apiPinSeguridad;
            if (pinAlmacenado == _pinSeguridad.text) {
              if (context.mounted) {
                Auth.instance.isLocked = false;
                GoRouter.of(context).goNamed(RouteNames.home);
              }
            } else {
              showSnackBar(
                  procesarSesionMessenger, 'El pin ingresado es incorrecto.',
                  state: StatusSnackBar.error, colorText: Colors.white);
              _pinSeguridad.text = "";
            }
            return;
          }
        }
      }

      if (localAuthentication) {
        Logger.info('redirigir a home!!!');
        if (context.mounted) {
          Auth.instance.isLocked = false;
          GoRouter.of(context).goNamed(RouteNames.home);
        }
        return;
      }
    } catch (e) {
      Logger.error('Error al inicializar sesion de forma local $e');
      // Logger.error('Stacktrace $stackTrace');
    }
  }

  Future<dynamic> formPinSeguridad(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: CutomDialog(
              title: 'Pin de seguridad',
              onConfirm: () {
                Logger.info('validar pin de seguridad $_pinSeguridad');
              },
              subtitle: 'Ingresa tu pin de seguridad',
              content: Column(
                children: [
                  CustomTextInput(
                      onlyNumbers: true,
                      placeholder: 'Ingresa un número de 6 dígitos',
                      requiredData: true,
                      maxLength: 6,
                      controller: _pinSeguridad,
                      title: 'Número de 6 dígitos',
                      // onChange: (value) {
                      //   Logger.info('valor pin $value');
                      //   // service.store.form.username = value,
                      // },
                      validate: (value, alias) => validateData(
                            context,
                            value,
                            alias,
                            max: 6,
                            min: 6,
                            regExp: PatternRegexp.number,
                          ))
                ],
              ),
            ),
          );
        });
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
                            image: AssetImage(Recursos.logoAnh))),
                  ),
                  InkWell(
                    onTap: () {
                      inicializar();
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      alignment: Alignment.center,
                      child: Icon(
                        color: theme.warning,
                        Auth.instance.isLocked
                            ? SolarIconsBold.lockKeyhole
                            : SolarIconsBold.lockKeyholeUnlocked,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
              // SizedBox(
              //   height: 40,
              // ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image.asset(
                    //   Recursos.lock,
                    //   width: 80,
                    // ),
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
                    const Text(
                      'Usa tu pin de seguridad',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                        onPressed: () async {
                          await Dialogo.showNativeModalBottomSheet(
                              widget: const PinOlvidado(),
                              context: context,
                              isDismissible: true,
                              dragable: true);
                        },
                        child: Text(
                          '¿No recuerdas tu pin?',
                          style: TextStyle(color: theme.fontColor),
                        )),
                    const SizedBox(height: 48),
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
