import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/modulo.dart';
import 'package:red_neuro_app/src/models/rol.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/auth/auth_service.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:red_neuro_app/src/ui/pages/perfil/componentes/perfil_info_card.dart';
import 'package:red_neuro_app/src/ui/pages/perfil/perfil_service.dart';

GlobalKey<ScaffoldMessengerState> perfilMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  static const int _maxAvatarSizeBytes = 5 * 1024 * 1024;
  static const List<String> _allowedAvatarExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  Usuario? _profile;
  List<Rol> _roles = <Rol>[];
  String? _activeRoleId;
  bool _changingRole = false;
  bool _updatingPhoto = false;
  int _avatarVersion = DateTime.now().millisecondsSinceEpoch;
  String? _avatarFailedUrl;
  final Map<String, Uint8List?> _avatarCache = <String, Uint8List?>{};
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
            esSupervisor: false,
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

  Future<void> _pickAndUploadPhoto() async {
    if (_updatingPhoto) return;

    final ThemeController theme = ThemeController.instance;

    // 1) Esto es un async gap, aún no tocaste UI “peligrosa”
    final FilePickerResult? selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedAvatarExtensions,
      allowMultiple: false,
    );

    if (!mounted) return; // <- recomendable tras el await del picker
    if (selected == null || selected.files.isEmpty) return;

    final PlatformFile platformFile = selected.files.first;
    final String extension = (platformFile.extension ?? '').toLowerCase();

    if (!_allowedAvatarExtensions.contains(extension)) {
      showSnackBar(
        perfilMessenger,
        'Formato no permitido. Usa JPG, JPEG, PNG o WEBP.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }

    if (platformFile.path == null || platformFile.path!.trim().isEmpty) {
      showSnackBar(
        perfilMessenger,
        'No se pudo leer el archivo seleccionado.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }

    final File foto = File(platformFile.path!);
    if (!foto.existsSync()) {
      showSnackBar(
        perfilMessenger,
        'El archivo no existe o no está disponible.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }

    final int fileSize = foto.lengthSync();
    if (fileSize <= 0 || fileSize > _maxAvatarSizeBytes) {
      showSnackBar(
        perfilMessenger,
        'La imagen debe pesar máximo 5 MB.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }

    setState(() => _updatingPhoto = true);

    // Captura el service ANTES del await de red
    final PerfilService service = PerfilService('', context);

    try {
      final ResponseApi response = await service.actualizarFotoPerfil(foto);

      if (!mounted) return;

      final bool synced = await _refreshProfileAfterPhotoChange(service);
      if (!mounted) return;

      showSnackBar(
        perfilMessenger,
        synced
            ? (response.status == StatusNetwork.connected
                  ? response.message
                  : 'Foto actualizada y perfil refrescado.')
            : (response.status == StatusNetwork.connected
                  ? 'La foto se actualizó, pero no se pudo refrescar el perfil.'
                  : response.message),
        state: synced ? StatusSnackBar.success : StatusSnackBar.error,
        colorText: theme.white,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        perfilMessenger,
        'No se pudo actualizar la foto: $e',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      if (mounted) {
        setState(() => _updatingPhoto = false);
      }
    }
  }

  Future<void> _deletePhoto() async {
    if (_updatingPhoto) return;

    final ThemeController theme = ThemeController.instance;
    setState(() => _updatingPhoto = true);

    try {
      final PerfilService service = PerfilService('', context);
      final ResponseApi response = await service.eliminarFotoPerfil();

      if (!mounted) return;

      final bool synced = await _refreshProfileAfterPhotoChange(service);
      if (synced) {
        showSnackBar(
          perfilMessenger,
          response.status == StatusNetwork.connected
              ? response.message
              : 'Foto eliminada y perfil refrescado.',
          state: StatusSnackBar.success,
          colorText: theme.white,
        );
      } else {
        showSnackBar(
          perfilMessenger,
          response.status == StatusNetwork.connected
              ? 'La foto se eliminó, pero no se pudo refrescar el perfil.'
              : response.message,
          state: StatusSnackBar.error,
          colorText: theme.white,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        perfilMessenger,
        'No se pudo eliminar la foto: $e',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      if (mounted) {
        setState(() => _updatingPhoto = false);
      }
    }
  }

  Future<void> _applyProfileUpdate(Usuario refreshed) async {
    await Auth.instance.updateUser(refreshed);
    if (!mounted) return;

    setState(() {
      _profile = refreshed;
      _roles = refreshed.roles;
      _activeRoleId =
          refreshed.idRol ?? (_roles.isNotEmpty ? _roles.first.idRol : '');
      _avatarVersion = DateTime.now().millisecondsSinceEpoch;
      _avatarFailedUrl = null;
      _avatarCache.clear();
    });
  }

  Future<bool> _refreshProfileAfterPhotoChange(PerfilService service) async {
    for (int intentos = 0; intentos < 2; intentos++) {
      final Usuario? refreshed = await service.refrescarPerfilDesdeApi();
      if (refreshed != null && mounted) {
        await _applyProfileUpdate(refreshed);
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  String? _avatarUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;

    final String normalized = rawUrl.startsWith('http')
        ? rawUrl
        : '${Constantes.apiUrl}$rawUrl';

    final Uri? uri = Uri.tryParse(normalized);
    if (uri == null) return null;

    final Map<String, String> params = <String, String>{
      ...uri.queryParameters,
      'v': '$_avatarVersion',
    };

    return uri.replace(queryParameters: params).toString();
  }

  Future<Uint8List?> _fetchAvatarBytes(String url) async {
    if (_avatarCache.containsKey(url)) {
      return _avatarCache[url];
    }

    final HttpClient client = HttpClient();
    try {
      final Uri? uri = Uri.tryParse(url);
      if (uri == null) {
        _avatarCache[url] = null;
        return null;
      }

      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        _avatarCache[url] = null;
        await response.drain<void>();
        return null;
      }

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
      );
      _avatarCache[url] = bytes;
      return bytes;
    } catch (_) {
      _avatarCache[url] = null;
      return null;
    } finally {
      client.close(force: true);
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
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.brightness,
      builder: (BuildContext context, bool _, Widget? child) {
        final ThemeController theme = ThemeController.instance;
        final Usuario profile = _profile ?? Auth.instance.profile;

        if (_loading && _profile == null) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Center(
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        }

        final bool hasMultipleRoles = _roles.length > 1;
        final String? avatarUrl = _avatarUrl(profile.urlFoto);
        final bool showRemoteAvatar =
            avatarUrl != null && avatarUrl != _avatarFailedUrl;

        return ScaffoldMessenger(
          key: perfilMessenger,
          child: Scaffold(
            backgroundColor: theme.background,
            appBar: TrayModuleHeader(
              titulo: 'Configuración',
              subtitulo: 'Administra tu perfil y seguridad de tu cuenta.',
              isCompact: MediaQuery.of(context).size.width < 560,
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: <Widget>[
                          Container(
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
                            child: Stack(
                              children: <Widget>[
                                Positioned.fill(
                                  child: ClipOval(
                                    child: showRemoteAvatar
                                        ? FutureBuilder<Uint8List?>(
                                            future: _fetchAvatarBytes(
                                              avatarUrl,
                                            ),
                                            builder:
                                                (
                                                  BuildContext context,
                                                  AsyncSnapshot<Uint8List?>
                                                  snapshot,
                                                ) {
                                                  final Uint8List? bytes =
                                                      snapshot.data;
                                                  if (snapshot.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      bytes == null &&
                                                      mounted &&
                                                      _avatarFailedUrl !=
                                                          avatarUrl) {
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback((
                                                          _,
                                                        ) {
                                                          if (!mounted) return;
                                                          setState(() {
                                                            _avatarFailedUrl =
                                                                avatarUrl;
                                                          });
                                                        });
                                                  }

                                                  if (bytes != null) {
                                                    return Image.memory(
                                                      bytes,
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true,
                                                    );
                                                  }

                                                  return _buildAvatarFallback(
                                                    theme,
                                                    profile,
                                                  );
                                                },
                                          )
                                        : _buildAvatarFallback(theme, profile),
                                  ),
                                ),
                                if (_updatingPhoto)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: theme.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: <Widget>[
                              FilledButton.icon(
                                onPressed: _updatingPhoto
                                    ? null
                                    : _pickAndUploadPhoto,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Cambiar foto'),
                                style: _profilePrimaryButtonStyle(theme),
                              ),
                              if (profile.urlFoto != null &&
                                  profile.urlFoto!.trim().isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: _updatingPhoto
                                      ? null
                                      : _deletePhoto,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Quitar'),
                                  style: _profileDangerButtonStyle(theme),
                                ),
                            ],
                          ),
                        ],
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
      },
    );
  }
}

class _ThemePreference extends StatelessWidget {
  const _ThemePreference();

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;

    return _ProfileSectionCard(
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

    return _ProfileSectionCard(
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
              esSupervisor: false,
              modulos: const <Modulo>[],
            ),
    );

    return _ProfileSectionCard(
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
              children: roles.map((Rol rol) {
                final bool isSelected = rol.idRol == activeRoleId;
                return isSelected
                    ? FilledButton(
                        onPressed: null,
                        style: _roleFilledButtonStyle(theme),
                        child: Text(rol.rol.isEmpty ? 'Rol' : rol.rol),
                      )
                    : OutlinedButton(
                        onPressed: changing
                            ? null
                            : () => onRoleSelected?.call(rol.idRol),
                        style: _roleOutlinedButtonStyle(theme),
                        child: Text(rol.rol.isEmpty ? 'Rol' : rol.rol),
                      );
              }).toList(),
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
                    style: TextStyle(
                      color: theme.fontColor.withValues(alpha: 0.7),
                    ),
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

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.grey.withValues(alpha: 0.3)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

ButtonStyle _roleFilledButtonStyle(ThemeController theme) {
  return FilledButton.styleFrom(
    disabledBackgroundColor: theme.primary,
    disabledForegroundColor: theme.white,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

ButtonStyle _roleOutlinedButtonStyle(ThemeController theme) {
  return OutlinedButton.styleFrom(
    foregroundColor: theme.secondary,
    side: BorderSide(color: theme.grey.withValues(alpha: 0.4)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

ButtonStyle _profilePrimaryButtonStyle(ThemeController theme) {
  return FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

ButtonStyle _profileDangerButtonStyle(ThemeController theme) {
  return OutlinedButton.styleFrom(
    foregroundColor: theme.error,
    side: BorderSide(color: theme.error.withValues(alpha: 0.45)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

Widget _buildAvatarFallback(ThemeController theme, Usuario profile) {
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
