import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:red_neuro_app/src/ui/common/components/tray_ui_helpers.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/utils/role_utils.dart';
import 'package:red_neuro_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena.dart';
import 'package:red_neuro_app/src/ui/pages/perfil/componentes/perfil_info_card.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/perfil/perfil_service.dart';
import 'package:red_neuro_app/src/plugins/seguridad/seguridad.dart';

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
  bool? _biometricAvailable;
  bool? _biometricLoginEnabled;
  bool _updatingBiometricPreference = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSecurityPreferences();
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

  Future<void> _loadSecurityPreferences() async {
    final bool hasDeviceSecurity = await Seguridad.instance.hasDeviceSecurity;
    final bool fingerprintEnabled =
        await Seguridad.instance.hasFingeprintEnabled;

    if (!mounted) return;
    setState(() {
      _biometricAvailable = hasDeviceSecurity;
      _biometricLoginEnabled = hasDeviceSecurity ? fingerprintEnabled : false;
    });
  }

  Future<void> _updateBiometricLogin(bool enabled) async {
    if (_updatingBiometricPreference) return;

    final ThemeController theme = ThemeController.instance;
    final bool hasDeviceSecurity = await Seguridad.instance.hasDeviceSecurity;

    if (!mounted) return;

    if (!hasDeviceSecurity) {
      setState(() {
        _biometricAvailable = false;
        _biometricLoginEnabled = false;
      });
      showSnackBar(
        perfilMessenger,
        'Este dispositivo no tiene seguridad de bloqueo disponible.',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
      return;
    }

    setState(() {
      _updatingBiometricPreference = true;
    });

    try {
      await Seguridad.instance.updateFingeprint(enabled);
      if (!mounted) return;
      setState(() {
        _biometricAvailable = true;
        _biometricLoginEnabled = enabled;
      });
      showSnackBar(
        perfilMessenger,
        enabled
            ? 'El desbloqueo con seguridad del dispositivo quedó habilitado para esta cuenta.'
            : 'El desbloqueo con seguridad del dispositivo quedó como opcional y desactivado.',
        state: StatusSnackBar.success,
        colorText: theme.white,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        perfilMessenger,
        'No se pudo actualizar la preferencia de desbloqueo: $e',
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingBiometricPreference = false;
        });
      }
    }
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
          'Rol activo: ${_humanRoleLabel(selectedRole)}',
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

  Future<void> _copyField(String field, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!mounted) return;
    showCopiedMessage(perfilMessenger, field.toLowerCase());
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_updatingPhoto) return;

    final ThemeController theme = ThemeController.instance;

    final FilePickerResult? selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedAvatarExtensions,
      allowMultiple: false,
    );

    if (!mounted) return;
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
          return TemplatePage(
            showEnvironmentBanner: false,
            page: Scaffold(
              backgroundColor: theme.transparent,
              body: Center(
                child: CircularProgressIndicator(color: theme.primary),
              ),
            ),
          );
        }

        final bool hasMultipleRoles = _roles.length > 1;
        final String? avatarUrl = _avatarUrl(profile.urlFoto);
        final bool showRemoteAvatar =
            avatarUrl != null && avatarUrl != _avatarFailedUrl;
        final String fullName = _fullName(profile);
        final Rol? activeRole = _resolveActiveRole();
        final String activeRoleLabel = _humanRoleLabel(activeRole);
        final String roleDescription = _humanRoleDescription(activeRole);
        final PackageInfo appInfo = Auth.instance.appInfo;

        return TemplatePage(
          showEnvironmentBanner: false,
          page: ScaffoldMessenger(
            key: perfilMessenger,
            child: Scaffold(
              backgroundColor: theme.transparent,
              appBar: TrayModuleHeader(
                titulo: 'Perfil',
                subtitulo: 'Administra tu perfil y la seguridad de tu cuenta.',
                isCompact: MediaQuery.of(context).size.width < 560,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  children: <Widget>[
                    _ProfileHeroCard(
                      theme: theme,
                      fullName: fullName,
                      roleLabel: activeRoleLabel,
                      roleDescription: roleDescription,
                      avatar: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: theme.black.withValues(
                                alpha: theme.isLight ? 0.12 : 0.34,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.45),
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: ClipOval(
                                child: showRemoteAvatar
                                    ? FutureBuilder<Uint8List?>(
                                        future: _fetchAvatarBytes(avatarUrl),
                                        builder: (
                                          BuildContext context,
                                          AsyncSnapshot<Uint8List?> snapshot,
                                        ) {
                                          final Uint8List? bytes = snapshot.data;
                                          if (snapshot.connectionState ==
                                                  ConnectionState.done &&
                                              bytes == null &&
                                              mounted &&
                                              _avatarFailedUrl != avatarUrl) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (!mounted) return;
                                              setState(() {
                                                _avatarFailedUrl = avatarUrl;
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
                                    color: theme.black.withValues(alpha: 0.35),
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
                      actions: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed:
                                _updatingPhoto ? null : _pickAndUploadPhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Cambiar foto'),
                            style: _profilePrimaryButtonStyle(theme),
                          ),
                          if (profile.urlFoto != null &&
                              profile.urlFoto!.trim().isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: _updatingPhoto ? null : _deletePhoto,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Quitar'),
                              style: _profileDangerButtonStyle(theme),
                            ),
                        ],
                      ),
                      summaryItems: <_ProfileSummaryItemData>[
                        _ProfileSummaryItemData(
                          icon: Icons.email_outlined,
                          label: 'Correo',
                          value: _fallbackValue(profile.correoElectronico),
                        ),
                        _ProfileSummaryItemData(
                          icon: Icons.phone_outlined,
                          label: 'Celular',
                          value: _fallbackValue(profile.telefono),
                        ),
                        _ProfileSummaryItemData(
                          icon: Icons.badge_outlined,
                          label: 'Documento',
                          value:
                              '${_fallbackValue(profile.tipoDocumento)} · ${_fallbackValue(profile.nroDocumento)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PerfilInfoCard(
                      bgColor: theme.bgCard,
                      borderColor: theme.grey.withValues(alpha: .22),
                      headerIcon: Icons.person_outline_rounded,
                      headerTitle: 'Información personal',
                      items: <Map<String, dynamic>>[
                        <String, dynamic>{
                          'clave': 'Nombre completo',
                          'valor': fullName,
                        },
                        <String, dynamic>{
                          'clave': 'Fecha de nacimiento',
                          'valor': _fallbackValue(profile.fechaNacimiento),
                        },
                      ],
                    ),
                    const SizedBox(height: 20),
                    PerfilInfoCard(
                      bgColor: theme.bgCard,
                      borderColor: theme.grey.withValues(alpha: .22),
                      headerIcon: Icons.contact_page_outlined,
                      headerTitle: 'Datos de contacto',
                      onCopy: _copyField,
                      items: <Map<String, dynamic>>[
                        <String, dynamic>{
                          'clave': 'Celular',
                          'valor': _fallbackValue(profile.telefono),
                          'copiable': true,
                        },
                        <String, dynamic>{
                          'clave': 'Correo electrónico',
                          'valor': _fallbackValue(profile.correoElectronico),
                          'copiable': true,
                        },
                      ],
                    ),
                    const SizedBox(height: 20),
                    PerfilInfoCard(
                      bgColor: theme.bgCard,
                      borderColor: theme.grey.withValues(alpha: .22),
                      headerIcon: Icons.info_outline_rounded,
                      headerTitle: 'Aplicación',
                      items: <Map<String, dynamic>>[
                        <String, dynamic>{
                          'clave': 'Versión',
                          'valor': appInfo.version,
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
                      biometricAvailable: _biometricAvailable,
                      biometricLoginEnabled: _biometricLoginEnabled,
                      updatingBiometricPreference: _updatingBiometricPreference,
                      onToggleBiometricLogin: _updateBiometricLogin,
                      onChangePassword: () async {
                        final dynamic result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                const CambiarContrasena(),
                          ),
                        );

                        if (!mounted || result is! Map<String, dynamic>) return;

                        final bool success = result['success'] == true;
                        final String message =
                            (result['message'] as String? ?? '').trim();
                        if (!success || message.isEmpty) return;

                        showSnackBar(
                          perfilMessenger,
                          message,
                          state: StatusSnackBar.success,
                          colorText: theme.white,
                        );
                      },
                      onLogout: _logout,
                      loggingOut: _loggingOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Rol? _resolveActiveRole() {
    if (_roles.isEmpty) return null;
    for (final Rol rol in _roles) {
      if (rol.idRol == _activeRoleId) {
        return rol;
      }
    }
    return _roles.first;
  }

  String _fullName(Usuario profile) {
    final List<String> parts = <String>[
      profile.nombres,
      profile.primerApellido,
      profile.segundoApellido,
    ].where((String value) => value.trim().isNotEmpty).toList();

    return parts.isEmpty ? 'Usuario sin nombre' : parts.join(' ');
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.theme,
    required this.fullName,
    required this.roleLabel,
    required this.roleDescription,
    required this.avatar,
    required this.actions,
    required this.summaryItems,
  });

  final ThemeController theme;
  final String fullName;
  final String roleLabel;
  final String roleDescription;
  final Widget avatar;
  final Widget actions;
  final List<_ProfileSummaryItemData> summaryItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.primary.withValues(alpha: theme.isLight ? 0.14 : 0.26),
            theme.bgCard,
            theme.primary.withValues(alpha: theme.isLight ? 0.05 : 0.14),
          ],
        ),
        border: Border.all(color: theme.primary.withValues(alpha: 0.18)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.black.withValues(alpha: theme.isLight ? 0.06 : 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          avatar,
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              roleLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: theme.fontColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            roleDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme.fontColor.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          actions,
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stackItems = constraints.maxWidth < 560;
              if (stackItems) {
                return Column(
                  children: summaryItems
                      .map(
                        (_ProfileSummaryItemData item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProfileSummaryItemCard(item: item),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: summaryItems
                    .map(
                      (_ProfileSummaryItemData item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _ProfileSummaryItemCard(item: item),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryItemData {
  const _ProfileSummaryItemData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _ProfileSummaryItemCard extends StatelessWidget {
  const _ProfileSummaryItemCard({required this.item});

  final _ProfileSummaryItemData item;

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.instance;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.bgCard2.withValues(alpha: theme.isLight ? 0.55 : 0.3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.grey.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: theme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: TextStyle(
                    color: theme.fontColor.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.fontColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.bgCard2.withValues(
                    alpha: theme.isLight ? 0.55 : 0.22,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.primary.withValues(
                      alpha: theme.isLight ? 0.12 : 0.2,
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Tema oscuro',
                            style: TextStyle(
                              color: theme.fontColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDark
                                ? 'Activo para una visualización más cómoda en ambientes con poca luz.'
                                : 'Activo el tema claro con colores alineados al estilo principal de la app.',
                            style: TextStyle(
                              color: theme.fontColor.withValues(alpha: 0.68),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch.adaptive(
                      value: isDark,
                      activeThumbColor: theme.primary,
                      activeTrackColor: theme.primary.withValues(alpha: 0.3),
                      inactiveThumbColor: theme.grey,
                      inactiveTrackColor: theme.grey.withValues(alpha: 0.3),
                      onChanged: (_) => theme.changeTheme(),
                    ),
                  ],
                ),
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
    required this.biometricAvailable,
    required this.biometricLoginEnabled,
    required this.updatingBiometricPreference,
    required this.onToggleBiometricLogin,
    required this.onChangePassword,
    required this.onLogout,
    required this.loggingOut,
  });

  final bool? biometricAvailable;
  final bool? biometricLoginEnabled;
  final bool updatingBiometricPreference;
  final ValueChanged<bool> onToggleBiometricLogin;
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.bgCard2.withValues(
                alpha: theme.isLight ? 0.55 : 0.22,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.fingerprint, color: theme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Desbloqueo con seguridad del dispositivo',
                        style: TextStyle(
                          color: theme.fontColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        biometricAvailable == false
                            ? 'Tu dispositivo no tiene bloqueo del sistema disponible, así que el inicio seguirá con contraseña.'
                            : biometricLoginEnabled == true
                                ? 'La app pedirá la seguridad del sistema para desbloquearse, ya sea reconocimiento facial, huella, patrón, PIN o el método disponible.'
                                : 'Este desbloqueo es opcional y ahora mismo está desactivado para esta cuenta.',
                        style: TextStyle(
                          color: theme.fontColor.withValues(alpha: 0.68),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (biometricAvailable == null || biometricLoginEnabled == null)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  )
                else
                  Switch.adaptive(
                    value: biometricLoginEnabled!,
                    activeThumbColor: theme.primary,
                    activeTrackColor: theme.primary.withValues(alpha: 0.3),
                    inactiveThumbColor: theme.grey,
                    inactiveTrackColor: theme.grey.withValues(alpha: 0.3),
                    onChanged: biometricAvailable == false ||
                            updatingBiometricPreference
                        ? null
                        : onToggleBiometricLogin,
                  ),
              ],
            ),
          ),
          Divider(color: theme.grey.withValues(alpha: 0.2)),
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

    final String activeRoleLabel = _humanRoleLabel(activeRole);
    final String activeRoleDescription = _humanRoleDescription(activeRole);

    return _ProfileSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.bgCard2.withValues(alpha: theme.isLight ? 0.52 : 0.22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.workspace_premium_outlined,
                        color: theme.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        activeRoleLabel,
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Tipo de acceso',
                  style: TextStyle(
                    color: theme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activeRoleDescription,
                  style: TextStyle(
                    color: theme.fontColor.withValues(alpha: 0.78),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            onRoleSelected == null
                ? 'Tu cuenta tiene un único perfil de acceso asignado.'
                : 'Si tienes varios perfiles, cambia aquí la vista y los módulos disponibles.',
            style: TextStyle(
              color: theme.fontColor.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (onRoleSelected != null) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: roles.map((Rol rol) {
                final bool isSelected = rol.idRol == activeRoleId;
                final String label = _humanRoleLabel(rol);
                return isSelected
                    ? FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        style: _roleFilledButtonStyle(theme),
                        label: Text(label),
                      )
                    : OutlinedButton(
                        onPressed: changing
                            ? null
                            : () => onRoleSelected?.call(rol.idRol),
                        style: _roleOutlinedButtonStyle(theme),
                        child: Text(label),
                      );
              }).toList(),
            ),
            if (changing) ...<Widget>[
              const SizedBox(height: 12),
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
                    'Actualizando perfil de acceso...',
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
      color: theme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

ButtonStyle _roleFilledButtonStyle(ThemeController theme) {
  return FilledButton.styleFrom(
    disabledBackgroundColor: theme.primary,
    disabledForegroundColor: theme.white,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

ButtonStyle _roleOutlinedButtonStyle(ThemeController theme) {
  return OutlinedButton.styleFrom(
    foregroundColor: theme.secondary,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    side: BorderSide(color: theme.grey.withValues(alpha: 0.45)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

ButtonStyle _profilePrimaryButtonStyle(ThemeController theme) {
  return FilledButton.styleFrom(
    backgroundColor: theme.primary,
    foregroundColor: theme.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

ButtonStyle _profileDangerButtonStyle(ThemeController theme) {
  return OutlinedButton.styleFrom(
    foregroundColor: theme.error,
    side: BorderSide(color: theme.error.withValues(alpha: 0.4)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

Widget _buildAvatarFallback(ThemeController theme, Usuario profile) {
  final String initials = _buildInitials(profile);
  return Container(
    color: theme.primary.withValues(alpha: 0.14),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: TextStyle(
        color: theme.primary,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

String _buildInitials(Usuario profile) {
  final String nombres = profile.nombres.trim();
  final String primerApellido = profile.primerApellido.trim();
  final String segundoApellido = profile.segundoApellido.trim();
  final String first = nombres.isNotEmpty ? nombres[0] : '';
  final String second = primerApellido.isNotEmpty
      ? primerApellido[0]
      : (segundoApellido.isNotEmpty ? segundoApellido[0] : '');
  final String initials = '$first$second'.trim().toUpperCase();
  return initials.isEmpty ? 'RN' : initials;
}

String _fallbackValue(String? value, {String empty = 'No disponible'}) {
  final String normalized = (value ?? '').trim();
  return normalized.isEmpty ? empty : normalized;
}

String _humanRoleLabel(Rol? rol) {
  if (rol == null) return 'Sin acceso asignado';

  final String source = _fallbackRoleSource(rol).toUpperCase();
  final String normalized = source
      .replaceAll('-', '_')
      .replaceAll(' ', '_')
      .replaceAll(RegExp(r'_+'), '_');

  switch (normalized) {
    case 'ADMIN':
    case 'ADMINISTRADOR':
    case 'JEFE':
    case 'COORDINADOR':
    case 'PERSONAL':
    case 'PROFESIONAL_INVITADO':
      return RoleUtils.roleLabel(normalized);
    case 'PACIENTE':
      return 'Paciente';
    case 'RECEPCION':
    case 'RECEPCIONISTA':
      return 'Recepción';
    default:
      return _toTitleCase(
        _fallbackValue(_fallbackRoleSource(rol), empty: 'Acceso general'),
      );
  }
}

String _humanRoleDescription(Rol? rol) {
  if (rol == null) {
    return 'Aún no se identificó un perfil de acceso para esta cuenta.';
  }

  final String source = _fallbackRoleSource(rol).toUpperCase();
  final String normalized = source
      .replaceAll('-', '_')
      .replaceAll(' ', '_')
      .replaceAll(RegExp(r'_+'), '_');

  switch (normalized) {
    case 'ADMIN':
    case 'ADMINISTRADOR':
      return 'Gestiona configuraciones, usuarios y módulos con acceso administrativo.';
    case 'JEFE':
      return 'Opera de forma global, incluyendo la gestión de personal.';
    case 'COORDINADOR':
      return 'Opera citas y pacientes, y puede consultar personal.';
    case 'PERSONAL':
      return 'Trabaja sobre sus asignaciones, pacientes y perfil.';
    case 'PROFESIONAL_INVITADO':
      return 'Trabaja sobre sus citas y pacientes asignados.';
    case 'PACIENTE':
      return 'Consulta tu información personal y el seguimiento de tus servicios.';
    case 'RECEPCION':
    case 'RECEPCIONISTA':
      return 'Administra agenda, registro y seguimiento de atención al usuario.';
    default:
      return _fallbackValue(
        rol.descripcion,
        empty: 'Este perfil define los módulos y permisos visibles en tu cuenta.',
      );
  }
}

String _fallbackRoleSource(Rol rol) {
  final List<String> candidates = <String>[rol.nombre, rol.rol, rol.descripcion];
  return candidates.firstWhere(
    (String value) => value.trim().isNotEmpty,
    orElse: () => '',
  );
}

String _toTitleCase(String value) {
  final String normalized = value
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
  if (normalized.isEmpty) return normalized;

  return normalized
      .split(' ')
      .map((String word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}
