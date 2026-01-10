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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/ui/pages/placeholder/placeholder.dart';
import 'package:red_neuro_app/src/ui/pages/placeholder/role_tray_placeholder.dart';

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
    final resolvedRoleName = (selectedRole?.rol ?? profile.rol ?? '')
        .toUpperCase();

    if (!mounted) return;

    setState(() {
      _currentRole = resolvedRoleName;
      _itemsMenu = _itemsByRole(
        user: profile,
        selectedRole: selectedRole,
        overview: _buildUserOverview(profile),
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

  Widget _buildUserOverview(Usuario user) {
    return UserOverview(user: user, currentRole: _currentRole);
  }

  void _onItemTapped(String titulo, int index) {
    setState(() {
      _selectedIndex = index;
      _selectedSubItem = null;
      showSubmenu = false;
    });
    Logger.info('Vista $titulo');
    controllerPrincipal.jumpToPage(index);
  }

  void _onItemTappedSubmenu(String titulo, int index, int subIndex) {
    setState(() {
      _selectedIndex = index;
      _selectedSubItem = subIndex;
      showSubmenu = true;
    });
    Logger.info('Vista $titulo');
    controllerSubmenu.jumpToPage(subIndex);
  }

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

    Widget iconWidget = Icon(
      icon,
      color: color ?? (isSelected ? theme.primary : null),
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
                        color: color ?? (isSelected ? theme.primary : null),
                      ),
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
              statusBarColor: theme.transparent,
            ),
            backgroundColor: Colors.transparent,
            centerTitle: false,
          ),
          body: Column(
            children: [
              const SizedBox(height: 10),
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
          bottomNavigationBar: BottomAppBar(
            color: theme.background,
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
    );
  }
}

List<ChildrenItem> _itemsByRole({
  required Usuario user,
  required Rol? selectedRole,
  required Widget overview,
}) {
  final theme = ThemeController.instance;
  final resolvedRole = (selectedRole?.rol ?? user.rol ?? '').toUpperCase();

  final homeSummary = ChildrenItem(
    iconoImagen: SolarIconsOutline.home,
    iconoImagenSeleccionada: SolarIconsBold.home,
    titulo: 'Inicio',
    color: theme.primary,
    children: KeepAlivePage(child: overview),
  );

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

  const maxDirectTabs = 4;
  final visibleSubmodules = subModuleItems
      .take(maxDirectTabs)
      .toList(growable: false);
  final overflowSubmodules = subModuleItems
      .skip(maxDirectTabs)
      .toList(growable: false);

  final List<ChildrenItem> navigation = [homeSummary, ...visibleSubmodules];

  if (overflowSubmodules.isNotEmpty) {
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
  }

  navigation.add(perfilNav);

  return navigation;
}

List<ChildrenItem> _submodulesFromRole({
  required Rol? selectedRole,
  required String resolvedRole,
  required ThemeController theme,
}) {
  if (selectedRole != null && selectedRole.modulos.isNotEmpty) {
    final filteredModules = selectedRole.modulos.where((module) {
      final name = module.nombre.toLowerCase();
      final label = module.label.toLowerCase();
      final url = module.url.toLowerCase();
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
        submodules.add(_submoduleToItem(subModule, theme: theme));
      }
    }

    if (submodules.isNotEmpty) return submodules;
  }

  switch (resolvedRole) {
    case 'ADMIN':
      return _adminMenu(theme);
    case 'SUPERVISOR':
      return _supervisorMenu(theme);
    case 'MEDICO':
      return _medicoMenu(theme);
    default:
      return [_noModulesPlaceholder(theme)];
  }
}

ChildrenItem _submoduleToItem(
  SubModulo subModule, {
  required ThemeController theme,
}) {
  final blueprint = _resolveTrayBlueprint(subModule);
  final normalizedUrl = subModule.url.toLowerCase();
  final normalizedName = subModule.nombre.toLowerCase();

  final isUsuariosModule =
      normalizedUrl.contains('usuarios') || normalizedName == 'usuarios';

  return ChildrenItem(
    iconoImagen: _moduleIconData(subModule.propiedades?.icono),
    iconoImagenSeleccionada: _moduleIconData(
      subModule.propiedades?.icono,
      filled: true,
    ),
    titulo: subModule.label.isNotEmpty ? subModule.label : subModule.nombre,
    color: theme.primary,
    children: KeepAlivePage(
      child: isUsuariosModule
          ? const UsuariosPage()
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
    case 'user':
    case 'usuarios':
      return filled ? PhosphorIconsFill.users : PhosphorIconsRegular.users;
    case 'tag':
    case 'etiquetas':
      return filled ? PhosphorIconsFill.tag : PhosphorIconsRegular.tag;
    case 'home':
      return filled ? PhosphorIconsFill.house : PhosphorIconsRegular.house;
    case 'person':
      return filled ? PhosphorIconsFill.user : PhosphorIconsRegular.user;
    case 'manage_accounts':
    case 'manage-accounts':
      return filled
          ? PhosphorIconsFill.userSwitch
          : PhosphorIconsRegular.userSwitch;
    case 'agrupadores':
    case 'server':
      return filled ? SolarIconsBold.server : SolarIconsOutline.server;
    default:
      return filled
          ? PhosphorIconsFill.gridFour
          : PhosphorIconsRegular.gridFour;
  }
}

List<ChildrenItem> _adminMenu(ThemeController theme) => [
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.users,
    iconoImagenSeleccionada: PhosphorIconsFill.users,
    titulo: 'Usuarios',
    children: const KeepAlivePage(child: UsuariosPage()),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.tag,
    iconoImagenSeleccionada: PhosphorIconsFill.tag,
    titulo: 'Etiquetas',
    children: const KeepAlivePage(
      child: RoleTrayPlaceholder(
        title: 'Etiquetas',
        description: 'Crea y organiza etiquetas para clasificar citas.',
        actions: [
          'Nueva etiqueta (POST /etiquetas)',
          'Editar etiqueta (PATCH /etiquetas/:id)',
          'Eliminar etiqueta (DELETE /etiquetas/:id)',
        ],
      ),
    ),
  ),
  ChildrenItem(
    iconoImagen: SolarIconsOutline.server,
    iconoImagenSeleccionada: SolarIconsBold.server,
    titulo: 'Agrupadores',
    children: const KeepAlivePage(
      child: RoleTrayPlaceholder(
        title: 'Agrupadores',
        description: 'Organiza campañas o bloques para citas.',
        actions: [
          'Crear agrupador (POST /agrupadores)',
          'Editar agrupador (PATCH /agrupadores/:id)',
          'Eliminar agrupador (DELETE /agrupadores/:id)',
        ],
      ),
    ),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.calendarCheck,
    iconoImagenSeleccionada: PhosphorIconsFill.calendarCheck,
    titulo: 'Citas',
    children: const KeepAlivePage(
      child: RoleTrayPlaceholder(
        title: 'Citas (Administrador)',
        description:
            'Bandeja vacía para monitorear y gestionar todas las citas.',
        actions: [
          'Listar todas las citas (GET /citas)',
          'Crear cita para cualquier médico (POST /citas)',
          'Editar, cancelar o reprogramar (PATCH /citas/:id/...)',
        ],
      ),
    ),
  ),
];

List<ChildrenItem> _supervisorMenu(ThemeController theme) => [
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.users,
    iconoImagenSeleccionada: PhosphorIconsFill.users,
    titulo: 'Usuarios',
    children: const KeepAlivePage(child: UsuariosPage()),
  ),
  ChildrenItem(
    iconoImagen: PhosphorIconsRegular.calendarPlus,
    iconoImagenSeleccionada: PhosphorIconsFill.calendarPlus,
    titulo: 'Citas',
    children: const KeepAlivePage(
      child: CitasPage(
        soloMisCitas: false,
        titulo: 'Citas (Supervisor)',
        mostrarFiltroMedico: true,
      ),
    ),
  ),
];

List<ChildrenItem> _medicoMenu(ThemeController theme) => [
  ChildrenItem(
    iconoImagen: SolarIconsOutline.calendarSearch,
    iconoImagenSeleccionada: SolarIconsBold.calendarSearch,
    titulo: 'Mis citas',
    children: const KeepAlivePage(
      child: CitasPage(soloMisCitas: true, titulo: 'Mis citas'),
    ),
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
    '/admin/home': _TrayBlueprint(
      title: 'Inicio',
      description:
          'Pantalla de bienvenida para navegación rápida según tu rol activo.',
      actions: const [
        'Consultar accesos rápidos visibles para el rol',
        'Revisar notificaciones o recordatorios de la sesión',
      ],
      icon: _moduleIconData('home'),
    ),
    'inicio': _TrayBlueprint(
      title: 'Inicio',
      description:
          'Pantalla de bienvenida para navegación rápida según tu rol activo.',
      actions: const [
        'Consultar accesos rápidos visibles para el rol',
        'Revisar notificaciones o recordatorios de la sesión',
      ],
      icon: _moduleIconData('home'),
    ),
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

  final normalizedUrl = (subModule.url).toLowerCase();
  final normalizedName = (subModule.nombre).toLowerCase();

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
