import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/resources.dart';
import 'package:control_ventas_movil/src/extensions/strings_extensions.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/components/custom_simple_circle.dart';
import 'package:control_ventas_movil/src/ui/pages/inicio/inicio_service.dart';
import 'package:control_ventas_movil/src/ui/pages/inicio/inicio_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

final GlobalKey<ScaffoldMessengerState> inicioMessenger =
    GlobalKey<ScaffoldMessengerState>();

class InicioPage extends StatefulWidget {
  final VoidCallback onGoVehicles;
  const InicioPage({super.key, required this.onGoVehicles});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> with WidgetsBindingObserver {
  late InicioService service;
  final pinStore = CodigoPinStore.instance;

  @override
  void initState() {
    super.initState();
    service = InicioService('', context);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final profile = Auth.instance.profile;
    final isLocked = Auth.instance.isLocked;

    return ScaffoldMessenger(
      key: inicioMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                  // mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      width: 80,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage(Recursos.logoPrincipal),
                              fit: BoxFit.contain)),
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
                  ]),
            ),
            const SizedBox(
              height: 10,
            ),
            CircleAvatar(
              backgroundColor: theme.background,
              foregroundColor: theme.primary,
              radius: 30,
              child: Text(
                '${profile.nombres[0].toUpperCase()}${profile.primerApellido[0].toUpperCase()}',
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Center(
              child: Text(
                '${profile.nombres.capitalize()} ${profile.primerApellido.capitalize()}',
                style: TextStyle(
                    fontSize: 20,
                    color: theme.fontColor,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Center(
              child: Text(
                "${profile.tipoDocumento} ${profile.nroDocumento}",
                style: TextStyle(fontSize: 12, color: theme.fontColor),
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25))),
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    InkWell(
                      onTap: widget.onGoVehicles,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        // decoration: BoxDecoration(
                        //     border: Border.all(color: Colors.red)),
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          // crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    Positioned(
                                        top: -5.0,
                                        left: 20.0,
                                        child: CustomSimpleCircle(
                                          customRadius: 360,
                                          customColor: theme.secondary
                                              .withValues(alpha: 0.2),
                                        )),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      decoration: BoxDecoration(
                                          color: theme.secondary
                                              .withValues(alpha: 0.2),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20))),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            SolarIconsOutline.bus,
                                            color: theme.secondary,
                                            // size: 18,
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          const Text(
                                            'Mis vehículos',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const Align(
                                            alignment: Alignment.bottomRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Ver todos',
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                                SizedBox(
                                                  width: 3,
                                                ),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  size: 14,
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              flex: 3,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    Logger.info("nuevo vehiculo");
                                    // context.pushNamed(
                                    //     RouteNames.registroConductores);
                                    final result = await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                        ),
                                        builder: (BuildContext context) =>
                                            Padding(
                                              padding: MediaQuery.of(context)
                                                  .viewInsets,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Barra indicativa
                                                    Container(
                                                      width: 50,
                                                      height: 5,
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[300],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    // ModalConductor(),
                                                  ],
                                                ),
                                              ),
                                              // child: ModalVehiculo(),
                                            ));

                                    if (result == null) {
                                      Logger.info(
                                          "Modal cerrado con un swipe hacia abajo o botón cerrar");
                                    } else {
                                      Logger.info(
                                          "Modal cerrado con resultado: $result");
                                    }
                                  },
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20)),
                                  splashColor:
                                      theme.primary.withValues(alpha: 0.3),
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                        color: theme.white,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(20))),
                                    child: Column(
                                      children: [
                                        Icon(
                                          SolarIconsOutline.addCircle,
                                          color: theme.secondary,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Nuevo Vehículo',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              height: 1,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
