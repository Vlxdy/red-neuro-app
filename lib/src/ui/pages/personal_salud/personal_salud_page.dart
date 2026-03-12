import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/extensions/colores_extension.dart';
import 'package:red_neuro_app/src/models/ocupacion.dart';
import 'package:red_neuro_app/src/models/personal_salud.dart';
import 'package:red_neuro_app/src/models/rol.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/common/form_stepper/step_form_dialog_layout.dart';
import 'package:red_neuro_app/src/ui/common/components/tray_ui_helpers.dart';
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
  bool _processingAction = false;
  String? _currentUsuarioRolId;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _service = PersonalSaludService(context);
    Auth.instance.profileListenable.addListener(_onProfileChanged);
    _cargarUsuarioActual();
    _cargarPersonalSalud();
    _scrollController.addListener(_handleScroll);
  }

  void _onProfileChanged() {
    _cargarUsuarioActual();
  }

  String _resolverIdUsuarioRol(Usuario profile) {
    final directo = (profile.idUsuarioRol ?? '').trim();
    if (directo.isNotEmpty) return directo;

    final roles = profile.roles;
    final roleId = (profile.idRol ?? '').trim();
    if (roles.isEmpty) return '';

    Rol? activeRole;
    if (roleId.isNotEmpty) {
      try {
        activeRole = roles.firstWhere((rol) => rol.idRol == roleId);
      } catch (_) {
        activeRole = null;
      }
    }
    activeRole ??= roles.first;
    return activeRole.idUsuarioRol.trim();
  }

  Future<void> _cargarUsuarioActual() async {
    final profile = Auth.instance.profile;
    String id = _resolverIdUsuarioRol(profile);

    if (id.isEmpty) {
      final profileAsync = await Auth.instance.profileAsync();
      id = _resolverIdUsuarioRol(profileAsync);
    }

    if (!mounted) return;
    setState(() {
      _currentUsuarioRolId = id.isEmpty ? null : id;
    });
  }

  bool _esUsuarioActual(PersonalSalud personal) {
    final currentId = _currentUsuarioRolId?.trim();
    if (currentId == null || currentId.isEmpty) return false;
    return personal.id.trim() == currentId;
  }

  @override
  void dispose() {
    Auth.instance.profileListenable.removeListener(_onProfileChanged);
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
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: CustomTextInputStyles.decoration(
                    label: 'Buscar por nombre',
                    prefixIcon: const Icon(Icons.search),
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
      return '';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      return 'El celular debe tener exactamente 8 dígitos';
    }
    final numero = int.tryParse(trimmed);
    if (numero == null || numero < 60000000 || numero > 79999999) {
      return 'El celular debe estar entre 60000000 y 79999999';
    }
    return '';
  }

  String _textoMayusculasSoloLetras(String value) {
    final mayusculas = value.toUpperCase();
    return mayusculas.replaceAll(RegExp(r'[^A-ZÁÉÍÓÚÑ\s]'), '');
  }

  void _normalizarTextoMayusculas(
    TextEditingController controller,
    String value,
  ) {
    final normalizado = _textoMayusculasSoloLetras(value);
    if (controller.text == normalizado) return;
    controller.value = TextEditingValue(
      text: normalizado,
      selection: TextSelection.collapsed(offset: normalizado.length),
    );
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
    final esUsuarioActual = _esUsuarioActual(persona);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? copiedField;
        final ocupaciones = persona.ocupaciones;
        final contacto = [
          if ((persona.correoElectronico ?? '').trim().isNotEmpty)
            persona.correoElectronico!.trim(),
          if ((persona.telefono ?? '').trim().isNotEmpty)
            'Tel: ${persona.telefono!.trim()}',
        ].join(' · ');
        return StatefulBuilder(
          builder: (context, setStateSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Información del personal',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: _buildAvatar(persona, radius: 28),
                  title: Text(persona.nombreCompleto),
                  subtitle: contacto.isEmpty ? null : Text(contacto),
                  trailing: _buildEstadoChip(persona.estaActivo),
                ),
                const SizedBox(height: 8),
                _buildTipoPersonalChip(persona.esSupervisor),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((persona.correoElectronico ?? '').trim().isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.alternate_email,
                        label: 'Correo',
                        value: persona.correoElectronico!.trim(),
                        copied: copiedField == 'correo',
                        onTap: () async {
                          await _copiarDato(persona.correoElectronico!.trim());
                          if (!mounted) return;
                          setStateSheet(() => copiedField = 'correo');
                        },
                      ),
                    if ((persona.telefono ?? '').trim().isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.phone_outlined,
                        label: 'Celular',
                        value: persona.telefono!.trim(),
                        copied: copiedField == 'celular',
                        onTap: () async {
                          await _copiarDato(persona.telefono!.trim());
                          if (!mounted) return;
                          setStateSheet(() => copiedField = 'celular');
                        },
                      ),
                    if ((persona.nroDocumento ?? '').trim().isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.badge_outlined,
                        label: 'Documento',
                        value: persona.nroDocumento!.trim(),
                      ),
                    if ((persona.genero ?? '').trim().isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.wc_outlined,
                        label: 'Género',
                        value: _textoGenero(persona.genero!.trim()),
                      ),
                    if (_formatearFechaInicial(persona.fechaNacimiento).trim().isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.cake_outlined,
                        label: 'Nacimiento',
                        value: _formatearFechaInicial(persona.fechaNacimiento),
                      ),
                    if (persona.esSupervisor)
                      CopyableInfoPill(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Rol',
                        value: 'Administrador',
                      ),
                  ],
                ),
                if (ocupaciones.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Ocupaciones',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildOcupacionesCell(persona),
                ],
                if (!esUsuarioActual) ...[
                  const SizedBox(height: 18),
                  SafeArea(
                    top: false,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _processingAction
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _abrirFormulario(personal: persona);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: _theme.primary,
                            foregroundColor: _theme.white,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _processingAction
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _confirmarCambioEstado(persona);
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: persona.estaActivo
                                  ? _theme.primary
                                  : Colors.green.shade700,
                            ),
                            foregroundColor: persona.estaActivo
                                ? _theme.primary
                                : Colors.green.shade700,
                          ),
                          icon: Icon(
                            persona.estaActivo
                                ? Icons.person_off_outlined
                                : Icons.person_add_alt_1_outlined,
                          ),
                          label: Text(
                            persona.estaActivo ? 'Desactivar' : 'Activar',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ));
      },
    );
  }

  Future<void> _copiarDato(String valor) async {
    await Clipboard.setData(ClipboardData(text: valor));
  }

  String _textoGenero(String genero) {
    final normalizado = genero.trim().toUpperCase();
    if (normalizado == 'F') return 'Femenino';
    if (normalizado == 'M') return 'Masculino';
    return genero;
  }

  Widget _buildEstadoChip(bool estaActivo) {
    final color = estaActivo ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estaActivo ? Icons.check_circle : Icons.pause_circle_filled,
            size: 14,
            color: color.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            estaActivo ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: color.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoPersonalChip(bool esSupervisor) {
    if (!esSupervisor) return const SizedBox.shrink();
    return const TrayAdminBadge();
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
    bool esSupervisor = personal?.esSupervisor ?? false;
    String? generoSeleccionado = personal?.genero;
    String apellidoErrorText = '';
    String? modalErrorText;
    String? submitErrorText;
    bool submitting = false;
    int currentStep = 0;
    final bool isEditing = personal != null;
    final int lastStepIndex = isEditing ? 2 : 3;

    final seleccionInicial = personal?.ocupaciones ?? [];
    final List<Ocupacion> selectedOcupaciones = seleccionInicial.isNotEmpty
        ? seleccionInicial
              .map(
                (ocupacion) => Ocupacion(
                  id: ocupacion.id,
                  nombre: ocupacion.nombre,
                  descripcion: null,
                  estado: 'ACTIVO',
                  grado: ocupacion.grado,
                  estudios: const [],
                ),
              )
              .toList()
        : <Ocupacion>[];

    final List<Ocupacion> ocupacionesDisponibles = [];
    bool ocupacionesLoading = false;
    bool ocupacionesHasMore = true;
    int ocupacionesPage = 1;
    String ocupacionesFiltro = '';
    Timer? ocupacionesDebounce;
    bool scrollListenerAttached = false;
    final ScrollController ocupacionesScrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> cargarOcupaciones({
              bool reset = false,
              bool clearBeforeLoad = true,
            }) async {
              if (ocupacionesLoading || (!ocupacionesHasMore && !reset)) {
                return;
              }
              setStateDialog(() => ocupacionesLoading = true);
              if (reset) {
                ocupacionesPage = 1;
                ocupacionesHasMore = true;
                if (clearBeforeLoad) {
                  ocupacionesDisponibles.clear();
                }
              }
              final result = await _service.obtenerOcupacionesPaginadas(
                page: ocupacionesPage,
                limit: 20,
                filtro: ocupacionesFiltro,
              );
              if (!mounted) return;
              setStateDialog(() {
                if (reset) {
                  ocupacionesDisponibles
                    ..clear()
                    ..addAll(result.items);
                } else {
                  ocupacionesDisponibles.addAll(result.items);
                }
                ocupacionesHasMore =
                    ocupacionesDisponibles.length < result.total;
                ocupacionesPage += 1;
                ocupacionesLoading = false;
              });
            }

            if (!scrollListenerAttached) {
              scrollListenerAttached = true;
              ocupacionesScrollController.addListener(() {
                if (ocupacionesScrollController.position.pixels >=
                        ocupacionesScrollController
                                .position
                                .maxScrollExtent -
                            120 &&
                    !ocupacionesLoading &&
                    ocupacionesHasMore) {
                  cargarOcupaciones();
                }
              });
              cargarOcupaciones(reset: true);
            }

            Widget stepContent() {
              final isWide = MediaQuery.of(context).size.width >= 720;

              if (currentStep == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              onChange: (value) {
                                _normalizarTextoMayusculas(nombres, value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextInput(
                              title: 'Primer apellido',
                              controller: primerApellido,
                              requiredData: true,
                              validate: (value, alias) => _validarApellidos(
                                value,
                                alias,
                                primerApellido: primerApellido,
                                segundoApellido: segundoApellido,
                              ),
                              onChange: (value) {
                                _normalizarTextoMayusculas(primerApellido, value);
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
                                (value?.isEmpty ?? true) ? 'Campo requerido' : '',
                            onChange: (value) {
                              _normalizarTextoMayusculas(nombres, value);
                            },
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
                            onChange: (value) {
                              _normalizarTextoMayusculas(primerApellido, value);
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
                              validate: (value, alias) => _validarApellidos(
                                value,
                                alias,
                                primerApellido: primerApellido,
                                segundoApellido: segundoApellido,
                              ),
                              onChange: (value) {
                                _normalizarTextoMayusculas(segundoApellido, value);
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
                            onChange: (value) {
                              _normalizarTextoMayusculas(segundoApellido, value);
                              if (apellidoErrorText.isNotEmpty) {
                                setStateDialog(() {
                                  apellidoErrorText = '';
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextInput(
                            title: 'Número de documento',
                            controller: nroDocumento,
                            requiredData: true,
                            onlyNumbers: true,
                            validate: (value, alias) =>
                                (value?.isEmpty ?? true) ? 'Campo requerido' : '',
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
                    CustomTextInput(
                      title: 'Fecha de nacimiento',
                      controller: fechaNacimiento,
                      requiredData: true,
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        await _seleccionarFecha(fechaNacimiento);
                      },
                      validate: (value, alias) =>
                          _validarFechaNacimiento(value, alias),
                    ),
                  ],
                );
              }

              if (currentStep == 1) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacto y género',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextInput(
                              title: 'Celular (opcional)',
                              controller: telefono,
                              onlyNumbers: true,
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
                            title: 'Celular (opcional)',
                            controller: telefono,
                            onlyNumbers: true,
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
                    DropdownButtonFormField<String>(
                      decoration: CustomTextInputStyles.decoration(
                        label: 'Género (opcional)',
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
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          generoSeleccionado = value;
                        });
                      },
                    ),
                  ],
                );
              }

              if (currentStep == 2) {
                final selectedIds = selectedOcupaciones.map((e) => e.id).toSet();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ocupaciones (opcional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    FormField<List<Ocupacion>>(
                      initialValue: selectedOcupaciones,
                      builder: (state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedOcupaciones.isEmpty)
                              Text(
                                'Puedes continuar sin ocupaciones y agregarlas después.',
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedOcupaciones.map((item) {
                                  return Chip(
                                    label: Text(item.nombre),
                                    backgroundColor: HexColor.fromHex(
                                      '#64748b',
                                    ).withValues(alpha: .15),
                                    deleteIcon: const Icon(Icons.close),
                                    onDeleted: () {
                                      setStateDialog(() {
                                        selectedOcupaciones.removeWhere(
                                          (ocupacion) =>
                                              ocupacion.id == item.id,
                                        );
                                      });
                                      state.didChange(selectedOcupaciones);
                                    },
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 12),
                            AutocompleteField<Ocupacion>(
                              optionsBuilder: (textEditingValue) {
                                final query = textEditingValue.text
                                    .trim()
                                    .toLowerCase();
                                if (query.isEmpty &&
                                    ocupacionesDisponibles.isEmpty &&
                                    !ocupacionesLoading) {
                                  Future.microtask(
                                    () => cargarOcupaciones(reset: true),
                                  );
                                }
                                if (query.isEmpty) {
                                  return ocupacionesDisponibles;
                                }
                                return ocupacionesDisponibles.where(
                                  (option) => option.nombre
                                      .toLowerCase()
                                      .contains(query),
                                );
                              },
                              displayStringForOption: (option) => option.nombre,
                              onSelected: (selection) {
                                if (selectedIds.contains(selection.id)) {
                                  return;
                                }
                                setStateDialog(() {
                                  selectedOcupaciones.add(selection);
                                  ocupacionesFiltro = '';
                                  ocupacionesDisponibles.clear();
                                  ocupacionesHasMore = true;
                                  ocupacionesPage = 1;
                                });
                                state.didChange(selectedOcupaciones);
                                FocusScope.of(context).unfocus();
                                cargarOcupaciones(reset: true);
                              },
                              labelText: 'Agregar ocupacion (opcional)',
                              loading: ocupacionesLoading,
                              loadingText: 'Cargando ocupaciones...',
                              emptyText: 'No hay ocupaciones disponibles.',
                              optionsHeaderText: 'Ocupaciones',
                              optionsScrollController:
                                  ocupacionesScrollController,
                              selectedIconColor: _theme.primary,
                              isOptionSelected: (option) =>
                                  selectedIds.contains(option.id),
                              onChanged: (value) {
                                ocupacionesFiltro = value.trim();
                                ocupacionesDebounce?.cancel();
                                if (ocupacionesFiltro.isEmpty) {
                                  cargarOcupaciones(
                                    reset: true,
                                    clearBeforeLoad: false,
                                  );
                                  return;
                                }
                                ocupacionesDebounce = Timer(
                                  const Duration(milliseconds: 400),
                                  () => cargarOcupaciones(reset: true),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
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
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              if (personal != null && (value?.isEmpty ?? true)) {
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
                              if (personal != null && (value?.isEmpty ?? true)) {
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
                            if (personal != null && (value?.isEmpty ?? true)) {
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
                            if (personal != null && (value?.isEmpty ?? true)) {
                              return '';
                            }
                            return (value?.isEmpty ?? true)
                                ? 'Campo requerido'
                                : '';
                          },
                        ),
                      ],
                    ),
                ],
              );
            }

            return WillPopScope(
              onWillPop: () async => !submitting,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * .9,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Form(
                      key: formKey,
                      child: AbsorbPointer(
                        absorbing: submitting,
                        child: StepFormDialogLayout(
                          title: personal == null
                              ? 'Registrar personal de salud'
                              : 'Editar personal de salud',
                          totalSteps: lastStepIndex + 1,
                          currentStep: currentStep,
                          stepErrorText: modalErrorText,
                          submitErrorText: submitErrorText,
                          isSubmitting: submitting,
                          onClose: submitting
                              ? null
                              : () => Navigator.pop(context),
                          onBack: currentStep > 0
                              ? () {
                                  setStateDialog(() {
                                    currentStep -= 1;
                                    modalErrorText = null;
                                    submitErrorText = null;
                                  });
                                }
                              : null,
                          nextLabel: currentStep == lastStepIndex
                              ? (personal == null ? 'Crear' : 'Guardar')
                              : 'Siguiente',
                          nextIcon: currentStep == lastStepIndex
                              ? (personal == null
                                    ? PhosphorIconsFill.userPlus
                                    : PhosphorIconsFill.floppyDisk)
                              : null,
                          stepContent: stepContent(),
                          onNext: () async {
                            if (currentStep < lastStepIndex) {
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
                                  modalErrorText = apellidoError;
                                });
                                return;
                              }
                              setStateDialog(() {
                                currentStep += 1;
                                modalErrorText = null;
                                submitErrorText = null;
                              });
                              return;
                            }

                            final isValid = validateForm(formKey);
                            if (!isValid) return;
                            setStateDialog(() {
                              modalErrorText = null;
                            });
                            if (!isEditing &&
                                (contrasena.text.isNotEmpty ||
                                    repetirContrasena.text.isNotEmpty) &&
                                contrasena.text != repetirContrasena.text) {
                              setStateDialog(() {
                                modalErrorText = 'Las contraseñas no coinciden';
                              });
                              return;
                            }

                            final persona = {
                              'nombres': nombres.text.trim(),
                              'primerApellido': primerApellido.text.trim(),
                              if (segundoApellido.text.trim().isNotEmpty)
                                'segundoApellido': segundoApellido.text.trim(),
                              'fechaNacimiento': _formatearFechaBackend(
                                fechaNacimiento.text,
                              ),
                              'nroDocumento': nroDocumento.text.trim(),
                              if (telefono.text.trim().isNotEmpty)
                                'telefono': telefono.text.trim(),
                              if ((generoSeleccionado ?? '').trim().isNotEmpty)
                                'genero': generoSeleccionado,
                            };
                            final idsOcupaciones = selectedOcupaciones
                                .map((ocupacion) => ocupacion.id)
                                .toList();

                            Map<String, dynamic> body;
                            if (personal == null) {
                              body = {
                                'persona': persona,
                                'correoElectronico': correo.text.trim(),
                                'contrasena': contrasena.text,
                                'repetirContrasena': repetirContrasena.text,
                                'esSupervisor': esSupervisor,
                                if (idsOcupaciones.isNotEmpty)
                                  'idOcupaciones': idsOcupaciones,
                              };
                            } else {
                              body = {
                                'persona': persona,
                                'correoElectronico': correo.text.trim(),
                                'esSupervisor': esSupervisor,
                                if (idsOcupaciones.isNotEmpty)
                                  'idOcupaciones': idsOcupaciones,
                              };
                            }

                            setStateDialog(() {
                              submitting = true;
                              submitErrorText = null;
                            });
                            final error = await _guardarPersonal(body, personal);
                            if (!mounted) return;
                            if (error == null) {
                              Navigator.pop(context);
                              return;
                            }
                            setStateDialog(() {
                              submitting = false;
                              submitErrorText = error;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      ocupacionesDebounce?.cancel();
      ocupacionesScrollController.dispose();
    });
  }

  Future<String?> _guardarPersonal(
    Map<String, dynamic> body,
    PersonalSalud? personal,
  ) async {
    if (_processingAction) return 'Ya existe una operación en curso';
    setState(() => _processingAction = true);

    final response = personal == null
        ? await _service.crearPersonalSalud(body)
        : await _service.actualizarPersonalSalud(personal.id, body);

    if (!mounted) return null;

    if (response.status != StatusNetwork.connected) {
      setState(() => _processingAction = false);
      return response.message.isEmpty
          ? 'No se pudo guardar el personal de salud.'
          : response.message;
    }

    showSnackBar(
      personalSaludMessenger,
      personal == null
          ? 'Personal de salud registrado correctamente.'
          : 'Personal de salud actualizado correctamente.',
      state: StatusSnackBar.success,
      colorText: _theme.white,
    );
    await _cargarPersonalSalud(page: 1);
    if (!mounted) return null;
    setState(() => _processingAction = false);
    return null;
  }

  Future<void> _confirmarCambioEstado(PersonalSalud personal) async {
    if (_processingAction) return;
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
    if (!mounted) return;

    setState(() => _processingAction = true);

    final response = estaActivo
        ? await _service.inactivarPersonalSalud(personal.id)
        : await _service.activarPersonalSalud(personal.id);

    if (!mounted) return;

    if (response.status != StatusNetwork.connected) {
      setState(() => _processingAction = false);
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
    await _cargarPersonalSalud(page: 1);
    if (!mounted) return;
    setState(() => _processingAction = false);
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

  Widget _buildOcupacionesCell(PersonalSalud personal) {
    if (personal.ocupaciones.isEmpty) {
      return const Text('Sin ocupaciones');
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: personal.ocupaciones
          .map(
            (ocupacion) => Chip(
              label: Text(ocupacion.nombre),
              backgroundColor: HexColor.fromHex(
                '#64748b',
              ).withValues(alpha: .15),
            ),
          )
          .toList(),
    );
  }

  Widget _buildOcupacionesResumen(PersonalSalud personal) {
    if (personal.ocupaciones.isEmpty) {
      return Text(
        'Sin ocupaciones asignadas',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final top = personal.ocupaciones.take(2).map((e) => e.nombre).toList();
    final extras = personal.ocupaciones.length - top.length;
    final resumen = extras > 0 ? '${top.join(' · ')}  +$extras' : top.join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _theme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.local_hospital_outlined, size: 15, color: _theme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              resumen,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
                final detallePrincipal = [
                  persona.nroDocumento ?? 'Sin documento',
                  if (persona.ocupaciones.isNotEmpty)
                    '${persona.ocupaciones.length} ocupaciones',
                ].join(' · ');
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _mostrarDetallesPersonal(persona),
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _theme.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _theme.white.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  horizontalTitleGap: 10,
                                  leading: _buildAvatar(persona, radius: 18),
                                  title: Text(
                                    persona.nombreCompleto,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  subtitle: Text(
                                    detallePrincipal,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: _buildEstadoChip(persona.estaActivo),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (persona.esSupervisor)
                                      _buildTipoPersonalChip(
                                        persona.esSupervisor,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _buildOcupacionesResumen(persona),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      );
  }

  Widget _buildLoadingMoreIndicator() {
    if (!_loadingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 840;
    final isNarrowHeader = MediaQuery.of(context).size.width < 560;
    return TemplatePage(
      showEnvironmentBanner: false,
      page: ScaffoldMessenger(
        key: personalSaludMessenger,
        child: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
          titulo: 'Personal de salud',
          subtitulo:
              'Administra perfiles, ocupaciones y permisos administrativos.',
          isCompact: isNarrowHeader,
          actions: [
            IconButton(
              onPressed: _processingAction ? null : _abrirFiltros,
              icon: Icon(Icons.filter_list, color: _theme.white),
              style: IconButton.styleFrom(
                minimumSize: const Size(36, 36),
                side: BorderSide(
                  color: _theme.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            IconButton(
              onPressed: _processingAction ? null : () => _abrirFormulario(),
              icon: Icon(Icons.add, color: _theme.white),
              style: IconButton.styleFrom(
                minimumSize: const Size(36, 36),
                side: BorderSide(
                  color: _theme.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSummary(),
                  const SizedBox(height: 12),
                  if (!isCompact)
                    CustomDesktopDataTable(
                      titulo: 'Gestión de personal de salud',
                      descripcion:
                          'Consulta, filtra y administra el personal de salud.',
                      acciones: [
                        IconButton(
                          onPressed:
                              _processingAction ? null : _cargarPersonalSalud,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                      columnas: [
                        CriterioOrdenType(nombre: 'Nombre'),
                        CriterioOrdenType(nombre: 'Documento'),
                        CriterioOrdenType(nombre: 'Estado'),
                        CriterioOrdenType(nombre: 'Ocupaciones'),
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
                              _buildOcupacionesCell(persona),
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
                                  if (!_esUsuarioActual(persona))
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: _processingAction
                                          ? null
                                          : () => _abrirFormulario(
                                                personal: persona,
                                              ),
                                    ),
                                  IconButton(
                                    tooltip: 'Ver detalles',
                                    icon: const Icon(Icons.visibility_outlined),
                                    onPressed: () =>
                                        _mostrarDetallesPersonal(persona),
                                  ),
                                  if (!_esUsuarioActual(persona))
                                    IconButton(
                                      tooltip: persona.estaActivo
                                          ? 'Inactivar'
                                          : 'Activar',
                                      icon: Icon(
                                        persona.estaActivo
                                            ? Icons.person_off_outlined
                                            : Icons.person_add_alt_1_outlined,
                                      ),
                                      onPressed: _processingAction
                                          ? null
                                          : () =>
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
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: _buildCompactList()),
                          _buildLoadingMoreIndicator(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_processingAction)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}
