import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/extensions/colores_extension.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/personal_salud.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/autocomplete_field.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/pages/personal_salud/personal_salud_service.dart';

final GlobalKey<ScaffoldMessengerState> personalSaludMessenger =
    GlobalKey<ScaffoldMessengerState>();

class PersonalSaludPage extends StatefulWidget {
  const PersonalSaludPage({super.key});

  @override
  State<PersonalSaludPage> createState() => _PersonalSaludPageState();
}

class _PersonalSaludPageState extends State<PersonalSaludPage>
    with FormController {
  final _theme = ThemeController.instance;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  late final PersonalSaludService _service;

  List<PersonalSalud> _personal = [];
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  String _filtro = '';
  String? _rolPersonalSalud;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _service = PersonalSaludService(context);
    _cargarRolPersonalSalud();
    _cargarPersonalSalud();
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
    if (!_scrollController.hasClients || _loadingMore || _loading) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 200 && _personal.length < _total) {
      _cargarPersonalSalud(page: _page + 1, append: true);
    }
  }

  Future<void> _cargarRolPersonalSalud() async {
    final rol = await _service.obtenerRolPersonalSalud();
    if (!mounted) return;
    setState(() {
      _rolPersonalSalud = rol;
    });
  }

  Future<void> _cargarPersonalSalud({int? page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    final result = await _service.obtenerPersonalSalud(
      page: page ?? _page,
      limit: _limit,
      filtro: _filtro,
    );

    if (!mounted) return;
    setState(() {
      if (append) {
        _personal = [..._personal, ...result.personal];
      } else {
        _personal = result.personal;
      }
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
        personalSaludMessenger,
        result.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _abrirFiltros() async {
    final controller = TextEditingController(text: _filtro);
    final result = await showModalBottomSheet<bool>(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SimpleButton(
                        title: 'Cancelar',
                        outlined: true,
                        background: _theme.primary,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SimpleButton(
                        title: 'Aplicar',
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;
    setState(() {
      _filtro = controller.text.trim();
      _searchController.text = _filtro;
    });
    _cargarPersonalSalud(page: 1);
  }

  Widget _buildFilterSummary() {
    if (_filtro.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _theme.primary20,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filtro: $_filtro',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filtro = '';
                _searchController.clear();
              });
              _cargarPersonalSalud(page: 1);
            },
            child: const Text('Quitar filtros'),
          ),
        ],
      ),
    );
  }

  DateTime? _parseFechaNacimiento(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
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

  String _formatearFechaBackend(String value) {
    final limpio = value.trim();
    if (limpio.isEmpty) return '';
    try {
      if (limpio.contains('/')) {
        final parsed = _dateFormatter.parseStrict(limpio);
        return DateFormat('yyyy-MM-dd').format(parsed);
      }
      final parsed = DateTime.parse(limpio);
      return DateFormat('yyyy-MM-dd').format(parsed);
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

  String _validarApellidos(
    String? value,
    String alias, {
    required TextEditingController primerApellido,
    required TextEditingController segundoApellido,
  }) {
    final primer = primerApellido.text.trim();
    final segundo = segundoApellido.text.trim();
    if (primer.isEmpty && segundo.isEmpty) {
      return 'Ingresa al menos un apellido';
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

  String _validarCelular(String? value, String alias) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Campo requerido';
    }
    if (!RegExp(r'^[67]\d{7}$').hasMatch(trimmed)) {
      return 'El celular debe tener 8 dígitos y empezar con 6 o 7';
    }
    return '';
  }

  String _resolveAvatarUrl(String? urlFoto) {
    if (urlFoto == null || urlFoto.trim().isEmpty) {
      return '';
    }
    final trimmed = urlFoto.trim();
    if (trimmed.startsWith('http')) {
      return trimmed;
    }
    return '${Constantes.apiUrl}$trimmed';
  }

  String _initialsFor(PersonalSalud persona) {
    final parts = [
      persona.nombres,
      if ((persona.primerApellido ?? '').trim().isNotEmpty)
        persona.primerApellido!.trim(),
      if ((persona.segundoApellido ?? '').trim().isNotEmpty)
        persona.segundoApellido!.trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'PS';
    final initials = parts.take(2).map((part) => part[0]).join();
    return initials.toUpperCase();
  }

  Widget _buildAvatar(PersonalSalud persona, {double radius = 18}) {
    final url = _resolveAvatarUrl(persona.urlFoto);
    final initials = Text(
      _initialsFor(persona),
      style: TextStyle(
        color: _theme.primary,
        fontWeight: FontWeight.w600,
        fontSize: radius * 0.7,
      ),
    );
    if (url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _theme.primary20,
        child: initials,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _theme.primary20,
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(child: initials),
        ),
      ),
    );
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

  void _mostrarDetallesPersonal(PersonalSalud persona) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Detalles del personal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Center(child: _buildAvatar(persona, radius: 36)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nombre completo'),
                  subtitle: Text(persona.nombreCompleto),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Documento'),
                  subtitle: Text(persona.nroDocumento ?? 'Sin documento'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Correo'),
                  subtitle: Text(
                    persona.correoElectronico ?? 'Sin correo registrado',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Teléfono'),
                  subtitle: Text(persona.telefono ?? 'Sin teléfono registrado'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha de nacimiento'),
                  subtitle: Text(
                    _formatearFechaInicial(persona.fechaNacimiento),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Género'),
                  subtitle: Text(persona.genero ?? 'No especificado'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Permisos administrativos'),
                  subtitle: Text(persona.esSupervisor ? 'Sí' : 'No'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Especialidades',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _buildEspecialidadesCell(persona),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirFormulario({PersonalSalud? personal}) {
    final formKey = GlobalKey<FormState>();
    final nombres = TextEditingController(text: personal?.nombres ?? '');
    final primerApellido = TextEditingController(
      text: personal?.primerApellido ?? '',
    );
    final segundoApellido = TextEditingController(
      text: personal?.segundoApellido ?? '',
    );
    final nroDocumento = TextEditingController(
      text: personal?.nroDocumento ?? '',
    );
    final telefono = TextEditingController(text: personal?.telefono ?? '');
    final correo = TextEditingController(
      text: personal?.correoElectronico ?? '',
    );
    final fechaNacimiento = TextEditingController(
      text: _formatearFechaInicial(personal?.fechaNacimiento),
    );
    final contrasena = TextEditingController();
    final repetirContrasena = TextEditingController();
    TextEditingController? autocompleteController;
    bool esSupervisor = personal?.esSupervisor ?? false;
    String? generoSeleccionado = personal?.genero;
    String apellidoErrorText = '';

    final seleccionInicial = personal?.especialidades ?? [];
    final selectedEspecialidades = seleccionInicial.isNotEmpty
        ? seleccionInicial
              .map(
                (especialidad) => Especialidad(
                  id: especialidad.id,
                  nombre: especialidad.nombre,
                  descripcion: null,
                  estado: 'ACTIVO',
                  colorHex: especialidad.colorHex,
                  estudios: const [],
                ),
              )
              .toList()
        : <Especialidad>[];

    final List<Especialidad> especialidadesDisponibles = [];
    bool especialidadesLoading = false;
    bool especialidadesHasMore = true;
    int especialidadesPage = 1;
    String especialidadesFiltro = '';
    Timer? especialidadesDebounce;
    bool scrollListenerAttached = false;
    final ScrollController especialidadesScrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> cargarEspecialidades({
              bool reset = false,
              bool clearBeforeLoad = true,
            }) async {
              if (especialidadesLoading || (!especialidadesHasMore && !reset)) {
                return;
              }
              setStateDialog(() => especialidadesLoading = true);
              if (reset) {
                especialidadesPage = 1;
                especialidadesHasMore = true;
                if (clearBeforeLoad) {
                  especialidadesDisponibles.clear();
                }
              }
              final result = await _service.obtenerEspecialidadesPaginadas(
                page: especialidadesPage,
                limit: 20,
                filtro: especialidadesFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  especialidadesDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  especialidadesDisponibles.addAll(result.items);
                }
                especialidadesHasMore =
                    especialidadesDisponibles.length < result.total;
                especialidadesPage += 1;
                especialidadesLoading = false;
              });
            }

            if (!scrollListenerAttached) {
              scrollListenerAttached = true;
              especialidadesScrollController.addListener(() {
                if (especialidadesScrollController.position.pixels >=
                        especialidadesScrollController
                                .position
                                .maxScrollExtent -
                            120 &&
                    !especialidadesLoading &&
                    especialidadesHasMore) {
                  cargarEspecialidades();
                }
              });
              cargarEspecialidades(reset: true);
            }
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
                                personal == null
                                    ? 'Registrar personal de salud'
                                    : 'Editar personal de salud',
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
                                        _validarApellidos(
                                          value,
                                          alias,
                                          primerApellido: primerApellido,
                                          segundoApellido: segundoApellido,
                                        ),
                                    onChange: (_) {
                                      if (apellidoErrorText.isNotEmpty) {
                                        setStateDialog(() {
                                          apellidoErrorText = '';
                                        });
                                      }
                                    },
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
                                  validate: (value, alias) => _validarApellidos(
                                    value,
                                    alias,
                                    primerApellido: primerApellido,
                                    segundoApellido: segundoApellido,
                                  ),
                                  onChange: (_) {
                                    if (apellidoErrorText.isNotEmpty) {
                                      setStateDialog(() {
                                        apellidoErrorText = '';
                                      });
                                    }
                                  },
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
                                        _validarApellidos(
                                          value,
                                          alias,
                                          primerApellido: primerApellido,
                                          segundoApellido: segundoApellido,
                                        ),
                                    onChange: (_) {
                                      if (apellidoErrorText.isNotEmpty) {
                                        setStateDialog(() {
                                          apellidoErrorText = '';
                                        });
                                      }
                                    },
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
                                  validate: (value, alias) => _validarApellidos(
                                    value,
                                    alias,
                                    primerApellido: primerApellido,
                                    segundoApellido: segundoApellido,
                                  ),
                                  onChange: (_) {
                                    if (apellidoErrorText.isNotEmpty) {
                                      setStateDialog(() {
                                        apellidoErrorText = '';
                                      });
                                    }
                                  },
                                ),
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
                          const SizedBox(height: 4),
                          if (apellidoErrorText.isNotEmpty)
                            Text(
                              apellidoErrorText,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextInput(
                                    title: 'Celular',
                                    controller: telefono,
                                    onlyNumbers: true,
                                    requiredData: true,
                                    validate: _validarCelular,
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
                                  title: 'Celular',
                                  controller: telefono,
                                  onlyNumbers: true,
                                  requiredData: true,
                                  validate: _validarCelular,
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
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextInput(
                                    title: 'Fecha de nacimiento (DD/MM/AAAA)',
                                    controller: fechaNacimiento,
                                    requiredData: true,
                                    placeholder: 'DD/MM/AAAA',
                                    maxLength: 10,
                                    textFiltering: RegExp(r'[0-9/]'),
                                    onTap: () =>
                                        _seleccionarFecha(fechaNacimiento),
                                    validate: _validarFechaNacimiento,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Género',
                                      isDense: true,
                                    ),
                                    initialValue: generoSeleccionado,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'F',
                                        child: Text('Femenino'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'M',
                                        child: Text('Masculino'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'O',
                                        child: Text('Otro'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        generoSeleccionado = value;
                                      });
                                    },
                                    validator: (value) =>
                                        (value == null || value.isEmpty)
                                        ? 'Campo requerido'
                                        : null,
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                CustomTextInput(
                                  title: 'Fecha de nacimiento (DD/MM/AAAA)',
                                  controller: fechaNacimiento,
                                  requiredData: true,
                                  placeholder: 'DD/MM/AAAA',
                                  maxLength: 10,
                                  textFiltering: RegExp(r'[0-9/]'),
                                  onTap: () =>
                                      _seleccionarFecha(fechaNacimiento),
                                  validate: _validarFechaNacimiento,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Género',
                                    isDense: true,
                                  ),
                                  initialValue: generoSeleccionado,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'F',
                                      child: Text('Femenino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'M',
                                      child: Text('Masculino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'O',
                                      child: Text('Otro'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      generoSeleccionado = value;
                                    });
                                  },
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? 'Campo requerido'
                                      : null,
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          Text(
                            'Especialidades',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          FormField<List<Especialidad>>(
                            initialValue: selectedEspecialidades,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Selecciona al menos una especialidad'
                                : null,
                            builder: (state) {
                              final selectedIds = selectedEspecialidades
                                  .map((e) => e.id)
                                  .toSet();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (selectedEspecialidades.isEmpty)
                                    Text(
                                      'No has seleccionado especialidades.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: selectedEspecialidades.map((
                                        item,
                                      ) {
                                        return Chip(
                                          label: Text(item.nombre),
                                          backgroundColor: HexColor.fromHex(
                                            item.colorHex,
                                          ).withValues(alpha: .15),
                                          deleteIcon: const Icon(Icons.close),
                                          onDeleted: () {
                                            setStateDialog(() {
                                              selectedEspecialidades
                                                  .removeWhere(
                                                    (especialidad) =>
                                                        especialidad.id ==
                                                        item.id,
                                                  );
                                            });
                                            state.didChange(
                                              selectedEspecialidades,
                                            );
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 12),
                                  AutocompleteField<Especialidad>(
                                    optionsBuilder: (textEditingValue) {
                                      final query = textEditingValue.text
                                          .trim()
                                          .toLowerCase();
                                      if (query.isEmpty &&
                                          especialidadesDisponibles.isEmpty &&
                                          !especialidadesLoading) {
                                        Future.microtask(
                                          () =>
                                              cargarEspecialidades(reset: true),
                                        );
                                      }
                                      if (query.isEmpty) {
                                        return especialidadesDisponibles;
                                      }
                                      return especialidadesDisponibles.where(
                                        (option) => option.nombre
                                            .toLowerCase()
                                            .contains(query),
                                      );
                                    },
                                    displayStringForOption: (option) =>
                                        option.nombre,
                                    onSelected: (selection) {
                                      if (selectedIds.contains(selection.id)) {
                                        return;
                                      }
                                      setStateDialog(() {
                                        selectedEspecialidades.add(selection);
                                        autocompleteController?.clear();
                                        especialidadesFiltro = '';
                                        especialidadesDisponibles.clear();
                                        especialidadesHasMore = true;
                                        especialidadesPage = 1;
                                      });
                                      state.didChange(selectedEspecialidades);
                                      FocusScope.of(context).unfocus();
                                      cargarEspecialidades(reset: true);
                                    },
                                    labelText:
                                        'Agregar especialidad (autocomplete)',
                                    loading: especialidadesLoading,
                                    loadingText: 'Cargando especialidades...',
                                    emptyText:
                                        'No hay especialidades disponibles.',
                                    optionsHeaderText: 'Especialidades',
                                    optionsScrollController:
                                        especialidadesScrollController,
                                    selectedIconColor: _theme.primary,
                                    isOptionSelected: (option) =>
                                        selectedIds.contains(option.id),
                                    onControllerReady: (controller) {
                                      autocompleteController ??= controller;
                                    },
                                    onChanged: (value) {
                                      especialidadesFiltro = value.trim();
                                      especialidadesDebounce?.cancel();
                                      if (especialidadesFiltro.isEmpty) {
                                        cargarEspecialidades(
                                          reset: true,
                                          clearBeforeLoad: false,
                                        );
                                        return;
                                      }
                                      especialidadesDebounce = Timer(
                                        const Duration(milliseconds: 400),
                                        () =>
                                            cargarEspecialidades(reset: true),
                                      );
                                    },
                                  ),
                                  if (state.hasError) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      state.errorText ?? '',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
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
                                    requiredData: personal == null,
                                    validate: (value, alias) {
                                      if (personal != null &&
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
                                    requiredData: personal == null,
                                    validate: (value, alias) {
                                      if (personal != null &&
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
                                  requiredData: personal == null,
                                  validate: (value, alias) {
                                    if (personal != null &&
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
                                  requiredData: personal == null,
                                  validate: (value, alias) {
                                    if (personal != null &&
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
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Permisos administrativos'),
                            subtitle: const Text(
                              'Habilita acciones de supervisión para personal de salud.',
                            ),
                            value: esSupervisor,
                            onChanged: (value) {
                              setStateDialog(() {
                                esSupervisor = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SimpleButton(
                              title: personal == null
                                  ? 'Crear personal'
                                  : 'Guardar cambios',
                              preffixicon: personal == null
                                  ? PhosphorIconsFill.userPlus
                                  : PhosphorIconsFill.floppyDisk,
                              fullWidth: false,
                              onTap: () async {
                                final isValid = validateForm(formKey);
                                if (!isValid) return;
                                final apellidoError = _validarApellidos(
                                  null,
                                  '',
                                  primerApellido: primerApellido,
                                  segundoApellido: segundoApellido,
                                );
                                if (apellidoError.isNotEmpty) {
                                  setStateDialog(() {
                                    apellidoErrorText = apellidoError;
                                  });
                                  showSnackBar(
                                    personalSaludMessenger,
                                    apellidoError,
                                    state: StatusSnackBar.error,
                                    colorText: _theme.white,
                                  );
                                  return;
                                }
                                if ((contrasena.text.isNotEmpty ||
                                        repetirContrasena.text.isNotEmpty) &&
                                    contrasena.text != repetirContrasena.text) {
                                  showSnackBar(
                                    personalSaludMessenger,
                                    'Las contraseñas no coinciden',
                                    state: StatusSnackBar.error,
                                    colorText: _theme.white,
                                  );
                                  return;
                                }
                                if (_rolPersonalSalud == null ||
                                    _rolPersonalSalud!.isEmpty) {
                                  showSnackBar(
                                    personalSaludMessenger,
                                    'No se pudo resolver el rol de personal de salud',
                                    state: StatusSnackBar.error,
                                    colorText: _theme.white,
                                  );
                                  return;
                                }

                                final persona = {
                                  'nombres': nombres.text.trim(),
                                  'primerApellido': primerApellido.text.trim(),
                                  'segundoApellido': segundoApellido.text
                                      .trim(),
                                  'fechaNacimiento': _formatearFechaBackend(
                                    fechaNacimiento.text,
                                  ),
                                  'nroDocumento': nroDocumento.text.trim(),
                                  'telefono': telefono.text.trim(),
                                  'genero': generoSeleccionado,
                                };

                                Map<String, dynamic> body;
                                if (personal == null) {
                                  body = {
                                    'persona': persona,
                                    'correoElectronico': correo.text.trim(),
                                    'contrasena': contrasena.text,
                                    'repetirContrasena': repetirContrasena.text,
                                    'roles': [_rolPersonalSalud],
                                    'esSupervisor': esSupervisor,
                                    'especialidades': selectedEspecialidades
                                        .map((especialidad) => especialidad.id)
                                        .toList(),
                                  };
                                } else {
                                  body = {
                                    'persona': persona,
                                    'correoElectronico': correo.text.trim(),
                                    if (contrasena.text.isNotEmpty)
                                      'contrasena': contrasena.text,
                                    if (repetirContrasena.text.isNotEmpty)
                                      'repetirContrasena':
                                          repetirContrasena.text,
                                    'roles': [_rolPersonalSalud],
                                    'esSupervisor': esSupervisor,
                                    'especialidades': selectedEspecialidades
                                        .map((especialidad) => especialidad.id)
                                        .toList(),
                                  };
                                }

                                Navigator.pop(context);
                                await _guardarPersonal(body, personal);
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
      },
    ).whenComplete(() {
      especialidadesDebounce?.cancel();
      especialidadesScrollController.dispose();
    });
  }

  Future<void> _guardarPersonal(
    Map<String, dynamic> body,
    PersonalSalud? personal,
  ) async {
    final response = personal == null
        ? await _service.crearPersonalSalud(body)
        : await _service.actualizarPersonalSalud(personal.id, body);

    if (response.status != StatusNetwork.connected) {
      showSnackBar(
        personalSaludMessenger,
        response.message.isEmpty
            ? 'No se pudo guardar el personal de salud.'
            : response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
      return;
    }

    showSnackBar(
      personalSaludMessenger,
      personal == null
          ? 'Personal de salud registrado correctamente.'
          : 'Personal de salud actualizado correctamente.',
      state: StatusSnackBar.success,
      colorText: _theme.white,
    );
    _cargarPersonalSalud(page: 1);
  }

  Future<void> _confirmarCambioEstado(PersonalSalud personal) async {
    final estaActivo = personal.estaActivo;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(estaActivo ? 'Inactivar personal' : 'Activar personal'),
        content: Text(
          estaActivo
              ? '¿Seguro que deseas inactivar a ${personal.nombreCompleto}?'
              : '¿Seguro que deseas activar a ${personal.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final response = estaActivo
        ? await _service.inactivarPersonalSalud(personal.id)
        : await _service.activarPersonalSalud(personal.id);
    if (response.status != StatusNetwork.connected) {
      showSnackBar(
        personalSaludMessenger,
        response.message.isEmpty
            ? 'No se pudo actualizar el estado.'
            : response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
      return;
    }

    showSnackBar(
      personalSaludMessenger,
      estaActivo
          ? 'Personal de salud inactivado correctamente.'
          : 'Personal de salud activado correctamente.',
      state: StatusSnackBar.success,
      colorText: _theme.white,
    );
    _cargarPersonalSalud(page: 1);
  }

  Widget _buildPagination() {
    final inicio = _personal.isEmpty ? 0 : ((_page - 1) * _limit) + 1;
    final fin = (_page - 1) * _limit + _personal.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mostrando $inicio - $fin de $_total registros'),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1 && !_loading
                    ? () => _cargarPersonalSalud(page: _page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page'),
              IconButton(
                onPressed: (_page * _limit) < _total && !_loading
                    ? () => _cargarPersonalSalud(page: _page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEspecialidadesCell(PersonalSalud personal) {
    if (personal.especialidades.isEmpty) {
      return const Text('Sin especialidades');
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: personal.especialidades
          .map(
            (especialidad) => Chip(
              label: Text(especialidad.nombre),
              backgroundColor: HexColor.fromHex(
                especialidad.colorHex,
              ).withValues(alpha: .15),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCompactList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => _cargarPersonalSalud(page: 1),
      child: _personal.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    'No hay personal de salud registrado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _personal.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final persona = _personal[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildAvatar(persona, radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                persona.nombreCompleto,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (persona.esSupervisor)
                              Chip(
                                label: const Text('Admin'),
                                backgroundColor: _theme.primary.withValues(
                                  alpha: .15,
                                ),
                                labelStyle: TextStyle(
                                  color: _theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            persona.estaActivo ? 'Activo' : 'Inactivo',
                          ),
                          backgroundColor: (persona.estaActivo
                                  ? Colors.green
                                  : Colors.grey)
                              .withValues(alpha: .15),
                          labelStyle: TextStyle(
                            color: persona.estaActivo
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          persona.nroDocumento ?? 'Sin documento',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        _buildEspecialidadesCell(persona),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _abrirFormulario(personal: persona),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _mostrarDetallesPersonal(persona),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Detalles'),
                            ),
                            TextButton.icon(
                              onPressed: () => _confirmarCambioEstado(persona),
                              icon: Icon(
                                persona.estaActivo
                                    ? Icons.person_off_outlined
                                    : Icons.person_add_alt_1_outlined,
                              ),
                              label: Text(
                                persona.estaActivo ? 'Inactivar' : 'Activar',
                              ),
                            ),
                          ],
                        ),
                        if (_loadingMore && index == _personal.length - 1) ...[
                          const SizedBox(height: 12),
                          const Center(child: CircularProgressIndicator()),
                        ],
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
    final isCompact = MediaQuery.of(context).size.width < 840;
    return ScaffoldMessenger(
      key: personalSaludMessenger,
      child: Scaffold(
        backgroundColor: _theme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCompact)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal de salud',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Administra perfiles, especialidades y permisos administrativos.',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: _abrirFiltros,
                              icon: const Icon(Icons.filter_list),
                              label: const Text('Filtros'),
                            ),
                            TextButton.icon(
                              onPressed: () => _abrirFormulario(),
                              icon: const Icon(Icons.add),
                              label: const Text('Nuevo'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Personal de salud',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: _abrirFiltros,
                          icon: const Icon(Icons.filter_list),
                        ),
                        IconButton(
                          onPressed: () => _abrirFormulario(),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                _buildFilterSummary(),
                const SizedBox(height: 12),
                if (!isCompact)
                  CustomDesktopDataTable(
                    titulo: 'Gestión de personal de salud',
                    descripcion:
                        'Consulta, filtra y administra el personal de salud.',
                    acciones: [
                      IconButton(
                        onPressed: _cargarPersonalSalud,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                    columnas: [
                      CriterioOrdenType(nombre: 'Nombre'),
                      CriterioOrdenType(nombre: 'Documento'),
                      CriterioOrdenType(nombre: 'Estado'),
                      CriterioOrdenType(nombre: 'Especialidades'),
                      CriterioOrdenType(nombre: 'Admin'),
                      CriterioOrdenType(nombre: 'Acciones'),
                    ],
                    contenidoTabla: _personal
                        .map(
                          (persona) => [
                            Row(
                              children: [
                                _buildAvatar(persona, radius: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(persona.nombreCompleto)),
                              ],
                            ),
                            Text(persona.nroDocumento ?? '-'),
                            Chip(
                              label: Text(
                                persona.estaActivo ? 'Activo' : 'Inactivo',
                              ),
                              backgroundColor: (persona.estaActivo
                                      ? Colors.green
                                      : Colors.grey)
                                  .withValues(alpha: .15),
                              labelStyle: TextStyle(
                                color: persona.estaActivo
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            _buildEspecialidadesCell(persona),
                            persona.esSupervisor
                                ? Chip(
                                    label: const Text('Admin'),
                                    backgroundColor: _theme.primary.withValues(
                                      alpha: .15,
                                    ),
                                    labelStyle: TextStyle(
                                      color: _theme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const Text('—'),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _abrirFormulario(personal: persona),
                                ),
                                IconButton(
                                  tooltip: 'Ver detalles',
                                  icon: const Icon(Icons.visibility_outlined),
                                  onPressed: () =>
                                      _mostrarDetallesPersonal(persona),
                                ),
                                IconButton(
                                  tooltip: persona.estaActivo
                                      ? 'Inactivar'
                                      : 'Activar',
                                  icon: Icon(
                                    persona.estaActivo
                                        ? Icons.person_off_outlined
                                        : Icons.person_add_alt_1_outlined,
                                  ),
                                  onPressed: () =>
                                      _confirmarCambioEstado(persona),
                                ),
                              ],
                            ),
                          ],
                        )
                        .toList(),
                    paginacion: _buildPagination(),
                    cargando: _loading,
                  )
                else ...[
                  const SizedBox(height: 12),
                  Expanded(child: _buildCompactList()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
