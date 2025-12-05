import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/modulo.dart';
import 'package:red_neuro_app/src/models/rol.dart';
import 'package:red_neuro_app/src/models/submodulo.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/badges/counter_badge.dart';
import 'package:red_neuro_app/src/ui/common/keep_alive_page.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:red_neuro_app/src/ui/pages/mi_cuenta/mi_cuenta.dart';
import 'package:red_neuro_app/src/ui/pages/perfil/perfil.dart';
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
  String? _currentRoleId;
  List<Rol> _availableRoles = [];
  Usuario? _userProfile;
  bool _isSyncingRole = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _configureMenu();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncRoleFromStorage();
    });
  }

  Future<void> _configureMenu({Usuario? user}) async {
    final profile = user ?? await Auth.instance.profileAsync();
    final List<Rol> roles = profile.roles;
    final roleId =
        profile.idRol ?? (roles.isNotEmpty ? roles.first.idRol : '');
    final selectedRole = _findRole(roles, roleId, profile.rol);
    final resolvedRoleName =
        (selectedRole?.rol ?? profile.rol ?? '').toUpperCase();

    setState(() {
      _initialized = true;
      _userProfile = profile;
      _availableRoles = roles;
      _currentRoleId = roleId;
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

  Future<void> _syncRoleFromStorage() async {
    if (_isSyncingRole || !mounted) return;
    _isSyncingRole = true;

    final storedUser = await Auth.instance.profileAsync();
    final storedRoleId =
        storedUser.idRol ?? (storedUser.roles.isNotEmpty ? storedUser.roles.first.idRol : '');

    if (storedRoleId != null && storedRoleId != _currentRoleId) {
      await _configureMenu(user: storedUser);
    }

    _isSyncingRole = false;
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
    return UserOverview(
      user: user,
      currentRole: _currentRole,
    );
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
                          child: icono,
                          offset: const Offset(-10, -6),
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
        showSubmenu = false;
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
        child: iconWidget,
        offset: const Offset(-10, -6),
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
                  controller: showSubmenu
                      ? controllerSubmenu
                      : controllerPrincipal,
                  onPageChanged: (int pageIndex) {
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

  final baseCuenta = _accountMenu(theme);

  final homeSummary = ChildrenItem(
    iconoImagen: SolarIconsOutline.home,
    iconoImagenSeleccionada: SolarIconsBold.home,
    titulo: 'Inicio',
    color: theme.primary,
    children: KeepAlivePage(child: overview),
  );

  final moduleItems = _modulesFromRole(
    selectedRole: selectedRole,
    resolvedRole: resolvedRole,
    theme: theme,
  );

  return [homeSummary, ...moduleItems, ...baseCuenta];
}

List<ChildrenItem> _modulesFromRole({
  required Rol? selectedRole,
  required String resolvedRole,
  required ThemeController theme,
}) {
  if (selectedRole != null && selectedRole.modulos.isNotEmpty) {
    final sortedModules = [...selectedRole.modulos]
      ..sort(
        (a, b) => (a.propiedades?.orden ?? 0)
            .compareTo(b.propiedades?.orden ?? 0),
      );

    return sortedModules
        .map((module) => _moduleToItem(module, theme))
        .toList();
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

ChildrenItem _moduleToItem(Modulo module, ThemeController theme) {
  final title = module.nombre.isNotEmpty ? module.nombre : module.label;
  final description = module.propiedades?.descripcion ??
      'Módulo ${module.label} sin descripción detallada. Bandeja vacía por ahora.';

  final trayChild = module.subModulos.isNotEmpty
      ? _SubmoduleTrayGrid(
          moduleLabel: title,
          subModules: module.subModulos,
          theme: theme,
        )
      : RoleTrayPlaceholder(
          title: title,
          description: description,
          actions: ['Explora las opciones disponibles dentro del módulo $title.'],
          leadingIcon: _moduleIconData(module.propiedades?.icono),
        );

  return ChildrenItem(
    iconoImagen: _moduleIconData(module.propiedades?.icono),
    iconoImagenSeleccionada: _moduleIconData(
      module.propiedades?.icono,
      filled: true,
    ),
    titulo: module.label.isNotEmpty ? module.label : module.nombre,
    color: theme.primary,
    children: KeepAlivePage(child: trayChild),
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

List<ChildrenItem> _accountMenu(ThemeController theme) => [
      ChildrenItem(
        iconoImagen: SolarIconsOutline.user,
        iconoImagenSeleccionada: SolarIconsBold.user,
        titulo: 'Cuenta',
        itemsSubmenu: [
          ChildrenItem(
            color: theme.primary,
            iconoImagen: SolarIconsOutline.user,
            iconoImagenSeleccionada: SolarIconsBold.user,
            titulo: 'Perfil',
            children: const KeepAlivePage(child: Perfil()),
          ),
          ChildrenItem(
            color: theme.primary,
            iconoImagen: SolarIconsOutline.password,
            iconoImagenSeleccionada: SolarIconsBold.password,
            titulo: 'Contraseña',
            children: const CambiarContrasena(),
          ),
          ChildrenItem(
            color: theme.primary,
            iconoImagen: SolarIconsOutline.logout,
            iconoImagenSeleccionada: SolarIconsBold.logout,
            titulo: 'Cerrar sesión',
            children: const Micuenta(),
          ),
        ],
      ),
    ];

List<ChildrenItem> _adminMenu(ThemeController theme) => [
      ChildrenItem(
        iconoImagen: PhosphorIconsRegular.users,
        iconoImagenSeleccionada: PhosphorIconsFill.users,
        titulo: 'Usuarios',
        children: KeepAlivePage(
          child: RoleTrayPlaceholder(
            title: 'Usuarios',
            description:
                'Gestiona altas, bajas y roles de usuarios. Bandeja inicial sin datos.',
            actions: const [
              'Crear/editar usuarios (POST/PATCH /usuarios)',
              'Activar o desactivar usuarios',
              'Filtrar por rol permitido: ADMIN, SUPERVISOR, MEDICO',
            ],
          ),
        ),
      ),
      ChildrenItem(
        iconoImagen: PhosphorIconsRegular.tag,
        iconoImagenSeleccionada: PhosphorIconsFill.tag,
        titulo: 'Etiquetas',
        children: KeepAlivePage(
          child: RoleTrayPlaceholder(
            title: 'Etiquetas',
            description: 'Crea y organiza etiquetas para clasificar citas.',
            actions: const [
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
        children: KeepAlivePage(
          child: RoleTrayPlaceholder(
            title: 'Agrupadores',
            description: 'Organiza campañas o bloques para citas.',
            actions: const [
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
        children: KeepAlivePage(
          child: RoleTrayPlaceholder(
            title: 'Citas (Administrador)',
            description: 'Bandeja vacía para monitorear y gestionar todas las citas.',
            actions: const [
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
        iconoImagen: PhosphorIconsRegular.calendarPlus,
        iconoImagenSeleccionada: PhosphorIconsFill.calendarPlus,
        titulo: 'Citas',
        children: KeepAlivePage(
          child: RoleTrayPlaceholder(
            title: 'Citas (Supervisor)',
            description:
                'Crear, ver y administrar citas. Bandeja inicial sin registros.',
            actions: const [
              'Crear citas para médicos (POST /citas)',
              'Ver todas las citas (GET /citas)',
              'Reprogramar o cancelar (PATCH /citas/:id/reprogramar | /cancelar)',
              'Asignar etiquetas a citas (PATCH /citas/:id/etiquetas)',
            ],
          ),
        ),
      ),
    ];

List<ChildrenItem> _medicoMenu(ThemeController theme) => [
      ChildrenItem(
        iconoImagen: SolarIconsOutline.calendarSearch,
        iconoImagenSeleccionada: SolarIconsBold.calendarSearch,
        titulo: 'Mis citas',
        children: KeepAlivePage(
          child: RoleTrayPlaceholder(
            title: 'Mis citas (Médico)',
            description:
                'Revisa y administra únicamente tus citas. Bandeja vacía por ahora.',
            actions: const [
              'Listar mis citas (GET /citas/mis-citas)',
              'Cambiar estado (PATCH /citas/:id/estado)',
              'Reprogramar (PATCH /citas/:id/reprogramar)',
              'Agregar etiquetas (PATCH /citas/:id/etiquetas)',
            ],
          ),
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
                  _infoRow('Rol activo',
                      activeRoleLabel.isNotEmpty ? activeRoleLabel : '-'),
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

class _SubmoduleTrayGrid extends StatelessWidget {
  const _SubmoduleTrayGrid({
    required this.moduleLabel,
    required this.subModules,
    required this.theme,
  });

  final String moduleLabel;
  final List<SubModulo> subModules;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    final sortedSubmodules = [...subModules]
      ..sort((a, b) => (a.propiedades?.orden ?? 0)
          .compareTo(b.propiedades?.orden ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moduleLabel,
            style: TextStyle(
              color: theme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: sortedSubmodules
                .map((subModule) => _buildTray(context, subModule))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTray(BuildContext context, SubModulo subModule) {
    final blueprint = _resolveTrayBlueprint(subModule);

    return SizedBox(
      width: 360,
      child: Card(
        elevation: 2,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: 320,
          child: RoleTrayPlaceholder(
            title: blueprint.title,
            description: blueprint.description,
            actions: blueprint.actions,
            leadingIcon: blueprint.icon,
          ),
        ),
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
  final description = subModule.propiedades?.descripcion ??
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
