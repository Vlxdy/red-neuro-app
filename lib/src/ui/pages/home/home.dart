import 'package:camino_seguro/src/config/routes.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/plugins/auth/auth.dart';
import 'package:camino_seguro/src/plugins/estaciones/estacion_servicio.dart';
import 'package:camino_seguro/src/plugins/utils/logger.dart';
import 'package:camino_seguro/src/ui/common/keep_alive_page.dart';
import 'package:camino_seguro/src/ui/global/template_page.dart';
import 'package:camino_seguro/src/ui/pages/areas/screens/areas.dart';
import 'package:camino_seguro/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/screens/dependientes.dart';
import 'package:camino_seguro/src/ui/pages/mi_cuenta/mi_cuenta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  int _selectedSubItem = 0;
  bool showSubmenu = false;

  final PageController controller = PageController(initialPage: 0);
  final PageController controllerSubmenu = PageController(initialPage: 0);
  late List<ChildrenItem> _itemsChildren;

  @override
  void initState() {
    super.initState();
    _cargarParametricas();
  }

  void _onItemTapped(int index, VoidCallback? onTap, String titulo) {
    if (onTap != null) {
      onTap();
    } else {
      setState(() {
        _selectedIndex = index;
        showSubmenu = false;
      });
      Logger.info('Vista \$titulo');
      controller.jumpToPage(index);
    }
  }

  void _onItemTappedSubmenu(String titulo, int indexPadre, int subIndex) {
    setState(() {
      _selectedIndex = indexPadre;
      _selectedSubItem = subIndex;
      showSubmenu = false;
    });
    Logger.info('Vista \$titulo');
    controllerSubmenu.jumpToPage(subIndex);
  }

  void _cargarParametricas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        // final paramService = ParametricasService('', context);
        // paramService.cargarParametricas();
      }
    });
  }

  void _showMenu(
      List<ChildrenItem> itemsSubmenu, int indexPadre, String titulo) {
    final theme = ThemeController.instance;
    setState(() {
      showSubmenu = true;
    });
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo.replaceAll('\n', ' '),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.secondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  mainAxisExtent: 100,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: itemsSubmenu.length,
                itemBuilder: (context, subIndex) {
                  final subitem = itemsSubmenu[subIndex];
                  return InkWell(
                    onTap: () {
                      _onItemTappedSubmenu(
                          subitem.titulo, indexPadre, subIndex);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Opacity(
                                opacity: 0.1,
                                child: Icon(
                                  subitem.iconoImagenSeleccionada,
                                  size: 50,
                                  color: subitem.color,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: subitem.color?.withAlpha(35),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(subitem.iconoImagenSeleccionada,
                                    color: subitem.color, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    subitem.titulo,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: subitem.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        showSubmenu = false;
      });
    });
  }

  Widget buildNavItem(
    IconData icon,
    String label,
    int index,
    VoidCallback? onTap,
    Color? color,
  ) {
    final bool isSelected = _selectedIndex == index;
    final theme = ThemeController.instance;

    return GestureDetector(
      onTap: onTap != null
          ? () => onTap()
          : () => _onItemTapped(index, onTap, label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? (isSelected ? theme.primary : null)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color ?? (isSelected ? theme.primary : null),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
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
    final estacion = EstacionServicioStore.instance.estacionServicio;
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _itemsChildren = [
      ChildrenItem(
        iconoImagen: SolarIconsOutline.peopleNearby,
        iconoImagenSeleccionada: SolarIconsBold.peopleNearby,
        titulo: 'Dependientes',
        children: const KeepAlivePage(child: Dependientes()),
      ),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.map,
        iconoImagenSeleccionada: SolarIconsBold.map,
        titulo: 'Áreas',
        children: const Areas(),
      ),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.mapPoint,
        iconoImagenSeleccionada: SolarIconsBold.mapPoint,
        titulo: 'Ubicaciones',
        children: const CambiarContrasena(),
      ),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.settings,
        iconoImagenSeleccionada: SolarIconsBold.settings,
        titulo: 'Configuración',
        children: const Areas(),
        itemsSubmenu: [
          ChildrenItem(
            color: theme.primary,
            iconoImagen: SolarIconsOutline.gasStation,
            iconoImagenSeleccionada: SolarIconsBold.gasStation,
            titulo: 'Perfil',
            children: const KeepAlivePage(child: Areas()),
            onTap: () => GoRouter.of(context).goNamed(RouteNames.perfil),
          ),
          ChildrenItem(
            color: theme.secondary,
            iconoImagen: SolarIconsOutline.speedometerMiddle,
            iconoImagenSeleccionada: SolarIconsBold.speedometerMiddle,
            titulo: 'Cambiar contraseña',
            children: const CambiarContrasena(),
          ),
        ],
      ),
    ];

    return TemplatePage(
      page: ScaffoldMessenger(
        key: homeMessenger,
        child: Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            toolbarHeight: 0,
            backgroundColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarBrightness:
                  theme.isDark ? Brightness.dark : Brightness.light,
              statusBarColor: Colors.transparent,
            ),
          ),
          body: Column(
            children: [
              // HEADER
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      estacion.nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.black,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Auth.instance.isLocked = true;
                            GoRouter.of(context)
                                .goNamed(RouteNames.procesarSesion);
                          },
                          icon: Icon(
                            isLocked
                                ? SolarIconsBold.lockKeyhole
                                : SolarIconsBold.lockKeyholeUnlocked,
                            color: theme.warning,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Micuenta(),
                            ),
                          ),
                          icon: Icon(
                            SolarIconsBold.settings,
                            color: theme.primary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // CONTENT
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller,
                  onPageChanged: (i) => setState(() => _selectedIndex = i),
                  children: _itemsChildren.map((item) {
                    if (item.itemsSubmenu != null) {
                      // Si tiene submenu, mostrar controles de submenu
                      return Column(
                        children: [
                          Expanded(
                            child: PageView(
                              controller: controllerSubmenu,
                              children: item.itemsSubmenu!
                                  .map((sub) => sub.children ?? Container())
                                  .toList(),
                            ),
                          ),
                          BottomNavigationBar(
                            currentIndex: _selectedSubItem,
                            items: item.itemsSubmenu!
                                .asMap()
                                .entries
                                .map((e) => BottomNavigationBarItem(
                                      icon: Icon(e.value.iconoImagen),
                                      label: e.value.titulo,
                                    ))
                                .toList(),
                            onTap: (idx) => _onItemTappedSubmenu(
                              item.itemsSubmenu![idx].titulo,
                              _selectedIndex,
                              idx,
                            ),
                          ),
                        ],
                      );
                    }
                    return item.children ?? Container();
                  }).toList(),
                ),
              ),
              // NAVIGATION
              BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _itemsChildren.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final itm = entry.value;
                    return buildNavItem(
                      _selectedIndex == idx
                          ? itm.iconoImagenSeleccionada
                          : itm.iconoImagen,
                      itm.titulo,
                      idx,
                      itm.itemsSubmenu != null
                          ? () => _showMenu(itm.itemsSubmenu!, idx, itm.titulo)
                          : itm.onTap,
                      itm.color,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChildrenItem {
  final IconData iconoImagen;
  final IconData iconoImagenSeleccionada;
  final String titulo;
  final Widget? children;
  final VoidCallback? onTap;
  final List<ChildrenItem>? itemsSubmenu;
  final Color? color;

  ChildrenItem({
    required this.iconoImagen,
    required this.iconoImagenSeleccionada,
    required this.titulo,
    this.children,
    this.onTap,
    this.itemsSubmenu,
    this.color,
  });
}
