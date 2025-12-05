import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/modulo.dart';
import 'package:red_neuro_app/src/models/rol.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/auth/auth_service.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/badges/counter_badge.dart';
import 'package:red_neuro_app/src/ui/common/keep_alive_page.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
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
  bool _changingRole = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _configureMenu();
    });
  }

  Future<void> _configureMenu() async {
    final user = await Auth.instance.profileAsync();
    final List<Rol> roles = user.roles;
    final roleId = user.idRol ?? (roles.isNotEmpty ? roles.first.idRol : '');
    final selectedRole = _findRole(roles, roleId, user.rol);
    final resolvedRoleName = (selectedRole?.rol ?? user.rol ?? '').toUpperCase();

    setState(() {
      _userProfile = user;
      _availableRoles = roles;
      _currentRoleId = roleId;
      _currentRole = resolvedRoleName;
      _itemsMenu = _itemsByRole(
        user: user,
        selectedRole: selectedRole,
        overview: _buildUserOverview(user, roles, roleId),
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

  Widget _buildUserOverview(Usuario user, List<Rol> roles, String? activeRoleId) {
    return UserOverview(
      user: user,
      roles: roles,
      activeRoleId: activeRoleId,
      isSwitchingRole: _changingRole,
      onRoleSelected: (idRol) => _handleRoleChange(idRol),
    );
  }

  Future<void> _handleRoleChange(String idRol) async {
    if (_changingRole || idRol == _currentRoleId || !mounted) return;
    setState(() {
      _changingRole = true;
    });

    final service = AuthService(context);
    final response = await service.cambiarRol(idRol);

    if (!mounted) return;

    if (response.status == StatusNetwork.connected) {
      await Auth.instance.login(response.data);
      await _configureMenu();

      final selected = _findRole(_availableRoles, idRol, null);
      showSnackBar(
        homeMessenger,
        'Rol activo: ${selected?.rol ?? idRol}',
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
    } else {
      showSnackBar(
        homeMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    }

    if (!mounted) return;
    setState(() {
      _changingRole = false;
    });
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
  final actions = module.subModulos.isNotEmpty
      ? module.subModulos
          .map((sub) => '${sub.label} (${sub.url})')
          .toList()
      : ['Explora las opciones disponibles dentro del módulo ${module.nombre}.'];

  final title = module.nombre.isNotEmpty ? module.nombre : module.label;
  final description = module.propiedades?.descripcion ??
      'Módulo ${module.label} sin descripción detallada. Bandeja vacía por ahora.';

  return ChildrenItem(
    iconoImagen: _moduleIconData(module.propiedades?.icono),
    iconoImagenSeleccionada: _moduleIconData(
      module.propiedades?.icono,
      filled: true,
    ),
    titulo: module.label.isNotEmpty ? module.label : module.nombre,
    color: theme.primary,
    children: KeepAlivePage(
      child: RoleTrayPlaceholder(
        title: title,
        description: description,
        actions: actions,
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
    required this.roles,
    required this.activeRoleId,
    required this.onRoleSelected,
    required this.isSwitchingRole,
  });

  final Usuario user;
  final List<Rol> roles;
  final String? activeRoleId;
  final ValueChanged<String> onRoleSelected;
  final bool isSwitchingRole;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final fullName = [
      user.nombres,
      user.primerApellido,
      user.segundoApellido,
    ].where((value) => value.trim().isNotEmpty).join(' ');
    final currentRole = roles.firstWhere(
      (r) => r.idRol == activeRoleId,
      orElse: () => roles.isNotEmpty ? roles.first : Rol(
        idRol: user.idRol ?? '',
        idUsuarioRol: user.idUsuarioRol ?? '',
        rol: user.rol ?? '',
        nombre: user.rol ?? '',
        descripcion: '',
        modulos: const [],
      ),
    );

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
                  _infoRow('Rol activo', currentRole.rol.isNotEmpty ? currentRole.rol : (user.rol ?? '-')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (roles.isNotEmpty) ...[
            Text(
              'Roles disponibles',
              style: TextStyle(
                color: theme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map(
                    (rol) => ChoiceChip(
                      label: Text(rol.rol.isEmpty ? 'Rol' : rol.rol),
                      selected: rol.idRol == activeRoleId,
                      selectedColor: theme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: rol.idRol == activeRoleId
                            ? theme.primary
                            : theme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        if (selected && rol.idRol.isNotEmpty && !isSwitchingRole) {
                          onRoleSelected(rol.idRol);
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
            if (isSwitchingRole) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Actualizando rol...',
                    style: TextStyle(color: theme.secondary),
                  ),
                ],
              ),
            ],
          ],
          if (roles.isEmpty)
            Text(
              'No se encontraron roles adicionales para este usuario.',
              style: TextStyle(color: theme.secondary),
            ),
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
