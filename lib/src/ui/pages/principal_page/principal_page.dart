import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/constants/constants.dart';
import 'package:control_ventas_movil/src/constants/resources.dart';
import 'package:control_ventas_movil/src/extensions/strings_extensions.dart';
import 'package:control_ventas_movil/src/models/carga_combustible.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/plugins/utils/utils.dart';
import 'package:control_ventas_movil/src/ui/common/components/custom_circle.dart';
import 'package:control_ventas_movil/src/ui/common/components/custom_simple_circle.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/principal_page/principal_page_service.dart';
import 'package:control_ventas_movil/src/ui/pages/principal_page/principal_page_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

final GlobalKey<ScaffoldMessengerState> principalMessenger =
    GlobalKey<ScaffoldMessengerState>();

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPage();
}

class _PrincipalPage extends State<PrincipalPage> with WidgetsBindingObserver {
  final auth = Auth.instance;
  late PrincipalPageService service;

  @override
  void initState() {
    service = PrincipalPageService('', context);
    service.fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isLocked = Auth.instance.isLocked;
    final store = context.watch<PrincipalPageStore>();
    final asignacionUsuario = store.vehiculoActivo.asignacion;
    return TemplatePage(
      page: ScaffoldMessenger(
          key: principalMessenger,
          child: Scaffold(
            backgroundColor: theme.primary,
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
                      // Header with name and vehicle information
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flex(
                                  direction: Axis.horizontal,
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          context.pop();
                                        },
                                        icon: Icon(
                                            color: theme.white,
                                            Icons.arrow_back_ios_new_rounded)),
                                    Text(
                                      'Detalle vehículo',
                                      style: TextStyle(
                                        color: theme.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                                    )),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.all(0),
                              margin: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              // padding: const EdgeInsets.all(16),
                              child: IntrinsicHeight(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      flex: 1,
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: theme.primary,
                                                border: Border.all(
                                                    color: theme.white,
                                                    width: 4),
                                                borderRadius: const BorderRadius
                                                    .horizontal(
                                                    left: Radius.circular(30)),
                                                image: const DecorationImage(
                                                    image: AssetImage(
                                                        Recursos.bgCar),
                                                    fit: BoxFit.contain))),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: ClipRRect(
                                        clipBehavior:
                                            Clip.antiAliasWithSaveLayer,
                                        borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(30),
                                            bottomRight: Radius.circular(30)),
                                        child: Stack(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(15),
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: theme.bgCard,
                                                borderRadius: const BorderRadius
                                                    .horizontal(
                                                    right: Radius.circular(30)),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .center, // Centrar verticalmente
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .center, // Alinear a la izquierda
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                        color: asignacionUsuario
                                                                    .tipo ==
                                                                TipoAsociacion
                                                                    .poseedor
                                                                    .name
                                                            ? theme.bgBlue
                                                            : asignacionUsuario
                                                                        .tipo ==
                                                                    TipoAsociacion
                                                                        .conductor
                                                                        .name
                                                                ? theme
                                                                    .secondary
                                                                : theme.primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50)),
                                                    child: Text(
                                                        asignacionUsuario.tipo
                                                            .capitalize(),
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                theme.white)),
                                                  ),
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                  Text(
                                                    '${store.vehiculoActivo.marca} ${store.vehiculoActivo.tipo} ${store.vehiculoActivo.modelo}',
                                                    // textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: theme.white),
                                                  ),
                                                  const SizedBox(
                                                    height: 2,
                                                  ),
                                                  Text(
                                                    store.vehiculoActivo.placa,
                                                    style: TextStyle(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.white,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              top: -140,
                                              left: -140,
                                              child: CustomSimpleCircle(
                                                customRadius: 200,
                                                customColor: theme.primary50
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                            Positioned(
                                              top: 100.0,
                                              right: -160.0,
                                              child: CustomSimpleCircle(
                                                customRadius: 450,
                                                customColor: theme.primary50
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.background,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Conductores',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              SizedBox(height: 5),
                              Text(
                                'Historial cargas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )),
    );
  }
}
