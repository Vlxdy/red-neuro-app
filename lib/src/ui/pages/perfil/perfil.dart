import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/modulo.dart';
import 'package:red_neuro_app/src/models/rol.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/auth/auth_service.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:red_neuro_app/src/ui/pages/perfil/componentes/perfil_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

GlobalKey<ScaffoldMessengerState> perfilMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  Usuario? _profile;
  List<Rol> _roles = <Rol>[];
  String? _activeRoleId;
  bool _changingRole = false;
  bool _loading = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final Usuario profile = await Auth.instance.profileAsync();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _roles = profile.roles;
      _activeRoleId =
          profile.idRol ?? (_roles.isNotEmpty ? _roles.first.idRol : '');
      _loading = false;
    });
  }

  Future<void> _changeRole(String idRol) async {
    if (_changingRole || idRol == _activeRoleId || !mounted) return;
    setState(() {
      _changingRole = true;
    });

    final ThemeController theme = ThemeController.instance;
    final AuthService service = AuthService(context);

    try {
      final ResponseApi response = await service.cambiarRol(idRol);

      if (!mounted) return;

      if (response.status == StatusNetwork.connected) {
        await Auth.instance.login(response.data);
        await _loadProfile();

        final Rol selectedRole = _roles.firstWhere(
          (Rol r) => r.idRol == idRol,
          orElse: () => Rol(
            idRol: idRol,
            idUsuarioRol: '',
            rol: '',
            nombre: '',
            descripcion: '',
            modulos: const <Modulo>[],
          ),
        );

        showSnackBar(
          perfilMessenger,
          'Rol activo: ${selectedRole.rol.isEmpty ? idRol : selectedRole.rol}',
          state: StatusSnackBar.success,
          colorText: theme.white,
        );
      } else {
        showSnackBar(
          perfilMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        perfilMessenger,
        'No se pudo cambiar el rol: $e',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingRole = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);

    final ThemeController theme = ThemeController.instance;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final String? error = await Auth.instance.logout();
      if (error != null && mounted) {
        showSnackBar(
          perfilMessenger,
          error,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
      }
    }

    if (mounted) setState(() => _loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;
    final Usuario profile = _profile ?? Auth.instance.profile;

    if (_loading && _profile == null) {
      return Scaffold(
        backgroundColor: theme.background,
        body: Center(child: CircularProgressIndicator(color: theme.primary)),
      );
    }

    final bool hasMultipleRoles = _roles.length > 1;

    return ScaffoldMessenger(
      key: perfilMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: theme.isDark
                ? Brightness.dark
                : Brightness.light,
            statusBarColor: theme.transparent,
          ),
          backgroundColor: theme.transparent,
          centerTitle: true,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: theme.black.withValues(
                            alpha: theme.isLight ? 0.1 : 0.4,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child:
                          profile.urlFoto != null &&
                              profile.urlFoto!.isNotEmpty &&
                              Uri.tryParse(profile.urlFoto!) != null
                          ? Image.network(
                              profile.urlFoto!.startsWith('http')
                                  ? profile.urlFoto!
                                  : '${Constantes.apiUrl}${profile.urlFoto!}',
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) => _buildAvatarFallback(theme, profile),
                            )
                          : _buildAvatarFallback(theme, profile),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "${profile.nombres} ${profile.primerApellido} ${profile.segundoApellido}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.fontColor,
                  ),
                ),
                const SizedBox(height: 20),
                PerfilInfoCard(
                  bgColor: theme.bgCard,
                  borderColor: theme.grey.withValues(alpha: .4),
                  headerIcon: Icons.person_outline_rounded,
                  headerTitle: 'Datitos personales',
                  items: <Map<String, dynamic>>[
                    <String, dynamic>{
                      "clave": "Nombres",
                      "valor":
                          "${profile.nombres} ${profile.primerApellido} ${profile.segundoApellido}",
                    },
                    <String, dynamic>{
                      "clave": "Fecha de nacimiento",
                      "valor": profile.fechaNacimiento,
                    },
                  ],
                ),
                const SizedBox(height: 20),
                PerfilInfoCard(
                  bgColor: theme.bgCard,
                  borderColor: theme.grey.withValues(alpha: .4),
                  headerIcon: Icons.contact_page_outlined,
                  headerTitle: 'Datos de contacto',
                  items: <Map<String, dynamic>>[
                    <String, dynamic>{
                      "clave": "Celular",
                      "valor": profile.telefono,
                    },
                    <String, dynamic>{
                      "clave": "Correo electrónico",
                      "valor": profile.correoElectronico,
                    },
                  ],
                ),
                const SizedBox(height: 20),
                _RoleCard(
                  theme: theme,
                  roles: _roles,
                  activeRoleId: _activeRoleId,
                  changing: _changingRole,
                  onRoleSelected: hasMultipleRoles ? _changeRole : null,
                ),
                const SizedBox(height: 20),
                const _ThemePreference(),
                const SizedBox(height: 20),
                _SessionActions(
                  onChangePassword: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const CambiarContrasena(),
                    ),
                  ),
                  onLogout: _logout,
                  loggingOut: _loggingOut,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreference extends StatelessWidget {
  const _ThemePreference();

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.grey.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.isLight
                ? theme.black.withValues(alpha: 0.05)
                : theme.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Preferencias',
            style: TextStyle(
              color: theme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: theme.brightness,
            builder: (BuildContext context, bool isLight, Widget? child) {
              final bool isDark = !isLight;

              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.primary,
                ),
                title: const Text('Tema oscuro'),
                subtitle: Text(
                  isDark ? 'Activado' : 'Desactivado',
                  style: TextStyle(color: theme.grey),
                ),
                value: isDark,
                onChanged: (_) => theme.changeTheme(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SessionActions extends StatelessWidget {
  const _SessionActions({
    required this.onChangePassword,
    required this.onLogout,
    required this.loggingOut,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.grey.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.isLight
                ? theme.black.withValues(alpha: 0.05)
                : theme.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Seguridad de la cuenta',
            style: TextStyle(
              color: theme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline, color: theme.primary),
            title: const Text('Cambiar contraseña'),
            subtitle: const Text('Actualiza tus credenciales de acceso.'),
            onTap: onChangePassword,
          ),
          Divider(color: theme.grey.withValues(alpha: 0.2)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: theme.error),
            title: const Text('Cerrar sesión'),
            subtitle: const Text('Finaliza la sesión actual de manera segura.'),
            trailing: loggingOut
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.error,
                    ),
                  )
                : null,
            onTap: loggingOut ? null : onLogout,
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.theme,
    required this.roles,
    required this.activeRoleId,
    required this.changing,
    required this.onRoleSelected,
  });

  final ThemeController theme;
  final List<Rol> roles;
  final String? activeRoleId;
  final bool changing;
  final ValueChanged<String>? onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final Rol activeRole = roles.firstWhere(
      (Rol r) => r.idRol == activeRoleId,
      orElse: () => roles.isNotEmpty
          ? roles.first
          : Rol(
              idRol: activeRoleId ?? '',
              idUsuarioRol: '',
              rol: '',
              nombre: '',
              descripcion: '',
              modulos: const <Modulo>[],
            ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.grey.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.isLight
                ? theme.black.withValues(alpha: 0.05)
                : theme.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Rol activo',
                style: TextStyle(
                  color: theme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activeRole.rol.isEmpty ? 'Sin rol' : activeRole.rol,
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Elige otro rol para actualizar los módulos visibles.',
            style: TextStyle(
              color: theme.fontColor.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          if (onRoleSelected == null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Este usuario solo tiene un rol asignado.',
              style: TextStyle(color: theme.fontColor.withValues(alpha: 0.7)),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map(
                    (Rol rol) => ChoiceChip(
                      label: Text(rol.rol.isEmpty ? 'Rol' : rol.rol),
                      selected: rol.idRol == activeRoleId,
                      selectedColor: theme.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: rol.idRol == activeRoleId
                            ? theme.primary
                            : theme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (bool selected) {
                        if (selected && !changing) {
                          onRoleSelected?.call(rol.idRol);
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
            if (changing) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
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
                    'Cambiando rol...',
                    style: TextStyle(color: theme.fontColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Widget _buildAvatarFallback(ThemeController theme, dynamic profile) {
  return Container(
    color: theme.primary,
    alignment: Alignment.center,
    child: Text(
      '${profile.nombres.isNotEmpty ? profile.nombres[0] : ''}'
      '${profile.primerApellido.isNotEmpty ? profile.primerApellido[0] : ''}',
      style: TextStyle(
        color: theme.white,
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
