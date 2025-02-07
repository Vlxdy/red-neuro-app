import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/seguridad/seguridad.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:control_ventas_movil/src/ui/common/components/custom_circle.dart';
import 'package:control_ventas_movil/src/ui/common/snackbar/snackbar.dart';
import 'package:control_ventas_movil/src/ui/pages/mi_cuenta/componentes/avatar_perfil.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

GlobalKey<ScaffoldMessengerState> miCuentaMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Micuenta extends StatefulWidget {
  const Micuenta({super.key});

  @override
  State<Micuenta> createState() => _MicuentaState();
}

class _MicuentaState extends State<Micuenta> {
  Seguridad seguridad = Seguridad.instance;
  bool? fingerprintEnabled;
  bool? hasFingerprint;
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
                  showSnackBar(miCuentaMessenger, error,
                      state: StatusSnackBar.error, colorText: theme.white);
                }
              },
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    inicializar();
  }

  void inicializar() async {
    hasFingerprint = await seguridad.hasBiometrics;
    fingerprintEnabled = await seguridad.hasFingeprintEnabled;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isLocked = Auth.instance.isLocked;

    return ScaffoldMessenger(
      key: miCuentaMessenger,
      child: Scaffold(
        backgroundColor: theme.primary,
        // appBar: AppBar(
        //   scrolledUnderElevation: 0,
        //   elevation: 0,
        //   systemOverlayStyle: SystemUiOverlayStyle(
        //       statusBarBrightness:
        //           theme.isDark ? Brightness.dark : Brightness.light,
        //       statusBarColor: theme.transparent),
        //   backgroundColor: theme.transparent,
        //   centerTitle: false,
        //   title: const Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         'Mi cuenta',
        //         style: TextStyle(fontWeight: FontWeight.bold),
        //       ),
        //     ],
        //   ),
        // ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                  top: -120.0,
                  left: 140.0,
                  child: CustomCircle(
                    customRadius: 350,
                    customColor: theme.primary50.withValues(alpha: 0.1),
                  )),
              Positioned(
                  top: -200.0,
                  left: -140.0,
                  child: CustomCircle(
                    customRadius: 350,
                    customColor: theme.primary50.withValues(alpha: 0.1),
                  )),
              Column(
                children: [
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Ajustes',
                          style: TextStyle(
                              color: theme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        IconButton(
                            onPressed: () {
                              Auth.instance.isLocked = true;
                              GoRouter.of(context)
                                  .goNamed(RouteNames.procesarSesion);
                            },
                            icon: Icon(
                              color: theme.warning,
                              isLocked
                                  ? SolarIconsBold.lockKeyhole
                                  : SolarIconsBold.lockKeyholeUnlocked,
                              size: 23,
                            ))
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: theme.background,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            AvatarPerfil(),
                            const SizedBox(
                              height: 30,
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: theme.white,
                                // backgroundBlendMode: BlendMode.colorBurn,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Logger.info('modificar pin de seguridad');
                                  GoRouter.of(context)
                                      .pushNamed(RouteNames.modificarPin);
                                },
                                // tileColor: Colors.red,
                                leading: Icon(
                                  SolarIconsBold.lockKeyholeMinimalistic,
                                  color: theme.secondary,
                                ),
                                title: const Text(
                                  'Modificar pin de seguridad',
                                  // style: TextStyle(color: theme.error),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: theme.white,
                                // backgroundBlendMode: BlendMode.colorBurn,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Logger.info('modificar fingerprint');
                                  if (fingerprintEnabled != null &&
                                      hasFingerprint != null &&
                                      hasFingerprint!) {
                                    seguridad
                                        .updateFingeprint(!fingerprintEnabled!);
                                    setState(() {
                                      fingerprintEnabled = !fingerprintEnabled!;
                                    });
                                  }
                                },
                                leading: const Icon(
                                  Icons.fingerprint_rounded,
                                ),
                                title: const Text(
                                  'Usar el sensor de huella',
                                ),
                                trailing: Transform.scale(
                                  scale: fingerprintEnabled != null ? 0.7 : 0.5,
                                  child: fingerprintEnabled != null &&
                                          hasFingerprint != null
                                      ? Switch.adaptive(
                                          activeColor: theme.primary,
                                          activeTrackColor: theme.primary
                                              .withValues(alpha: 0.3),
                                          inactiveThumbColor: theme.grey,
                                          inactiveTrackColor:
                                              theme.grey.withValues(alpha: 0.3),
                                          value: fingerprintEnabled!,
                                          onChanged: !hasFingerprint!
                                              ? null
                                              : (value) {
                                                  Logger.info(
                                                      'usar el sensor de huella ? > $value');
                                                  seguridad
                                                      .updateFingeprint(value);
                                                  setState(() {
                                                    fingerprintEnabled = value;
                                                  });
                                                })
                                      : CircularProgressIndicator(
                                          color: theme.secondary,
                                        ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: theme.white,
                                // backgroundBlendMode: BlendMode.colorBurn,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                onTap: logout,
                                tileColor: Colors.red,
                                leading: Icon(SolarIconsOutline.logout_3,
                                    color: theme.error),
                                title: Text(
                                  'Cerrar sesión',
                                  style: TextStyle(color: theme.error),
                                ),
                              ),
                            ),
                            // ListTile(
                            //   onTap: () {
                            //     // context.pushNamed(RouteNames.acercaFormix);
                            //   },
                            //   tileColor: theme.monochromatic50,
                            //   leading: const CircleAvatar(
                            //     maxRadius: 15,
                            //     backgroundImage:
                            //         AssetImage(Recursos.logoPrincipal),
                            //   ),
                            //   title: Text(
                            //     'Acerca de',
                            //     style: TextStyle(color: theme.neutral),
                            //   ),
                            //   subtitle: Text(
                            //     'Versión ${info.version}',
                            //     style: Theme.of(context)
                            //         .textTheme
                            //         .labelLarge
                            //         ?.copyWith(color: theme.black),
                            //   ),
                            //   // trailing: Icon(Icons.arrow_forward_ios, color: theme.neutral),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
