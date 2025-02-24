import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/logger.dart';
import 'package:control_ventas_movil/src/ui/common/keep_alive_page.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/home/home.dart';
import 'package:control_ventas_movil/src/ui/pages/mi_cuenta/mi_cuenta.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/componentes/usuario_directo_screen.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/maquinaria_screen.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/tanque_adicional.dart';
import 'package:control_ventas_movil/src/ui/pages/registrar_venta/venta_bidones_screen.dart';
import 'package:control_ventas_movil/src/ui/pages/resumen_dia/resumen_dia.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

final GlobalKey<ScaffoldMessengerState> homeMessenger =
    GlobalKey<ScaffoldMessengerState>();

class RegistrarVentaPage extends StatefulWidget {
  const RegistrarVentaPage({super.key});

  @override
  State<RegistrarVentaPage> createState() => _RegistrarVentaState();
}

class _RegistrarVentaState extends State<RegistrarVentaPage> {
  int _selectedIndex = 0;

  final PageController controller = PageController(
    initialPage: 0,
  );

  /// Array con lista de pestañas
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
                fontWeight: FontWeight.normal,
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
          iconoImagen: SolarIconsOutline.gasStation,
          iconoImagenSeleccionada: SolarIconsBold.gasStation,
          titulo: 'Venta de\nBidones',
          children: const KeepAlivePage(child: VentaBidonesScreen())),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.bus,
        iconoImagenSeleccionada: SolarIconsBold.bus,
        titulo: 'Maquinaria',
        children: const MaquinariaScreen(),
      ),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.home,
        iconoImagenSeleccionada: SolarIconsBold.home,
        titulo: 'Home',
        children: const ResumenDelDiaPage(),
        onTap: () => {GoRouter.of(context).goNamed(RouteNames.home)},
        // onTap: () async => await context.pushNamed<String>(RouteNames.home),
        color: theme.secondary,
      ),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.user,
        iconoImagenSeleccionada: SolarIconsBold.user,
        titulo: 'Usuario\nDirecto',
        children: const UsuarioDirectoPage(),
      ),
      ChildrenItem(
          iconoImagen: SolarIconsOutline.gasStation,
          iconoImagenSeleccionada: SolarIconsBold.gasStation,
          titulo: 'Tanque\nadicional',
          children: const TanqueAdicionalScreen()),
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
      body: Column(
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
    )));
  }
}
