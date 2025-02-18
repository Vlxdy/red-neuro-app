import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/keep_alive_page.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:control_ventas_movil/src/ui/pages/inicio/inicio_store.dart';
import 'package:control_ventas_movil/src/ui/pages/mi_cuenta/mi_cuenta.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

final GlobalKey<ScaffoldMessengerState> homeMessenger =
    GlobalKey<ScaffoldMessengerState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;
  final codigoPinStore = CodigoPinStore.instance;

  final PageController controller = PageController(
    initialPage: 2,
  );

  /// Array con lista de pestañas
  late List<ChildrenItem> _itemsChildren;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isLocked = Auth.instance.isLocked;
    _itemsChildren = [
      ChildrenItem(
        iconoImagen: SolarIconsOutline.courseUp,
        iconoImagenSeleccionada: SolarIconsBold.courseUp,
        titulo: 'Resumen del Día',
        children: const ResumenDelDiaPage(),
        // _onTappedBar
      ),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.checklistMinimalistic,
        iconoImagenSeleccionada: SolarIconsBold.checklistMinimalistic,
        titulo: 'Sincronizar Reportes',
        children: const CambiarContrasena(),
      ),
      ChildrenItem(
          iconoImagen: SolarIconsOutline.gasStation,
          iconoImagenSeleccionada: SolarIconsBold.gasStation,
          titulo: 'Volúmenes y Contadores',
          children: const KeepAlivePage(child: Micuenta())),
      ChildrenItem(
          iconoImagen: SolarIconsOutline.shopMinimalistic,
          iconoImagenSeleccionada: SolarIconsBold.shopMinimalistic,
          titulo: 'Registrar Ventas',
          children: const Micuenta()),
      ChildrenItem(
          iconoImagen: SolarIconsOutline.settings,
          iconoImagenSeleccionada: SolarIconsBold.settings,
          titulo: 'Perfil',
          children: const Micuenta()),
    ];

    return TemplatePage(
      page: ScaffoldMessenger(
        key: homeMessenger,
        child: Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            toolbarHeight: 0,
            scrolledUnderElevation: 0,
            // foregroundColor: theme.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
                statusBarBrightness:
                    theme.isDark ? Brightness.dark : Brightness.light,
                statusBarColor: theme.transparent),
            backgroundColor: Colors.transparent,
            centerTitle: false,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.info, color: theme.primary, size: 28),
                      const SizedBox(width: 20),
                      Icon(Icons.notifications, color: theme.primary, size: 28),
                      const SizedBox(width: 10),
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
                            size: 28,
                          )),
                    ]),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'EESS Santa Rosa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.black,
                        ),
                      ),
                      Text(
                        '12/12/2024 00:00 - 08:00',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.black,
                        ),
                      ),
                    ]),
              ),
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller,
                  onPageChanged: (pageIndex) {
                    setState(() {
                      _selectedIndex = pageIndex;
                    });
                  },
                  children: _itemsChildren.map((e) => e.children).toList(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  // color: theme.background,
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(0),
                    margin:
                        const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                    decoration: BoxDecoration(
                        color: theme.white,
                        borderRadius: BorderRadius.circular(50)),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = 0;
                              });
                              Logger.info('Vista ${_itemsChildren[0].titulo}');
                              controller.jumpToPage(0);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(50)),
                              ),
                              child: Icon(
                                _selectedIndex == 0
                                    ? _itemsChildren[0].iconoImagenSeleccionada
                                    : _itemsChildren[0].iconoImagen,
                                color: theme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = 1;
                              });
                              Logger.info('Vista ${_itemsChildren[1].titulo}');
                              controller.jumpToPage(1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Icon(
                                _selectedIndex == 1
                                    ? _itemsChildren[1].iconoImagenSeleccionada
                                    : _itemsChildren[1].iconoImagen,
                                color: theme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = 2;
                              });
                              Logger.info('Vista ${_itemsChildren[2].titulo}');
                              controller.jumpToPage(2);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Icon(
                                _selectedIndex == 2
                                    ? _itemsChildren[2].iconoImagenSeleccionada
                                    : _itemsChildren[2].iconoImagen,
                                color: theme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = 3;
                              });
                              Logger.info('Vista ${_itemsChildren[3].titulo}');
                              controller.jumpToPage(3);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(50))),
                              child: Icon(
                                _selectedIndex == 3
                                    ? _itemsChildren[3].iconoImagenSeleccionada
                                    : _itemsChildren[3].iconoImagen,
                                color: theme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = 3;
                              });
                              Logger.info('Vista ${_itemsChildren[4].titulo}');
                              controller.jumpToPage(3);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(50))),
                              child: Icon(
                                _selectedIndex == 4
                                    ? _itemsChildren[4].iconoImagenSeleccionada
                                    : _itemsChildren[4].iconoImagen,
                                color: theme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          bottomNavigationBar: null,
        ),
      ),
    );
  }
}

class ChildrenItem {
  IconData iconoImagen;
  IconData iconoImagenSeleccionada;
  String titulo;
  Widget children;

  ChildrenItem(
      {required this.iconoImagen,
      required this.iconoImagenSeleccionada,
      required this.titulo,
      required this.children});
}
