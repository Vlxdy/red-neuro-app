import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/keep_alive_page.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:control_ventas_movil/src/ui/pages/mi_cuenta/mi_cuenta.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/volumenes_tanques.dart';
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
  int _selectedIndex = 0;
  final PageController controller = PageController(initialPage: 0);

  late List<ChildrenItem> _itemsChildren;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index, VoidCallback? ontap, String titulo) {
    if (ontap != null) {
      ontap();
    } else {
      setState(() {
        _selectedIndex = index;
      });
      Logger.info('Vista $titulo');
      controller.jumpToPage(index);
    }
  }

  Widget buildNavItem(IconData icon, String label, int index,
      VoidCallback? ontap, Color? color) {
    final bool isSelected = _selectedIndex == index;
    final theme = ThemeController.instance;

    return GestureDetector(
      onTap: () => _onItemTapped(index, ontap, label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ?? (isSelected ? theme.primary : null),
          ),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color ?? (isSelected ? theme.primary : null),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final isLocked = Auth.instance.isLocked;
    _itemsChildren = [
      ChildrenItem(
          iconoImagen: SolarIconsOutline.chart_2,
          iconoImagenSeleccionada: SolarIconsBold.chart_2,
          titulo: 'Resumen\ndel Día',
          children: const KeepAlivePage(child: ResumenDelDiaPage())),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.checklistMinimalistic,
        iconoImagenSeleccionada: SolarIconsBold.checklistMinimalistic,
        titulo: 'Sincronizar\nReportes',
        children: const CambiarContrasena(),
      ),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.gasStation,
        iconoImagenSeleccionada: SolarIconsBold.gasStation,
        titulo: 'Volúmenes y\nContadores',
        children: const VolumenesTanquesScreen(),
      ),
      ChildrenItem(
          iconoImagen: SolarIconsOutline.sidebar,
          iconoImagenSeleccionada: SolarIconsBold.sidebar,
          titulo: 'Registrar\nVentas',
          onTap: () async =>
              await context.pushNamed<String>(RouteNames.registrarVenta)),
    ];

    return TemplatePage(
      page: ScaffoldMessenger(
          child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          toolbarHeight: 0,
          scrolledUnderElevation: 0,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarBrightness:
                  theme.isDark ? Brightness.dark : Brightness.light,
              statusBarColor: theme.transparent),
          backgroundColor: Colors.transparent,
          centerTitle: false,
        ),
        body: 
        
        
        
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Icon(Icons.info, color: theme.primary, size: 28),
                const SizedBox(width: 20),
                Icon(Icons.notifications, color: theme.primary, size: 28),
                const SizedBox(width: 10),
                IconButton(
                    onPressed: () {
                      Auth.instance.isLocked = true;
                      GoRouter.of(context).goNamed(RouteNames.procesarSesion);
                    },
                    icon: Icon(
                      color: theme.warning,
                      isLocked
                          ? SolarIconsBold.lockKeyhole
                          : SolarIconsBold.lockKeyholeUnlocked,
                      size: 28,
                    )),
                IconButton(
                    onPressed: () {
                      setState(() {
                        Logger.info('Vista Mi Cuenta');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Micuenta(),
                          ),
                        );
                      });
                    },
                    icon: Icon(
                      color: theme.primary,
                      SolarIconsBold.settings,
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
                  mainAxisSize: MainAxisSize.max,
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
                children: _itemsChildren
                    .map((item) => item.children ?? Container())
                    .toList(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _itemsChildren.asMap().entries.map((entry) {
              int index = entry.key;
              ChildrenItem item = entry.value;
              return buildNavItem(
                index == _selectedIndex
                    ? item.iconoImagenSeleccionada
                    : item.iconoImagen,
                item.titulo,
                index,
                item.onTap,
                item.color,
              );
            }).toList(),
          ),
        ),
      )),
    );
  }
}

class ChildrenItem {
  IconData iconoImagen;
  IconData iconoImagenSeleccionada;
  String titulo;
  Widget? children;
  VoidCallback? onTap;
  Color? color;

  ChildrenItem({
    required this.iconoImagen,
    required this.iconoImagenSeleccionada,
    required this.titulo,
    this.children,
    this.onTap,
    this.color,
  });
}
