import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
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
  bool _loadingRoles = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  String _filtro = '';
  String? _rolFiltro;

  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  String get _currentRole => (Auth.instance.profile.rol ?? '').toUpperCase();

  @override
  void initState() {
    super.initState();
    _service = UsuariosService(context);
    _cargarRoles();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarRoles() async {
    setState(() => _loadingRoles = true);
    final roles = await _service.obtenerRoles();
    setState(() {
      _roles = roles;
      _loadingRoles = false;
    });
  }

  Future<void> _cargarUsuarios({int? page}) async {
    setState(() => _loading = true);
    final result = await _service.obtenerUsuarios(
      page: page ?? _page,
      limit: _limit,
      filtro: _filtro,
      rol: _rolFiltro,
    );

    setState(() {
      _usuarios = result.usuarios;
      _page = result.page;
      _limit = result.limit;
      _total = result.total;
      _loading = false;
    });

    if (!mounted) return;
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
    if (_currentRole == 'ADMIN') return _roles;
    return _roles
        .where((rol) => rol.codigo == 'MEDICO' || rol.codigo == 'SUPERVISOR')
        .toList();
  }

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
      if (usuario != null)
        ...usuario.roles.map((rol) => rol.rol.toUpperCase()).toList(),
      if (usuario?.rol != null) usuario!.rol!.toUpperCase(),
    };
    String? rolSeleccionado = selectedRoles.isNotEmpty
        ? selectedRoles.first
        : null;
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
                          items: _rolesVisibles
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
                            if (_currentRole != 'ADMIN') {
                              final invalid = selectedRoles.any(
                                (rol) => rol != 'MEDICO' && rol != 'SUPERVISOR',
                              );
                              if (invalid) {
                                showSnackBar(
                                  usuariosMessenger,
                                  'Los supervisores solo pueden asignar roles MEDICO o SUPERVISOR',
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
    final activo = (usuario.estado ?? '').toUpperCase() == 'ACTIVO';
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
      _cargarUsuarios();
    } else {
      showSnackBar(
        usuariosMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  String _rolesTexto(Usuario usuario) {
    if (usuario.roles.isNotEmpty) {
      return usuario.roles.map((r) => r.rol).join(', ');
    }
    return usuario.rol ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: usuariosMessenger,
      child: TemplatePage(
        page: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuarios',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentRole == 'ADMIN'
                                ? 'Administra todos los roles disponibles'
                                : 'Los supervisores solo gestionan médicos y supervisores',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    SimpleButton(
                      title: 'Nuevo usuario',
                      preffixicon: PhosphorIconsFill.userPlus,
                      fullWidth: false,
                      onTap: () => _abrirFormulario(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomDesktopDataTable(
                  titulo: 'Gestión de usuarios',
                  descripcion:
                      'Consulta, filtra y administra los usuarios permitidos según tu rol.',
                  acciones: [
                    IconButton(
                      onPressed: _cargarUsuarios,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                  filtros: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar por nombre o correo',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              _filtro = value;
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
                          setState(() {
                            _filtro = _searchController.text.trim();
                          });
                          _cargarUsuarios(page: 1);
                        },
                      ),
                      SimpleButton(
                        title: 'Limpiar filtros',
                        preffixicon: Icons.clear,
                        fullWidth: false,
                        outlined: true,
                        background: _theme.primary,
                        onTap: () {
                          setState(() {
                            _filtro = '';
                            _rolFiltro = null;
                            _searchController.clear();
                          });
                          _cargarUsuarios(page: 1);
                        },
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Filtrar por rol',
                            isDense: true,
                          ),
                          value: _rolFiltro,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._rolesVisibles.map(
                              (rol) => DropdownMenuItem<String?>(
                                value: rol.codigo,
                                child: Text(rol.nombre),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _rolFiltro = value;
                            });
                            _cargarUsuarios(page: 1);
                          },
                        ),
                      ),
                    ],
                  ),
                  columnas: [
                    CriterioOrdenType(nombre: 'Usuario'),
                    CriterioOrdenType(nombre: 'Correo'),
                    CriterioOrdenType(nombre: 'Roles'),
                    CriterioOrdenType(nombre: 'Estado'),
                    CriterioOrdenType(nombre: 'Acciones'),
                  ],
                  contenidoTabla: _usuarios
                      .map(
                        (usuario) => [
                          Text(usuario.usuario ?? '-'),
                          Text(usuario.correoElectronico),
                          Text(_rolesTexto(usuario)),
                          Chip(
                            label: Text((usuario.estado ?? '-').toUpperCase()),
                            backgroundColor:
                                (usuario.estado ?? '').toUpperCase() == 'ACTIVO'
                                ? _theme.success.withValues(alpha: .15)
                                : _theme.error.withValues(alpha: .15),
                            labelStyle: TextStyle(
                              color:
                                  (usuario.estado ?? '').toUpperCase() ==
                                      'ACTIVO'
                                  ? _theme.success
                                  : _theme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _abrirFormulario(usuario: usuario),
                              ),
                              IconButton(
                                tooltip:
                                    (usuario.estado ?? '').toUpperCase() ==
                                        'ACTIVO'
                                    ? 'Desactivar'
                                    : 'Activar',
                                icon: Icon(
                                  (usuario.estado ?? '').toUpperCase() ==
                                          'ACTIVO'
                                      ? Icons.toggle_off
                                      : Icons.toggle_on,
                                  color: _theme.primary,
                                ),
                                onPressed: () => _cambiarEstado(usuario),
                              ),
                            ],
                          ),
                        ],
                      )
                      .toList(),
                  paginacion: _buildPagination(),
                  cargando: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final inicio = _usuarios.isEmpty ? 0 : ((_page - 1) * _limit) + 1;
    final fin = (_page - 1) * _limit + _usuarios.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mostrando $inicio - $fin de $_total usuarios'),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1 && !_loading
                    ? () => _cargarUsuarios(page: _page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page'),
              IconButton(
                onPressed: (_page * _limit) < _total && !_loading
                    ? () => _cargarUsuarios(page: _page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
