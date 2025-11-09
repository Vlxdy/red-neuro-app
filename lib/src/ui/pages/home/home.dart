import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/plugins/estaciones/bitacora_store.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:alimenta_app/src/ui/common/keep_alive_page.dart';
import 'package:alimenta_app/src/ui/global/template_page.dart';
import 'package:alimenta_app/src/ui/pages/citas_medicas/screens/citas_medicas_page.dart';
import 'package:alimenta_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:alimenta_app/src/ui/pages/plan_nutricional/screens/plan_nutricional_page.dart';
import 'package:alimenta_app/src/ui/pages/mi_cuenta/mi_cuenta.dart';
import 'package:alimenta_app/src/ui/pages/perfil/perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final GlobalKey<ScaffoldMessengerState> homeMessenger =
    GlobalKey<ScaffoldMessengerState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int? _selectedSubItem;
  bool showSubmenu = false;
  final PageController controllerPrincipal = PageController(initialPage: 0);
  final PageController controllerSubmenu = PageController(initialPage: 0);
  late List<ChildrenItem> _itemsMenu;
  final bitacoraStore = BitacoraStore.instance;
  final theme = ThemeController.instance;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(String titulo, int index) {
    setState(() {
      _selectedIndex = index;
      _selectedSubItem = null;
    });
    Logger.info('Vista $titulo');
    controllerPrincipal.jumpToPage(index);
  }

  void _onItemTappedSubmenu(String titulo, int index, int subIndex) {
    setState(() {
      _selectedIndex = index;
      _selectedSubItem = subIndex;
    });
    Logger.info('Vista $titulo');
    controllerSubmenu.jumpToPage(subIndex);
  }

  void _showMenu(
      List<ChildrenItem> itemsSubmenu, int indexPadre, String titulo) {
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
                    return SizedBox(
                      child: InkWell(
                        onTap: () => {
                          _onItemTappedSubmenu(
                              subitem.titulo, indexPadre, subIndex),
                          Navigator.pop(context)
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
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    ).whenComplete(
      () => setState(() {
        showSubmenu = false;
      }),
    );
  }

  Widget buildNavItem(IconData icon, String label, int index,
      List<ChildrenItem>? itemsSubmenu, Color? color) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: itemsSubmenu != null
          ? () => {
                setState(() {
                  showSubmenu = true;
                }),
                _showMenu(itemsSubmenu, index, label),
              }
          : () => _onItemTapped(label, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color ?? (isSelected ? theme.primary : null),
              ),
              const SizedBox(width: 2),
              itemsSubmenu != null
                  ? Transform.rotate(
                      angle: 3.14 / 2,
                      child: Icon(
                          isSelected
                              ? SolarIconsBold.roundDoubleAltArrowLeft
                              : SolarIconsOutline.menuDots,
                          size: 15,
                          color: color ?? (isSelected ? theme.primary : null)),
                    )
                  : const SizedBox(),
            ],
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
    _itemsMenu = [
      ChildrenItem(
        iconoImagen: PhosphorIconsRegular.forkKnife,
        iconoImagenSeleccionada: PhosphorIconsFill.forkKnife,
        titulo: 'Plan nutricional',
        children: const KeepAlivePage(child: PlanNutricionalPage()),
      ),
      ChildrenItem(
        iconoImagen: SolarIconsOutline.calendar,
        iconoImagenSeleccionada: SolarIconsBold.calendar,
        titulo: 'Citas médicas',
        children: const KeepAlivePage(child: CitasMedicasPage()),
      ),
      ChildrenItem(
          iconoImagen: SolarIconsOutline.settings,
          iconoImagenSeleccionada: SolarIconsBold.settings,
          titulo: 'Configuracion',
          // children: const Ubicaciones(),
          itemsSubmenu: [
            ChildrenItem(
                color: theme.primary,
                iconoImagen: SolarIconsOutline.user,
                iconoImagenSeleccionada: SolarIconsBold.user,
                titulo: 'Perfil',
                children: const KeepAlivePage(child: Perfil())),
            ChildrenItem(
              color: theme.secondary,
              iconoImagen: SolarIconsOutline.password,
              iconoImagenSeleccionada: SolarIconsBold.password,
              titulo: 'Cambiar contraseña',
              children: const CambiarContrasena(),
            ),
            ChildrenItem(
              color: theme.secondary,
              iconoImagen: SolarIconsOutline.password,
              iconoImagenSeleccionada: SolarIconsBold.password,
              titulo: 'Sesión',
              children: const Micuenta(),
            ),
          ]),
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
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller:
                    showSubmenu ? controllerSubmenu : controllerPrincipal,
                onPageChanged: (pageIndex) {
                  setState(() {
                    if (showSubmenu) {
                      _selectedSubItem = pageIndex;
                    } else {
                      _selectedIndex = pageIndex;
                      _selectedSubItem = null;
                    }
                  });
                },
                children: _selectedSubItem != null
                    ? (_itemsMenu[_selectedIndex]
                            .itemsSubmenu
                            ?.map((item) => item.children ?? Container())
                            .toList() ??
                        [])
                    : _itemsMenu
                        .map((item) => item.children ?? Container())
                        .toList(),
              ),
            )
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: theme.background,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _itemsMenu.asMap().entries.map((entry) {
              int index = entry.key;
              ChildrenItem item = entry.value;
              return buildNavItem(
                index == _selectedIndex
                    ? item.iconoImagenSeleccionada
                    : item.iconoImagen,
                item.titulo,
                index,
                item.itemsSubmenu,
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
  List<ChildrenItem>? itemsSubmenu;

  ChildrenItem(
      {required this.iconoImagen,
      required this.iconoImagenSeleccionada,
      required this.titulo,
      this.children,
      this.onTap,
      this.color,
      this.itemsSubmenu});
}
