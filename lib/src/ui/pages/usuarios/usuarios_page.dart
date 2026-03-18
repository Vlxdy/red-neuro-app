import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/utils/role_utils.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/usuarios/usuarios_service.dart';

final GlobalKey<ScaffoldMessengerState> usuariosMessenger =
    GlobalKey<ScaffoldMessengerState>();

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> with FormController {
  final _theme = ThemeController.instance;
  late final UsuariosService _service;

  List<Usuario> _usuarios = [];
  List<RolOption> _roles = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _processingEstado = false;
  String? _usuarioProcesandoId;
  bool _loadingRoles = false;
  bool _mostrarFiltros = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  String _filtro = '';
  String? _rolFiltro;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  String get _currentRole => _normalizarRol(Auth.instance.profile.rol ?? '');

  @override
  void initState() {
    super.initState();
    _service = UsuariosService(context);
    _cargarRoles();
    _cargarUsuarios();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 220 && _usuarios.length < _total) {
      _cargarUsuarios(page: _page + 1, append: true);
    }
  }

  Future<void> _cargarRoles() async {
    final roles = await _service.obtenerRoles();
    if (!mounted) return;
    setState(() {
      _roles = roles;
      _loadingRoles = false;
    });
  }

  Future<void> _cargarUsuarios({int? page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }

    final result = await _service.obtenerUsuarios(
      page: page ?? _page,
      limit: _limit,
      filtro: _filtro,
      rol: _rolFiltro,
    );

    if (!mounted) return;
    setState(() {
      _usuarios = append ? [..._usuarios, ...result.usuarios] : result.usuarios;
      _page = page ?? result.page;
      _limit = result.limit;
      _total = result.total;
      if (append) {
        _loadingMore = false;
      } else {
        _loading = false;
      }
    });

    if (result.status != StatusNetwork.connected) {
      showSnackBar(
        usuariosMessenger,
        result.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  List<RolOption> get _rolesVisibles {
    final permitidos = _rolesCreablesParaRolActual.toSet();
    if (permitidos.isEmpty) return const <RolOption>[];
    return _roles.where((rol) => permitidos.contains(_normalizarRol(rol.codigo))).toList();
  }

  String _normalizarRol(String rol) => RoleUtils.normalizeRole(rol);

  bool _esAdministrador(String rol) =>
      _normalizarRol(rol) == RoleUtils.administrador;

  bool _esRolPermitidoParaPersonal(String? rol) =>
      _rolesCreablesParaRolActual.contains(_normalizarRol(rol ?? ''));

  String _formatearRol(String rol) => RoleUtils.roleLabel(rol);

  List<String> get _rolesCreablesParaRolActual =>
      RoleUtils.creatableStaffRolesFor(_currentRole);

  DateTime? _parseFechaNacimiento(String value) {
    try {
      return _dateFormatter.parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  String _formatearFechaInicial(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }
    final limpio = value.trim();
    if (limpio.contains('/')) {
      return limpio;
    }
    try {
      final fecha = DateTime.parse(limpio);
      return _dateFormatter.format(fecha);
    } catch (_) {
      return limpio;
    }
  }

  String _validarFechaNacimiento(String? value, String alias) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    final fecha = _parseFechaNacimiento(value.trim());
    if (fecha == null) {
      return 'Ingresa una fecha válida (DD/MM/AAAA)';
    }
    final hoy = DateTime.now();
    final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
    final hoySolo = DateTime(hoy.year, hoy.month, hoy.day);
    if (!fechaSolo.isBefore(hoySolo)) {
      return 'La fecha debe ser anterior a la actual';
    }
    return '';
  }

  String _validarCorreo(String? value, String alias) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    final correo = value.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(correo)) {
      return 'Ingresa un correo electrónico válido';
    }
    return '';
  }

  Future<void> _seleccionarFecha(TextEditingController controller) async {
    final actual = _parseFechaNacimiento(controller.text.trim());
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime(hoy.year - 18, hoy.month, hoy.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
    );
    if (picked != null) {
      controller.text = _dateFormatter.format(picked);
    }
  }

  void _abrirFormulario({Usuario? usuario}) {
    final formKey = GlobalKey<FormState>();
    final nombres = TextEditingController(text: usuario?.nombres ?? '');
    final primerApellido = TextEditingController(
      text: usuario?.primerApellido ?? '',
    );
    final segundoApellido = TextEditingController(
      text: usuario?.segundoApellido ?? '',
    );
    final nroDocumento = TextEditingController(
      text: usuario?.nroDocumento ?? '',
    );
    final telefono = TextEditingController(text: usuario?.telefono ?? '');
    final correo = TextEditingController(
      text: usuario?.correoElectronico ?? '',
    );
    final fechaNacimiento = TextEditingController(
      text: _formatearFechaInicial(usuario?.fechaNacimiento),
    );
    final contrasena = TextEditingController();
    final repetirContrasena = TextEditingController();
    final selectedRoles = <String>{
      if (usuario != null) ...usuario.roles.map((rol) => rol.rol.toUpperCase()),
      if (usuario?.rol != null) usuario!.rol!.toUpperCase(),
    };
    String? rolSeleccionado = selectedRoles.isNotEmpty
        ? _normalizarRol(selectedRoles.first)
        : null;
    final rolesDisponibles = <RolOption>[
      ..._rolesVisibles,
      if (rolSeleccionado != null &&
          _rolesVisibles.every((rol) => rol.codigo != rolSeleccionado))
        RolOption(
          id: rolSeleccionado,
          codigo: rolSeleccionado,
          nombre: RoleUtils.roleLabel(rolSeleccionado),
        ),
    ];
    if (rolSeleccionado != null) {
      selectedRoles
        ..clear()
        ..add(rolSeleccionado);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            usuario == null
                                ? 'Registrar usuario'
                                : 'Editar usuario',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Datos personales',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextInput(
                                title: 'Nombres',
                                controller: nombres,
                                requiredData: true,
                                validate: (value, alias) =>
                                    (value?.isEmpty ?? true)
                                    ? 'Campo requerido'
                                    : '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextInput(
                                title: 'Primer apellido',
                                controller: primerApellido,
                                requiredData: true,
                                validate: (value, alias) =>
                                    (value?.isEmpty ?? true)
                                    ? 'Campo requerido'
                                    : '',
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            CustomTextInput(
                              title: 'Nombres',
                              controller: nombres,
                              requiredData: true,
                              validate: (value, alias) =>
                                  (value?.isEmpty ?? true)
                                  ? 'Campo requerido'
                                  : '',
                            ),
                            const SizedBox(height: 12),
                            CustomTextInput(
                              title: 'Primer apellido',
                              controller: primerApellido,
                              requiredData: true,
                              validate: (value, alias) =>
                                  (value?.isEmpty ?? true)
                                  ? 'Campo requerido'
                                  : '',
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextInput(
                                title: 'Segundo apellido',
                                controller: segundoApellido,
                                requiredData: true,
                                validate: (value, alias) =>
                                    (value?.isEmpty ?? true)
                                    ? 'Campo requerido'
                                    : '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextInput(
                                title: 'Número de documento',
                                controller: nroDocumento,
                                requiredData: true,
                                onlyNumbers: true,
                                validate: (value, alias) =>
                                    (value?.isEmpty ?? true)
                                    ? 'Campo requerido'
                                    : '',
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            CustomTextInput(
                              title: 'Segundo apellido',
                              controller: segundoApellido,
                              requiredData: true,
                              validate: (value, alias) =>
                                  (value?.isEmpty ?? true)
                                  ? 'Campo requerido'
                                  : '',
                            ),
                            const SizedBox(height: 12),
                            CustomTextInput(
                              title: 'Número de documento',
                              controller: nroDocumento,
                              requiredData: true,
                              onlyNumbers: true,
                              validate: (value, alias) =>
                                  (value?.isEmpty ?? true)
                                  ? 'Campo requerido'
                                  : '',
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextInput(
                                title: 'Teléfono',
                                controller: telefono,
                                onlyNumbers: true,
                                requiredData: true,
                                validate: (value, alias) =>
                                    (value?.isEmpty ?? true)
                                    ? 'Campo requerido'
                                    : '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextInput(
                                title: 'Correo electrónico',
                                controller: correo,
                                requiredData: true,
                                validate: _validarCorreo,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            CustomTextInput(
                              title: 'Teléfono',
                              controller: telefono,
                              onlyNumbers: true,
                              requiredData: true,
                              validate: (value, alias) =>
                                  (value?.isEmpty ?? true)
                                  ? 'Campo requerido'
                                  : '',
                            ),
                            const SizedBox(height: 12),
                            CustomTextInput(
                              title: 'Correo electrónico',
                              controller: correo,
                              requiredData: true,
                              validate: _validarCorreo,
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      CustomTextInput(
                        title: 'Fecha de nacimiento (DD/MM/AAAA)',
                        controller: fechaNacimiento,
                        requiredData: true,
                        placeholder: 'DD/MM/AAAA',
                        maxLength: 10,
                        textFiltering: RegExp(r'[0-9/]'),
                        onTap: () => _seleccionarFecha(fechaNacimiento),
                        validate: _validarFechaNacimiento,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Credenciales',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextInput(
                                title: 'Contraseña',
                                controller: contrasena,
                                obscure: true,
                                requiredData: usuario == null,
                                validate: (value, alias) {
                                  if (usuario != null &&
                                      (value?.isEmpty ?? true)) {
                                    return '';
                                  }
                                  return (value?.isEmpty ?? true)
                                      ? 'Campo requerido'
                                      : '';
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextInput(
                                title: 'Repetir contraseña',
                                controller: repetirContrasena,
                                obscure: true,
                                requiredData: usuario == null,
                                validate: (value, alias) {
                                  if (usuario != null &&
                                      (value?.isEmpty ?? true)) {
                                    return '';
                                  }
                                  return (value?.isEmpty ?? true)
                                      ? 'Campo requerido'
                                      : '';
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            CustomTextInput(
                              title: 'Contraseña',
                              controller: contrasena,
                              obscure: true,
                              requiredData: usuario == null,
                              validate: (value, alias) {
                                if (usuario != null &&
                                    (value?.isEmpty ?? true)) {
                                  return '';
                                }
                                return (value?.isEmpty ?? true)
                                    ? 'Campo requerido'
                                    : '';
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomTextInput(
                              title: 'Repetir contraseña',
                              controller: repetirContrasena,
                              obscure: true,
                              requiredData: usuario == null,
                              validate: (value, alias) {
                                if (usuario != null &&
                                    (value?.isEmpty ?? true)) {
                                  return '';
                                }
                                return (value?.isEmpty ?? true)
                                    ? 'Campo requerido'
                                    : '';
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Roles permitidos',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      if (_loadingRoles)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Selecciona un rol',
                            isDense: true,
                          ),
                          initialValue: rolSeleccionado,
                          items: rolesDisponibles
                              .map(
                                (rol) => DropdownMenuItem<String>(
                                  value: rol.codigo,
                                  child: Text(rol.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              rolSeleccionado = value;
                              selectedRoles.clear();
                              if (value != null) {
                                selectedRoles.add(value);
                              }
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SimpleButton(
                          title: usuario == null
                              ? 'Crear usuario'
                              : 'Guardar cambios',
                          preffixicon: usuario == null
                              ? PhosphorIconsFill.userPlus
                              : PhosphorIconsFill.floppyDisk,
                          fullWidth: false,
                          onTap: () async {
                            final isValid = validateForm(formKey);
                            if (!isValid) return;
                            if (rolSeleccionado == null ||
                                rolSeleccionado!.isEmpty) {
                              showSnackBar(
                                usuariosMessenger,
                                'Selecciona al menos un rol permitido',
                                state: StatusSnackBar.error,
                                colorText: _theme.white,
                              );
                              return;
                            }
                            if (!_esAdministrador(_currentRole)) {
                              final invalid = selectedRoles.any(
                                (rol) => !_esRolPermitidoParaPersonal(rol),
                              );
                              if (invalid) {
                                showSnackBar(
                                  usuariosMessenger,
                                  'Tu rol no puede asignar uno de los roles seleccionados',
                                  state: StatusSnackBar.error,
                                  colorText: _theme.white,
                                );
                                return;
                              }
                            }
                            if ((contrasena.text.isNotEmpty ||
                                    repetirContrasena.text.isNotEmpty) &&
                                contrasena.text != repetirContrasena.text) {
                              showSnackBar(
                                usuariosMessenger,
                                'Las contraseñas no coinciden',
                                state: StatusSnackBar.error,
                                colorText: _theme.white,
                              );
                              return;
                            }

                            final persona = {
                              'nombres': nombres.text.trim(),
                              'primerApellido': primerApellido.text.trim(),
                              'segundoApellido': segundoApellido.text.trim(),
                              'fechaNacimiento': fechaNacimiento.text.trim(),
                              'nroDocumento': nroDocumento.text.trim(),
                              'telefono': telefono.text.trim(),
                            };

                            Map<String, dynamic> body;
                            if (usuario == null) {
                              body = {
                                'persona': persona,
                                'correoElectronico': correo.text.trim(),
                                'contrasena': contrasena.text,
                                'repetirContrasena': repetirContrasena.text,
                                'roles': selectedRoles.toList(),
                              };
                            } else {
                              body = {
                                'persona': persona,
                                'correoElectronico': correo.text.trim(),
                                if (contrasena.text.isNotEmpty)
                                  'contrasena': contrasena.text,
                                if (repetirContrasena.text.isNotEmpty)
                                  'repetirContrasena': repetirContrasena.text,
                                'roles': selectedRoles.toList(),
                              };
                            }

                            Navigator.pop(context);
                            await _guardarUsuario(body, usuario);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _guardarUsuario(
    Map<String, dynamic> body,
    Usuario? usuario,
  ) async {
    try {
      final response = usuario == null
          ? await _service.crearUsuario(body)
          : await _service.actualizarUsuario(usuario.id ?? '', body);

      if (response.status == StatusNetwork.connected) {
        showSnackBar(
          usuariosMessenger,
          response.message,
          state: StatusSnackBar.success,
          colorText: _theme.white,
        );
        _cargarUsuarios();
      } else {
        showSnackBar(
          usuariosMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
      }
    } catch (e, stacktrace) {
      Logger.error('Error al guardar usuario $e');
      Logger.error('stacktrace $stacktrace');
      showSnackBar(
        usuariosMessenger,
        'No se pudo completar la operación',
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _cambiarEstado(Usuario usuario) async {
    if (_processingEstado) return;

    final activo = (usuario.estado ?? '').toUpperCase() == 'ACTIVO';
    final accion = activo ? 'inactivar' : 'activar';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${accion[0].toUpperCase()}${accion.substring(1)} usuario'),
        content: Text(
          '¿Confirmas que deseas $accion al usuario ${usuario.usuario ?? '-'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _processingEstado = true;
      _usuarioProcesandoId = usuario.id;
    });

    try {
      final response = activo
          ? await _service.inactivarUsuario(usuario.id ?? '')
          : await _service.activarUsuario(usuario.id ?? '');

      if (response.status == StatusNetwork.connected) {
        showSnackBar(
          usuariosMessenger,
          response.message,
          state: StatusSnackBar.success,
          colorText: _theme.white,
        );
        await _cargarUsuarios(page: 1);
      } else {
        showSnackBar(
          usuariosMessenger,
          response.message,
          state: StatusSnackBar.error,
          colorText: _theme.white,
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _processingEstado = false;
        _usuarioProcesandoId = null;
      });
    }
  }

  String _rolesTexto(Usuario usuario) {
    if (usuario.roles.isNotEmpty) {
      final roles = usuario.roles
          .map((rol) => _formatearRol(rol.rol))
          .where((rol) => rol.trim().isNotEmpty)
          .toSet()
          .toList();
      if (roles.isNotEmpty) {
        return roles.join(', ');
      }
    }
    final rolActivo = usuario.rol ?? '';
    if (rolActivo.trim().isEmpty) return '-';
    return _formatearRol(rolActivo);
  }

  Widget _buildEstadoChip(Usuario usuario) {
    final activo = (usuario.estado ?? '').toUpperCase() == 'ACTIVO';
    return Chip(
      label: Text((usuario.estado ?? '-').toUpperCase()),
      backgroundColor: (activo ? _theme.success : _theme.error).withValues(
        alpha: .15,
      ),
      labelStyle: TextStyle(
        color: activo ? _theme.success : _theme.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFiltros() {
    if (!_mostrarFiltros) return const SizedBox();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchController,
                enabled: !_processingEstado,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre o correo',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  setState(() {
                    _filtro = value.trim();
                  });
                  _cargarUsuarios(page: 1);
                },
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                decoration: const InputDecoration(
                  labelText: 'Filtrar por rol',
                  isDense: true,
                ),
                initialValue: _rolFiltro,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ..._roles.map(
                    (rol) => DropdownMenuItem<String?>(
                      value: rol.codigo,
                      child: Text(rol.nombre),
                    ),
                  ),
                ],
                onChanged: _processingEstado
                    ? null
                    : (value) {
                        setState(() {
                          _rolFiltro = value;
                        });
                        _cargarUsuarios(page: 1);
                      },
              ),
            ),
            SimpleButton(
              title: 'Buscar',
              preffixicon: Icons.search,
              fullWidth: false,
              onTap: () {
                if (_processingEstado) return;
                setState(() {
                  _filtro = _searchController.text.trim();
                });
                _cargarUsuarios(page: 1);
              },
            ),
            SimpleButton(
              title: 'Limpiar',
              preffixicon: Icons.clear,
              fullWidth: false,
              outlined: true,
              background: _theme.primary,
              onTap: () {
                if (_processingEstado) return;
                setState(() {
                  _filtro = '';
                  _rolFiltro = null;
                  _searchController.clear();
                });
                _cargarUsuarios(page: 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaUsuarios() {
    if (_loading && _usuarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _cargarUsuarios(page: 1),
      child: _usuarios.isEmpty
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No hay usuarios para mostrar.')),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _usuarios.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >= _usuarios.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final usuario = _usuarios[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    usuario.usuario ?? '-',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(usuario.correoElectronico),
                                  const SizedBox(height: 4),
                                  Text('Roles: ${_rolesTexto(usuario)}'),
                                ],
                              ),
                            ),
                            _buildEstadoChip(usuario),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: _processingEstado
                                  ? null
                                  : () => _abrirFormulario(usuario: usuario),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                            ),
                            TextButton.icon(
                              onPressed: _processingEstado
                                  ? null
                                  : () => _cambiarEstado(usuario),
                              icon: Icon(
                                (usuario.estado ?? '').toUpperCase() ==
                                        'ACTIVO'
                                    ? Icons.toggle_off
                                    : Icons.toggle_on,
                              ),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (usuario.estado ?? '').toUpperCase() ==
                                            'ACTIVO'
                                        ? 'Desactivar'
                                        : 'Activar',
                                  ),
                                  if (_processingEstado &&
                                      _usuarioProcesandoId == usuario.id) ...[
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompactHeader = MediaQuery.of(context).size.width < 560;
    final subtitle = _esAdministrador(_currentRole)
        ? 'Administra todos los roles disponibles'
        : 'El personal de salud con permisos administrativos gestiona usuarios del rol personal de salud';

    return ScaffoldMessenger(
      key: usuariosMessenger,
      child: TemplatePage(
        cargando: _processingEstado,
        showEnvironmentBanner: false,
        page: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
            titulo: 'Usuarios',
            subtitulo: subtitle,
            isCompact: isCompactHeader,
            actions: [
              IconButton(
                tooltip: _mostrarFiltros ? 'Ocultar filtros' : 'Mostrar filtros',
                onPressed: _processingEstado
                    ? null
                    : () {
                        setState(() {
                          _mostrarFiltros = !_mostrarFiltros;
                        });
                      },
                icon: Icon(
                  _mostrarFiltros
                      ? Icons.filter_alt_off_outlined
                      : Icons.filter_alt_outlined,
                  color: _theme.white,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  side: BorderSide(
                    color: _theme.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Nuevo usuario',
                onPressed: _processingEstado ? null : () => _abrirFormulario(),
                icon: Icon(PhosphorIconsFill.userPlus, color: _theme.white),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  side: BorderSide(
                    color: _theme.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFiltros(),
                Expanded(child: _buildListaUsuarios()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
