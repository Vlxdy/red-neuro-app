import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/rol.dart';
import 'package:red_neuro_app/src/models/submodulo.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/badges/counter_badge.dart';
import 'package:red_neuro_app/src/ui/common/keep_alive_page.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/perfil/perfil.dart';
import 'package:red_neuro_app/src/ui/pages/usuarios/usuarios_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_page.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_page.dart';
import 'package:red_neuro_app/src/ui/pages/categorias/categorias_page.dart';
import 'package:red_neuro_app/src/ui/pages/servicios/servicios_page.dart';
import 'package:red_neuro_app/src/ui/pages/lugares/lugares_page.dart';
import 'package:red_neuro_app/src/ui/pages/pacientes/pacientes_page.dart';
import 'package:red_neuro_app/src/ui/pages/personal_salud/personal_salud_page.dart';
import 'package:red_neuro_app/src/ui/pages/notificaciones/notificaciones_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/ui/pages/placeholder/placeholder.dart';
import 'package:red_neuro_app/src/ui/pages/placeholder/role_tray_placeholder.dart';
import 'package:red_neuro_app/src/utils/role_utils.dart';

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
  List<ChildrenItem> _itemsMenu = [];
  final theme = ThemeController.instance;
  String _currentRole = '';
  late final VoidCallback _profileListener;

  @override
  void initState() {
    super.initState();
    _profileListener = () {
      final profile = Auth.instance.profileListenable.value;
      _configureMenu(user: profile);
    };

    Auth.instance.profileListenable.addListener(_profileListener);

    WidgetsBinding.instance.addPostFrameCallback((_) => _configureMenu());
  }

  @override
  void dispose() {
    Auth.instance.profileListenable.removeListener(_profileListener);
    super.dispose();
  }

  Future<void> _configureMenu({Usuario? user}) async {
    final profile = user ?? await Auth.instance.profileAsync();
    final List<Rol> roles = profile.roles;
    final roleId = profile.idRol ?? (roles.isNotEmpty ? roles.first.idRol : '');
    final selectedRole = _findRole(roles, roleId, profile.rol);
    final roleName = RoleUtils.normalizeRole(selectedRole?.rol ?? profile.rol ?? '');
    final roleLabel = RoleUtils.roleLabel(roleName);

    if (!mounted) return;

    setState(() {
      _currentRole = roleLabel;
      _itemsMenu = _itemsByRole(
        user: profile,
        selectedRole: selectedRole,
        screenWidth: _currentScreenWidth(),
      );
      _selectedIndex = 0;
      _selectedSubItem = null;
    });
  }

  Rol? _findRole(List<Rol> roles, String? roleId, String? roleName) {
    if (roles.isEmpty) return null;
    try {
      return roles.firstWhere(
        (rol) =>
            (roleId != null && roleId.isNotEmpty && rol.idRol == roleId) ||
            (roleName != null &&
                roleName.isNotEmpty &&
                rol.rol.toUpperCase() == roleName.toUpperCase()),
      );
    } catch (_) {
      return roles.first;
    }
  }

  double _currentScreenWidth() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize.width / view.devicePixelRatio;
  }

  void _onItemTapped(String titulo, int index) {
    setState(() {
      _selectedIndex = index;
      _selectedSubItem = null;
      showSubmenu = false;
    });
    Logger.info('Vista $titulo');
    _jumpToPageSafely(controllerPrincipal, index);
  }

  void _onItemTappedSubmenu(String titulo, int index, int subIndex) {
    setState(() {
      _selectedIndex = index;
      _selectedSubItem = subIndex;
      showSubmenu = true;
    });
    Logger.info('Vista $titulo');
    _jumpToPageSafely(controllerSubmenu, subIndex);
  }

  void _jumpToPageSafely(PageController controller, int pageIndex) {
    if (controller.hasClients) {
      controller.jumpToPage(pageIndex);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (controller.hasClients) {
        controller.jumpToPage(pageIndex);
      }
    });
  }

  bool get _usePrimaryTrayShell => _itemsMenu.isNotEmpty;

  void _showMenu(
    List<ChildrenItem> itemsSubmenu,
    int indexPadre,
    String titulo,
  ) {
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
                  final badgeCount = subitem.badgeCount;
                  final icono = Icon(
                    subitem.iconoImagenSeleccionada,
                    color: subitem.color,
                    size: 28,
                  );
                  final iconWithBadge = badgeCount > 0
                      ? CounterBadge(
                          count: badgeCount,
                          backgroundColor: subitem.color ?? theme.primary,
                          borderColor: theme.white,
                          offset: const Offset(-10, -6),
                          child: icono,
                        )
                      : icono;
                  return SizedBox(
                    child: InkWell(
                      onTap: () => {
                        _onItemTappedSubmenu(
                          subitem.titulo,
                          indexPadre,
                          subIndex,
                        ),
                        Navigator.pop(context),
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
                                      iconWithBadge,
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
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    ).whenComplete(
      () => setState(() {
        showSubmenu = _selectedSubItem != null;
      }),
    );
  }

  Widget buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    List<ChildrenItem>? itemsSubmenu,
    Color? color, {
    int badgeCount = 0,
  }) {
    final bool isSelected = _selectedIndex == index;
    final navColor = _usePrimaryTrayShell
        ? (isSelected ? theme.white : theme.white.withValues(alpha: 0.78))
        : color;

    Widget iconWidget = Icon(
      icon,
      color: navColor ?? (isSelected ? theme.primary : null),
    );

    if (badgeCount > 0) {
      iconWidget = CounterBadge(
        count: badgeCount,
        backgroundColor: theme.primary,
        borderColor: theme.background,
        offset: const Offset(-10, -6),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: itemsSubmenu != null
          ? () => {
              setState(() {
                showSubmenu = true;
              }),
              _showMenu(itemsSubmenu, index, label),
            }
          : () => _onItemTapped(label, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (_usePrimaryTrayShell
                    ? theme.white.withValues(alpha: 0.14)
                    : theme.primary.withValues(alpha: 0.10))
              : theme.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(width: 2),
                itemsSubmenu != null
                    ? Transform.rotate(
                        angle: 3.14 / 2,
                        child: Icon(
                          isSelected
                              ? SolarIconsBold.roundDoubleAltArrowLeft
                              : SolarIconsOutline.menuDots,
                          size: 15,
                          color:
                              navColor ?? (isSelected ? theme.primary : null),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: navColor ?? (isSelected ? theme.primary : null),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    if (_itemsMenu.isEmpty) {
      return TemplatePage(
        page: Scaffold(
          backgroundColor: theme.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  _currentRole.isEmpty
                      ? 'Cargando menús por rol...'
                      : 'No hay módulos disponibles para $_currentRole',
                  style: TextStyle(color: theme.secondary),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final Color shellColor = theme.isDark ? theme.bgCard : theme.primary;
    final Color bottomNavColor = _usePrimaryTrayShell
        ? (theme.isDark ? theme.bgCard : theme.primary900)
        : theme.background;

    return TemplatePage(
      page: ScaffoldMessenger(
        key: homeMessenger,
        child: Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            toolbarHeight: 0,
            scrolledUnderElevation: 0,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarBrightness: theme.isDark
                  ? Brightness.dark
                  : Brightness.light,
              statusBarColor: _usePrimaryTrayShell
                  ? shellColor
                  : theme.transparent,
            ),
            backgroundColor: _usePrimaryTrayShell
                ? shellColor
                : theme.transparent,
            centerTitle: false,
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _selectedSubItem != null
                      ? controllerSubmenu
                      : controllerPrincipal,
                  onPageChanged: (int pageIndex) {
                    setState(() {
                      if (_selectedSubItem != null) {
                        _selectedSubItem = pageIndex;
                        showSubmenu = true;
                      } else {
                        _selectedIndex = pageIndex;
                        _selectedSubItem = null;
                        showSubmenu = false;
                      }
                    });
                  },
                  children: _selectedSubItem != null
                      ? (_itemsMenu[_selectedIndex].itemsSubmenu
                                ?.map(
                                  (ChildrenItem item) =>
                                      item.children ?? Container(),
                                )
                                .toList() ??
                            [])
                      : _itemsMenu
                            .map(
                              (ChildrenItem item) =>
                                  item.children ?? Container(),
                            )
                            .toList(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: bottomNavColor,
              border: Border(
                top: BorderSide(
                  color: _usePrimaryTrayShell
                      ? (theme.isDark
                          ? theme.monochromatic500.withValues(alpha: 0.9)
                          : theme.white.withValues(alpha: 0.12))
                      : theme.monochromatic200.withValues(alpha: 0.35),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.black.withValues(
                    alpha: theme.isDark ? 0.26 : 0.08,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _itemsMenu.asMap().entries.map((
                    MapEntry<int, ChildrenItem> entry,
                  ) {
                    int index = entry.key;
                    ChildrenItem item = entry.value;
                    return buildNavItem(
                      context,
                      index == _selectedIndex
                          ? item.iconoImagenSeleccionada
                          : item.iconoImagen,
                      item.titulo,
                      index,
                      item.itemsSubmenu,
                      item.color,
                      badgeCount: item.badgeCount,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<ChildrenItem> _itemsByRole({
  required Usuario user,
  required Rol? selectedRole,
  required double screenWidth,
}) {
  final theme = ThemeController.instance;
  final resolvedRole = RoleUtils.normalizeRole(selectedRole?.rol ?? user.rol ?? '');

  final perfilNav = ChildrenItem(
    iconoImagen: SolarIconsOutline.user,
    iconoImagenSeleccionada: SolarIconsBold.user,
    titulo: 'Perfil',
    color: theme.primary,
    children: const KeepAlivePage(child: Perfil()),
  );

  final subModuleItems = _submodulesFromRole(
    selectedRole: selectedRole,
    resolvedRole: resolvedRole,
    theme: theme,
  );

  final maxNavItems = (screenWidth / 72).floor().clamp(4, 6);
  final availableSlots = maxNavItems - 1;
  final needsOverflow = subModuleItems.length > availableSlots;
  final visibleSlots = needsOverflow
      ? (maxNavItems - 2).clamp(0, availableSlots)
      : availableSlots;

  final visibleSubmodules = subModuleItems
      .take(visibleSlots)
      .toList(growable: false);
  final overflowSubmodules = subModuleItems
      .skip(visibleSlots)
      .toList(growable: true);

  final List<ChildrenItem> navigation = [...visibleSubmodules];

  if (needsOverflow) {
    overflowSubmodules.add(perfilNav);
    navigation.add(
      ChildrenItem(
        iconoImagen: SolarIconsOutline.menuDots,
        iconoImagenSeleccionada: SolarIconsBold.menuDots,
        titulo: 'Más',
        color: theme.primary,
        itemsSubmenu: overflowSubmodules,
        children: const KeepAlivePage(
          child: RoleTrayPlaceholder(
            title: 'Elige una bandeja',
            description:
                'Este rol tiene varias bandejas. Selecciona una desde el menú flotante.',
            actions: [
              'Abre el menú "Más" para listar todas las bandejas disponibles',
              'Selecciona la bandeja que quieras explorar',
            ],
            leadingIcon: PhosphorIconsRegular.dotsThreeCircle,
          ),
        ),
      ),
    );
  } else {
    navigation.add(perfilNav);
  }

  return navigation;
}

String _normalizeRoute(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  if (normalized.isEmpty) return normalized;
  if (normalized.length > 1 && normalized.endsWith('/')) {
    return normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

String _canonicalSupportedRoute(String? value) {
  final normalized = _normalizeRoute(value);
  switch (normalized) {
    case '/admin/inicio':
      return '/admin/home';
    default:
      return normalized;
  }
}

ChildrenItem _homeMenuItem(ThemeController theme) => ChildrenItem(
  iconoImagen: PhosphorIconsRegular.house,
  iconoImagenSeleccionada: PhosphorIconsFill.house,
  titulo: 'Inicio',
  color: theme.primary,
  children: const KeepAlivePage(child: MisCitasHomePage()),
);

List<ChildrenItem> _ensureHomeFirst(
  List<ChildrenItem> items,
  ThemeController theme,
) {
  if (items.isEmpty) return [_homeMenuItem(theme)];

  final hasHome = items.any(
    (item) =>
        _normalizeRoute(item.titulo) == 'home' ||
        _normalizeRoute(item.titulo) == 'inicio',
  );
  if (hasHome) {
    final ordered = [...items]
      ..sort((a, b) {
        final aHome =
            _normalizeRoute(a.titulo) == 'home' ||
            _normalizeRoute(a.titulo) == 'inicio';
        final bHome =
            _normalizeRoute(b.titulo) == 'home' ||
            _normalizeRoute(b.titulo) == 'inicio';
        if (aHome == bHome) return 0;
        return aHome ? -1 : 1;
      });
    return ordered;
  }

  return [_homeMenuItem(theme), ...items];
}

List<ChildrenItem> _submodulesFromRole({
  required Rol? selectedRole,
  required String resolvedRole,
  required ThemeController theme,
}) {
  const supportedRoutesOrder = [
    '/admin/home',
    '/admin/citas',
    '/admin/pacientes',
    '/admin/personal_medico',
    '/admin/servicios',
    '/admin/lugares',
  ];

  const adminRoutesOrder = [...supportedRoutesOrder];

  if (selectedRole != null && selectedRole.modulos.isNotEmpty) {
    final filteredModules = selectedRole.modulos.where((module) {
      final name = _normalizeRoute(module.nombre);
      final label = _normalizeRoute(module.label);
      final url = _canonicalSupportedRoute(module.url);
      return name != 'principal' && label != 'principal' && url != '/principal';
    }).toList();

    final orderedModules = filteredModules
      ..sort(
        (a, b) =>
            (a.propiedades?.orden ?? 0).compareTo(b.propiedades?.orden ?? 0),
      );

    final submodules = <ChildrenItem>[];
    for (final module in orderedModules) {
      final orderedSubmodules = [...module.subModulos]
        ..sort(
          (a, b) =>
              (a.propiedades?.orden ?? 0).compareTo(b.propiedades?.orden ?? 0),
        );

      for (final subModule in orderedSubmodules) {
        if (!supportedRoutesOrder.contains(
          _canonicalSupportedRoute(subModule.url),
        )) {
          continue;
        }
        submodules.add(_submoduleToItem(subModule, theme: theme));
      }
    }

    final submodulesByUrl = <String, ChildrenItem>{};
    for (final module in orderedModules) {
      for (final subModule in module.subModulos) {
        final normalizedUrl = _canonicalSupportedRoute(subModule.url);
        if (adminRoutesOrder.contains(normalizedUrl)) {
          submodulesByUrl.putIfAbsent(
            normalizedUrl,
            () => _submoduleToItem(subModule, theme: theme),
          );
        }
      }
    }

    final orderedByPermission = adminRoutesOrder
        .map((route) => submodulesByUrl[route])
        .whereType<ChildrenItem>()
        .toList();

    if (orderedByPermission.isNotEmpty) {
      return _ensureHomeFirst(orderedByPermission, theme);
    }
    if (submodules.isNotEmpty) return _ensureHomeFirst(submodules, theme);
  }

  switch (resolvedRole) {
    case 'ADMINISTRADOR':
      return _adminMenu(theme);
    case 'JEFE':
      return _personalSaludAdminMenu(theme);
    case 'COORDINADOR':
    case 'PERSONAL':
    case 'PROFESIONAL_INVITADO':
      return _personalSaludMenu(theme);
    default:
      return [_noModulesPlaceholder(theme)];
  }
}

ChildrenItem _submoduleToItem(
  SubModulo subModule, {
  required ThemeController theme,
}) {
  final blueprint = _resolveTrayBlueprint(subModule);
  final normalizedUrl = _canonicalSupportedRoute(subModule.url);
  final normalizedName = _normalizeRoute(subModule.nombre);

  final isUsuariosModule =
      normalizedUrl.contains('usuarios') || normalizedName == 'usuarios';
  final isHomeModule =
      normalizedUrl == '/admin/home' ||
      normalizedName == 'home' ||
      normalizedName == 'inicio';
  final isCategoriasModule =
      normalizedUrl.contains('categorias') || normalizedName == 'categorias';
  final isServiciosModule =
      normalizedUrl.contains('estudios') ||
      normalizedUrl.contains('servicios') ||
      normalizedName == 'estudios' ||
      normalizedName == 'servicios';
  final isLugaresModule =
      normalizedUrl.contains('lugares') || normalizedName == 'lugares';
  final isCitasModule =
      normalizedUrl == '/admin/citas' || normalizedName == 'citas';
  final isNotificacionesModule =
      normalizedUrl.contains('notificaciones') ||
      normalizedName == 'notificaciones';
  final isPacientesModule =
      normalizedUrl.contains('pacientes') || normalizedName == 'pacientes';
  final isPersonalMedicoModule =
      normalizedUrl.contains('personal_medico') ||
      normalizedName.contains('personal');

  final resolvedIconName = isNotificacionesModule
      ? 'notificaciones'
      : isHomeModule
      ? 'home'
      : isCitasModule
      ? 'citas'
      : isCategoriasModule
      ? 'categorias'
      : isPacientesModule
      ? 'pacientes'
      : isPersonalMedicoModule
      ? 'personal_medico'
      : isLugaresModule
      ? 'lugares'
      : isServiciosModule
      ? 'servicios'
      : subModule.propiedades?.icono;

  return ChildrenItem(
    iconoImagen: _moduleIconData(resolvedIconName),
    iconoImagenSeleccionada: _moduleIconData(resolvedIconName, filled: true),
    titulo: isHomeModule
        ? (subModule.label.isNotEmpty ? subModule.label : 'Inicio')
        : isCategoriasModule
        ? 'Categorías'
        : isServiciosModule
        ? 'Servicios'
        : (subModule.label.isNotEmpty ? subModule.label : subModule.nombre),
    color: theme.primary,
    children: KeepAlivePage(
      child: isUsuariosModule
          ? const UsuariosPage()
          : isHomeModule
          ? const MisCitasHomePage()
          : isNotificacionesModule
          ? const NotificacionesPage()
          : isCategoriasModule
          ? const CategoriasPage()
          : isLugaresModule
          ? const LugaresPage()
          : isServiciosModule
          ? const ServiciosPage()
          : isCitasModule
          ? const CitasPage(
              soloMisCitas: false,
              titulo: 'Agenda',
              mostrarFiltroMedico: true,
            )
          : isPacientesModule
          ? const PacientesPage()
          : isPersonalMedicoModule
          ? const PersonalSaludPage()
          : RoleTrayPlaceholder(
              title: blueprint.title,
              description: blueprint.description,
              actions: blueprint.actions,
              leadingIcon: blueprint.icon,
            ),
    ),
  );
}

IconData _moduleIconData(String? iconName, {bool filled = false}) {
  switch ((iconName ?? '').toLowerCase()) {
    case 'calendar':
    case 'citas':
      return filled
          ? PhosphorIconsFill.calendarCheck
          : PhosphorIconsRegular.calendarCheck;
    case 'pacientes':
      return filled
          ? PhosphorIconsFill.userCircle
          : PhosphorIconsRegular.userCircle;
    case 'personal_medico':
    case 'personal-medico':
    case 'personal medico':
      return filled
          ? PhosphorIconsFill.stethoscope
          : PhosphorIconsRegular.stethoscope;
    case 'categorias':
    case 'category':
      return filled ? Icons.category : Icons.category_outlined;
    case 'ocupaciones':
    case 'medical_services':
      return filled ? Icons.medical_services : Icons.medical_services_outlined;
    case 'estudios':
    case 'servicios':
    case 'science':
      return filled ? Icons.science : Icons.science_outlined;
    case 'lugares':
    case 'place':
      return filled ? Icons.location_city : Icons.location_city_outlined;
    case 'user':
    case 'usuarios':
      return filled ? PhosphorIconsFill.users : PhosphorIconsRegular.users;
    case 'home':
      return filled ? PhosphorIconsFill.house : PhosphorIconsRegular.house;
    case 'person':
      return filled ? PhosphorIconsFill.user : PhosphorIconsRegular.user;
    case 'manage_accounts':
    case 'manage-accounts':
      return filled
          ? PhosphorIconsFill.userSwitch
          : PhosphorIconsRegular.userSwitch;
    case 'server':
      return filled ? SolarIconsBold.server : SolarIconsOutline.server;
    case 'notifications':
    case 'notificaciones':
      return filled ? Icons.notifications : Icons.notifications_none_rounded;
    default:
      return filled
          ? PhosphorIconsFill.gridFour
          : PhosphorIconsRegular.gridFour;
  }
}

List<ChildrenItem> _adminMenu(ThemeController theme) => [
  _homeMenuItem(theme),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.calendarCheck,
    iconoImagenSeleccionada: PhosphorIconsFill.calendarCheck,
    titulo: 'Agenda',
    children: const KeepAlivePage(
      child: CitasPage(
        soloMisCitas: false,
        titulo: 'Agenda',
        mostrarFiltroMedico: true,
      ),
    ),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.userCircle,
    iconoImagenSeleccionada: PhosphorIconsFill.userCircle,
    titulo: 'Pacientes',
    children: const KeepAlivePage(child: PacientesPage()),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.stethoscope,
    iconoImagenSeleccionada: PhosphorIconsFill.stethoscope,
    titulo: 'Personal médico',
    children: const KeepAlivePage(child: PersonalSaludPage()),
  ),
  ChildrenItem(
    iconoImagen: Icons.science_outlined,
    iconoImagenSeleccionada: Icons.science,
    titulo: 'Servicios',
    children: const KeepAlivePage(child: ServiciosPage()),
  ),
  ChildrenItem(
    iconoImagen: Icons.location_city_outlined,
    iconoImagenSeleccionada: Icons.location_city,
    titulo: 'Lugares',
    children: const KeepAlivePage(child: LugaresPage()),
  ),
];
List<ChildrenItem> _personalSaludAdminMenu(ThemeController theme) => [
  _homeMenuItem(theme),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.calendarPlus,
    iconoImagenSeleccionada: PhosphorIconsFill.calendarPlus,
    titulo: 'Agenda',
    children: const KeepAlivePage(
      child: CitasPage(
        soloMisCitas: false,
        titulo: 'Agenda (Personal de salud - Admin)',
        mostrarFiltroMedico: true,
      ),
    ),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.userCircle,
    iconoImagenSeleccionada: PhosphorIconsFill.userCircle,
    titulo: 'Pacientes',
    children: const KeepAlivePage(child: PacientesPage()),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.stethoscope,
    iconoImagenSeleccionada: PhosphorIconsFill.stethoscope,
    titulo: 'Personal médico',
    children: const KeepAlivePage(child: PersonalSaludPage()),
  ),
  ChildrenItem(
    iconoImagen: Icons.science_outlined,
    iconoImagenSeleccionada: Icons.science,
    titulo: 'Servicios',
    children: const KeepAlivePage(child: ServiciosPage()),
  ),
  ChildrenItem(
    iconoImagen: Icons.location_city_outlined,
    iconoImagenSeleccionada: Icons.location_city,
    titulo: 'Lugares',
    children: const KeepAlivePage(child: LugaresPage()),
  ),
];
List<ChildrenItem> _personalSaludMenu(ThemeController theme) => [
  _homeMenuItem(theme),
  ChildrenItem(
    iconoImagen: SolarIconsOutline.calendarSearch,
    iconoImagenSeleccionada: SolarIconsBold.calendarSearch,
    titulo: 'Agenda',
    children: const KeepAlivePage(
      child: CitasPage(soloMisCitas: true, titulo: 'Mi agenda'),
    ),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.userCircle,
    iconoImagenSeleccionada: PhosphorIconsFill.userCircle,
    titulo: 'Pacientes',
    children: const KeepAlivePage(child: PacientesPage()),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.stethoscope,
    iconoImagenSeleccionada: PhosphorIconsFill.stethoscope,
    titulo: 'Personal médico',
    children: const KeepAlivePage(child: PersonalSaludPage()),
  ),
  ChildrenItem(
    iconoImagen: Icons.science_outlined,
    iconoImagenSeleccionada: Icons.science,
    titulo: 'Servicios',
    children: const KeepAlivePage(child: ServiciosPage()),
  ),
  ChildrenItem(
    iconoImagen: Icons.location_city_outlined,
    iconoImagenSeleccionada: Icons.location_city,
    titulo: 'Lugares',
    children: const KeepAlivePage(child: LugaresPage()),
  ),
];
ChildrenItem _noModulesPlaceholder(ThemeController theme) => ChildrenItem(
  iconoImagen: PhosphorIconsRegular.chatTeardropText,
  iconoImagenSeleccionada: PhosphorIconsFill.chatTeardropText,
  titulo: 'Módulos',
  color: theme.primary,
  children: const KeepAlivePage(
    child: PlaceholderPage(
      title: "Rol sin módulos asignados aún.",
      icon: Icons.info_outline,
    ),
  ),
);

class ChildrenItem {
  IconData iconoImagen;
  IconData iconoImagenSeleccionada;
  String titulo;
  Widget? children;
  VoidCallback? onTap;
  Color? color;
  List<ChildrenItem>? itemsSubmenu;
  int badgeCount;

  ChildrenItem({
    required this.iconoImagen,
    required this.iconoImagenSeleccionada,
    required this.titulo,
    this.children,
    this.onTap,
    this.color,
    this.itemsSubmenu,
    this.badgeCount = 0,
  });
}

class UserOverview extends StatelessWidget {
  const UserOverview({
    super.key,
    required this.user,
    required this.currentRole,
  });

  final Usuario user;
  final String currentRole;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final fullName = [
      user.nombres,
      user.primerApellido,
      user.segundoApellido,
    ].where((value) => value.trim().isNotEmpty).join(' ');
    final activeRoleLabel = currentRole.isNotEmpty
        ? currentRole
        : (user.rol ?? '').toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido/a',
            style: TextStyle(
              color: theme.secondary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fullName.isEmpty ? (user.usuario ?? 'Usuario') : fullName,
            style: TextStyle(
              color: theme.neutral,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            color: theme.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Usuario', user.usuario ?? '-'),
                  _infoRow('Correo', user.correoElectronico),
                  _infoRow('Documento', user.nroDocumento),
                  _infoRow(
                    'Rol activo',
                    activeRoleLabel.isNotEmpty ? activeRoleLabel : '-',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: theme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(color: theme.neutral),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrayBlueprint {
  final String title;
  final String description;
  final List<String> actions;
  final IconData icon;

  const _TrayBlueprint({
    required this.title,
    required this.description,
    required this.actions,
    required this.icon,
  });
}

_TrayBlueprint _resolveTrayBlueprint(SubModulo subModule) {
  final knownTrays = <String, _TrayBlueprint>{
    '/admin/perfil': _TrayBlueprint(
      title: 'Perfil',
      description: 'Gestiona tu información personal y credenciales.',
      actions: const [
        'Ver datos de cuenta y foto de perfil',
        'Actualizar información básica',
        'Revisar rol activo y accesos',
      ],
      icon: _moduleIconData('person'),
    ),
    'perfil': _TrayBlueprint(
      title: 'Perfil',
      description: 'Gestiona tu información personal y credenciales.',
      actions: const [
        'Ver datos de cuenta y foto de perfil',
        'Actualizar información básica',
        'Revisar rol activo y accesos',
      ],
      icon: _moduleIconData('person'),
    ),
    '/admin/home': _TrayBlueprint(
      title: 'Home',
      description:
          'Vista principal de Mis citas con resumen, solicitadas y timeline por fecha.',
      actions: const [
        'Ver resumen de citas desde hoy',
        'Expandir o colapsar solicitadas pendientes',
        'Recorrer timeline por fecha con paginación',
      ],
      icon: _moduleIconData('home'),
    ),
    '/admin/categorias': _TrayBlueprint(
      title: 'Categorías',
      description:
          'Administra categorías utilizadas para organizar los servicios.',
      actions: const [
        'Listar categorías activas e inactivas',
        'Crear y editar categorías',
        'Cambiar estado de categorías',
      ],
      icon: _moduleIconData('categorias'),
    ),
    '/admin/servicios': _TrayBlueprint(
      title: 'Servicios',
      description:
          'Gestiona el catálogo de servicios y estudios disponibles en la plataforma.',
      actions: const [
        'Listar servicios por categoría',
        'Crear y editar servicios',
        'Actualizar disponibilidad de servicios',
      ],
      icon: _moduleIconData('servicios'),
    ),
    '/admin/usuarios': _TrayBlueprint(
      title: 'Usuarios',
      description:
          'Administra cuentas del sistema, altas, bajas y configuraciones.',
      actions: const [
        'Listar usuarios y filtrar por estado o rol',
        'Crear y editar información de usuario',
        'Asignar o revocar roles disponibles',
      ],
      icon: _moduleIconData('manage_accounts'),
    ),
    '/admin/notificaciones': _TrayBlueprint(
      title: 'Notificaciones',
      description:
          'Consulta la bandeja de avisos y el resumen diario de citas por rol.',
      actions: const [
        'Ver notificaciones por fecha y estado de lectura',
        'Marcar notificaciones individuales o todas como vistas',
        'Revisar resumen diario de citas',
      ],
      icon: _moduleIconData('notificaciones'),
    ),
    'notificaciones': _TrayBlueprint(
      title: 'Notificaciones',
      description:
          'Consulta la bandeja de avisos y el resumen diario de citas por rol.',
      actions: const [
        'Ver notificaciones por fecha y estado de lectura',
        'Marcar notificaciones individuales o todas como vistas',
        'Revisar resumen diario de citas',
      ],
      icon: _moduleIconData('notificaciones'),
    ),
    '/admin/citas': _TrayBlueprint(
      title: 'Agenda',
      description:
          'Agenda y administra las citas médicas disponibles en el sistema.',
      actions: const [
        'Revisar agenda diaria o semanal',
        'Crear, editar o cancelar citas médicas',
        'Aplicar filtros por médico o estado',
      ],
      icon: _moduleIconData('calendar'),
    ),
    '/admin/pacientes': _TrayBlueprint(
      title: 'Pacientes',
      description:
          'Gestiona el listado de pacientes registrados en la plataforma.',
      actions: const [
        'Listar pacientes registrados',
        'Crear o editar información de pacientes',
      ],
      icon: _moduleIconData('user'),
    ),
    '/admin/personal_medico': _TrayBlueprint(
      title: 'Personal médico',
      description:
          'Gestiona el catálogo de médicos y personal de salud disponibles.',
      actions: const [
        'Listar personal médico activo',
        'Registrar o actualizar perfiles médicos',
      ],
      icon: _moduleIconData('manage_accounts'),
    ),
    '/admin/lugares': _TrayBlueprint(
      title: 'Lugares',
      description:
          'Gestiona instituciones y lugares de atención disponibles en la plataforma.',
      actions: const [
        'Listar lugares con filtros y paginación',
        'Crear, editar y cambiar estado de lugares',
      ],
      icon: _moduleIconData('lugares'),
    ),
    'usuarios': _TrayBlueprint(
      title: 'Usuarios',
      description:
          'Administra cuentas del sistema, altas, bajas y configuraciones.',
      actions: const [
        'Listar usuarios y filtrar por estado o rol',
        'Crear y editar información de usuario',
        'Asignar o revocar roles disponibles',
      ],
      icon: _moduleIconData('manage_accounts'),
    ),
  };

  final normalizedUrl = _canonicalSupportedRoute(subModule.url);
  final normalizedName = _normalizeRoute(subModule.nombre);

  final match = knownTrays[normalizedUrl] ?? knownTrays[normalizedName];
  if (match != null) return match;

  final title = subModule.label.isNotEmpty ? subModule.label : subModule.nombre;
  final description =
      subModule.propiedades?.descripcion ??
      'Bandeja vacía para $title. A la espera de integraciones.';

  return _TrayBlueprint(
    title: title,
    description: description,
    actions: const [
      'Definir acciones de navegación para este submódulo',
      'Sin datos aún: pendiente de integración con API',
    ],
    icon: _moduleIconData(subModule.propiedades?.icono),
  );
}
