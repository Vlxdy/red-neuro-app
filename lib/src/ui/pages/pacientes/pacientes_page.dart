import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/models/paciente.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/components/tray_ui_helpers.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_confirmacion_dialog.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_confirmar_solicitada_dialog.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_modal.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_formulario_modal_widget.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_listado.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_catalogo_selector_modal_widget.dart';
import 'package:red_neuro_app/src/ui/pages/pacientes/pacientes_service.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/inicio_citas_utils.dart';
import 'package:red_neuro_app/src/utils/role_utils.dart';

final GlobalKey<ScaffoldMessengerState> pacientesMessenger =
    GlobalKey<ScaffoldMessengerState>();

class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> with FormController {
  final _theme = ThemeController.instance;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  late final PacientesService _service;
  late final CitasService _citasService;

  List<Paciente> _pacientes = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _refreshingByScrollTop = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  String _filtro = '';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _rolActivo =>
      RoleUtils.normalizeRole(Auth.instance.profile.rol?.toString());

  bool get _puedeCrearPacientes =>
      _rolActivo != RoleUtils.personal &&
      _rolActivo != RoleUtils.profesionalInvitado;

  @override
  void initState() {
    super.initState();
    _service = PacientesService(context);
    _citasService = CitasService(context);
    _cargarPacientes();
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

    final position = _scrollController.position;
    final current = position.pixels;
    final maxScroll = position.maxScrollExtent;

    final isAtTop = current <= 0;
    final isScrollingUp =
        position.userScrollDirection == ScrollDirection.forward;
    if (isAtTop && isScrollingUp && !_refreshingByScrollTop) {
      _refreshingByScrollTop = true;
      _cargarPacientes(page: 1).whenComplete(() {
        _refreshingByScrollTop = false;
      });
      return;
    }

    if (current >= maxScroll - 200 && _pacientes.length < _total) {
      _cargarPacientes(page: _page + 1, append: true);
    }
  }

  String _validarRequerido(String? value, String alias) {
    if (value == null || value.trim().isEmpty) {
      return '$alias es requerido';
    }
    return '';
  }

  DateTime? _parseFechaNacimiento(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    try {
      return _dateFormatter.parseStrict(value);
    } catch (_) {
      try {
        return DateTime.parse(value.trim());
      } catch (_) {
        return null;
      }
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

  String _validarFechaOpcional(String? value, String alias) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }
    final fecha = _parseFechaNacimiento(value.trim());
    if (fecha == null) {
      return 'Ingresa una fecha válida (DD/MM/AAAA)';
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

  Widget _buildResponsiveFields({
    required bool isWide,
    required Widget first,
    required Widget second,
  }) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    }

    return Column(
      children: [
        first,
        const SizedBox(height: 12),
        second,
      ],
    );
  }

  String _formatearGenero(String? genero) {
    switch ((genero ?? '').toUpperCase()) {
      case 'F':
        return 'Femenino';
      case 'M':
        return 'Masculino';
      case 'O':
        return 'Otro';
      default:
        return '-';
    }
  }

  String _edadPaciente(String? fechaNacimiento) {
    final value = _formatearFechaInicial(fechaNacimiento).trim();
    if (value.isEmpty) return 'Sin edad';
    final fecha = _parseFechaNacimiento(value);
    if (fecha == null) return 'Sin edad';
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    if (edad < 0) return 'Sin edad';
    return '$edad años';
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

  Future<void> _cargarPacientes({int? page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    final result = await _service.obtenerPacientes(
      page: page ?? _page,
      limit: _limit,
      filtro: _filtro,
    );

    if (!mounted) return;
    setState(() {
      if (append) {
        _pacientes = [..._pacientes, ...result.pacientes];
      } else {
        _pacientes = result.pacientes;
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
        pacientesMessenger,
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
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o documento',
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
    _cargarPacientes(page: 1);
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
              _cargarPacientes(page: 1);
            },
            child: const Text('Quitar filtros'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormulario({Paciente? paciente}) async {
    final formKey = GlobalKey<FormState>();
    final nombres = TextEditingController(text: paciente?.nombres ?? '');
    final primerApellido = TextEditingController(
      text: paciente?.primerApellido ?? '',
    );
    final segundoApellido = TextEditingController(
      text: paciente?.segundoApellido ?? '',
    );
    final nroDocumento = TextEditingController(
      text: paciente?.nroDocumento ?? '',
    );
    final fechaNacimiento = TextEditingController(
      text: _formatearFechaInicial(paciente?.fechaNacimiento),
    );
    final telefono = TextEditingController(text: paciente?.telefono ?? '');
    final observacion = TextEditingController(
      text: paciente?.observacion ?? '',
    );
    String? generoSeleccionado = paciente?.genero;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isWide = MediaQuery.of(context).size.width > 700;
        String errorGuardado = '';
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setStateModal) {
            Future<void> guardarPaciente() async {
              setStateModal(() {
                errorGuardado = '';
              });

              final isValid = validateForm(formKey);
              if (!isValid) {
                setStateModal(() {
                  errorGuardado = 'Completa correctamente los campos requeridos.';
                });
                return;
              }

              final fechaBackend = _formatearFechaBackend(fechaNacimiento.text);
              final payload = <String, dynamic>{
                'nombres': nombres.text.trim().toUpperCase(),
                if (primerApellido.text.trim().isNotEmpty)
                  'primerApellido': primerApellido.text.trim().toUpperCase(),
                if (segundoApellido.text.trim().isNotEmpty)
                  'segundoApellido': segundoApellido.text.trim().toUpperCase(),
                if (nroDocumento.text.trim().isNotEmpty)
                  'nroDocumento': nroDocumento.text.trim(),
                if (fechaBackend.isNotEmpty) 'fechaNacimiento': fechaBackend,
                if (telefono.text.trim().isNotEmpty)
                  'telefono': telefono.text.trim(),
                if (generoSeleccionado?.trim().isNotEmpty ?? false)
                  'genero': generoSeleccionado,
                if (observacion.text.trim().isNotEmpty)
                  'observacion': observacion.text.trim(),
              };

              setStateModal(() {
                guardando = true;
              });

              final response = paciente == null
                  ? await _service.crearPaciente(payload)
                  : await _service.actualizarPaciente(paciente.id, payload);

              if (!mounted) return;

              setStateModal(() {
                guardando = false;
              });

              if (response.status == StatusNetwork.connected) {
                showSnackBar(
                  pacientesMessenger,
                  response.message,
                  state: StatusSnackBar.success,
                  colorText: _theme.white,
                );
                _cargarPacientes();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } else {
                setStateModal(() {
                  errorGuardado = response.message;
                });
                showSnackBar(
                  pacientesMessenger,
                  response.message,
                  state: StatusSnackBar.error,
                  colorText: _theme.white,
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        paciente == null ? 'Nuevo paciente' : 'Editar paciente',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        title: 'Nombres',
                        controller: nombres,
                        requiredData: true,
                        validate: _validarRequerido,
                        onChange: (value) {
                          _normalizarTextoMayusculas(nombres, value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildResponsiveFields(
                        isWide: isWide,
                        first: CustomTextInput(
                          title: 'Primer apellido',
                          controller: primerApellido,
                          onChange: (value) {
                            _normalizarTextoMayusculas(primerApellido, value);
                          },
                        ),
                        second: CustomTextInput(
                          title: 'Segundo apellido',
                          controller: segundoApellido,
                          onChange: (value) {
                            _normalizarTextoMayusculas(segundoApellido, value);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildResponsiveFields(
                        isWide: isWide,
                        first: CustomTextInput(
                          title: 'Número de documento (opcional)',
                          controller: nroDocumento,
                          onlyNumbers: true,
                        ),
                        second: CustomTextInput(
                          title: 'Celular (opcional)',
                          controller: telefono,
                          onlyNumbers: true,
                          validate: _validarCelular,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildResponsiveFields(
                        isWide: isWide,
                        first: CustomTextInput(
                          title: 'Fecha de nacimiento (DD/MM/AAAA)',
                          controller: fechaNacimiento,
                          placeholder: 'DD/MM/AAAA',
                          maxLength: 10,
                          textFiltering: RegExp(r'[0-9/]'),
                          onTap: () => _seleccionarFecha(fechaNacimiento),
                          validate: _validarFechaOpcional,
                        ),
                        second: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Género (opcional)',
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
                            setStateModal(() => generoSeleccionado = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextInput(
                        title: 'Observación (opcional)',
                        controller: observacion,
                        lines: 3,
                      ),
                      if (errorGuardado.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            errorGuardado,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SimpleButton(
                              title: 'Cancelar',
                              outlined: true,
                              background: _theme.primary,
                              onTap: guardando
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SimpleButton(
                              title: guardando
                                  ? 'Guardando...'
                                  : (paciente == null ? 'Crear' : 'Guardar'),
                              onTap: guardando ? null : guardarPaciente,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }
  }

  Future<void> _cambiarEstado(Paciente paciente) async {
    final response = await _service.cambiarEstadoPaciente(paciente.id);

    if (!mounted) return;
    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        pacientesMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarPacientes();
    } else {
      showSnackBar(
        pacientesMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  void _verDetalle(Paciente paciente) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? copiedField;
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle del paciente',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    PhosphorIconsRegular.userCircle,
                    color: _theme.primary,
                  ),
                  title: Text(
                    paciente.nombreCompleto,
                    style: theme.textTheme.titleMedium,
                  ),
                  trailing: TrayStatusBadge(
                    status: paciente.estado,
                    activeColor: _theme.success,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((paciente.nroDocumento ?? '').trim().isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.badge_outlined,
                        label: 'Documento',
                        value: paciente.nroDocumento!.trim(),
                        copied: copiedField == 'documento',
                        onTap: () async {
                          await _copiarDatoPaciente(
                            paciente.nroDocumento!.trim(),
                          );
                          if (!mounted) return;
                          setStateSheet(() => copiedField = 'documento');
                        },
                      ),
                    if ((paciente.telefono ?? '').trim().isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.phone_outlined,
                        label: 'Celular',
                        value: paciente.telefono!.trim(),
                        copied: copiedField == 'celular',
                        onTap: () async {
                          await _copiarDatoPaciente(
                            paciente.telefono!.trim(),
                          );
                          if (!mounted) return;
                          setStateSheet(() => copiedField = 'celular');
                        },
                      ),
                    if (_formatearFechaInicial(paciente.fechaNacimiento)
                        .trim()
                        .isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.cake_outlined,
                        label: 'Nacimiento',
                        value: _formatearFechaInicial(paciente.fechaNacimiento),
                      ),
                    if (_formatearGenero(paciente.genero).trim().isNotEmpty)
                      CopyableInfoPill(
                        icon: Icons.wc_outlined,
                        label: 'Género',
                        value: _formatearGenero(paciente.genero),
                      ),
                  ],
                ),
                if ((paciente.observacion ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Observación',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(paciente.observacion!.trim()),
                ],
                const SizedBox(height: 12),
                    SafeArea(
                      top: false,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _theme.primary,
                              foregroundColor: _theme.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _abrirFormulario(paciente: paciente);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _verCitasPaciente(paciente);
                            },
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: const Text('Ver citas'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _cambiarEstado(paciente);
                            },
                            icon: Icon(
                              paciente.estado.toUpperCase() == 'ACTIVO'
                                  ? Icons.toggle_off
                                  : Icons.toggle_on,
                            ),
                            label: Text(
                              paciente.estado.toUpperCase() == 'ACTIVO'
                                  ? 'Desactivar'
                                  : 'Activar',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _copiarDatoPaciente(String valor) async {
    await Clipboard.setData(ClipboardData(text: valor));
  }

  Future<bool> _handleResponseErrorCita(
    dynamic response,
    String fallback,
  ) async {
    if (response is! ResponseApi) {
      await showErrorDialog(context, fallback);
      return false;
    }
    if (response.status == StatusNetwork.connected) return true;
    final message = response.message.isNotEmpty ? response.message : fallback;
    await showErrorDialog(context, message);
    return false;
  }

  Future<bool> _confirmarAccionSimpleCita({
    required String titulo,
    required String mensaje,
    required String accion,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(accion),
          ),
        ],
      ),
    );
    return confirmar == true;
  }

  Future<String?> _confirmarAccionCita({
    required bool esNueva,
    required String tipoCita,
    required String servicioNombre,
    required DateTime fechaInicio,
    int? duracionMinutos,
    String? pacienteNombre,
    String? ocupacionNombre,
    String? medicoNombre,
    String? pacienteDocumento,
    String? pacienteTelefono,
    String? pacienteGenero,
    String? lugarNombre,
    String? lugarDireccion,
    String? detalle,
  }) {
    return showCitaConfirmacionDialog(
      context: context,
      data: CitaAccionConfirmacionData(
        esNueva: esNueva,
        tipoCita: tipoCita,
        servicioNombre: servicioNombre,
        fechaInicio: fechaInicio,
        duracionMinutos: duracionMinutos,
        pacienteNombre: pacienteNombre,
        ocupacionNombre: ocupacionNombre,
        medicoNombre: medicoNombre,
        pacienteDocumento: pacienteDocumento,
        pacienteTelefono: pacienteTelefono,
        pacienteGenero: pacienteGenero,
        lugarNombre: lugarNombre,
        lugarDireccion: lugarDireccion,
        detalle: detalle,
      ),
      dateTimeFormat: _dateTimeFormatter,
      formatearGenero: InicioCitasUtils.formatearGenero,
    );
  }

  DateTime _resolveDefaultStartTimePaciente(DateTime baseDay) {
    return DateTime(baseDay.year, baseDay.month, baseDay.day, 8);
  }

  IconData _iconoTipoCitaPaciente(CitaMedica cita) {
    final tipo = (cita.tipoCita ?? '').trim().toUpperCase();
    if (tipo == 'ESTUDIO') return Icons.science_outlined;
    return Icons.medical_services_outlined;
  }

  Future<void> _mostrarHistorialCitaPaciente(CitaMedica cita) async {
    await InicioCitasUtils.mostrarHistorialCita(
      context: context,
      cita: cita,
      service: _citasService,
      theme: _theme,
      dateFormat: _dateFormatter,
      dateTimeFormat: _dateTimeFormatter,
    );
  }

  Future<void> _abrirFormularioCitaPaciente({
    CitaMedica? cita,
    bool programarControl = false,
    Future<void> Function()? onUpdated,
  }) async {
    await abrirCitasFormularioModal(
      context: context,
      theme: _theme,
      service: _citasService,
      dateFormat: _dateFormatter,
      timeFormat: DateFormat('HH:mm'),
      messengerKey: pacientesMessenger,
      selectedDay: null,
      currentTabIndex: 2,
      resolveDefaultStartTime: _resolveDefaultStartTimePaciente,
      validarRequerido: _validarRequerido,
      calcularEdadPaciente: InicioCitasUtils.calcularEdadPaciente,
      formatearFechaPaciente: InicioCitasUtils.formatearFechaPaciente,
      formatearGenero: InicioCitasUtils.formatearGenero,
      puedeGestionarSolicitada: (citaItem) =>
          CitasUtils.puedeGestionarSolicitada(citaItem, Auth.instance.profile),
      colorEstado: (estado) => CitasUtils.colorEstado(estado, _theme),
      formatearTipoCita: CitasUtils.formatearTipoCita,
      confirmarAccionCita: _confirmarAccionCita,
      confirmarAccionSimple: _confirmarAccionSimpleCita,
      handleResponseError: _handleResponseErrorCita,
      cargarCitasCalendario: () async => onUpdated?.call(),
      cargarCitasListado: ({int? page}) async => onUpdated?.call(),
      mostrarHistorialCita: _mostrarHistorialCitaPaciente,
      eliminarCitaEditable: (citaItem) async {
        final confirmar = await _confirmarAccionSimpleCita(
          titulo: 'Eliminar borrador',
          mensaje: '¿Confirmas eliminar este borrador de cita?',
          accion: 'Sí, eliminar',
        );
        if (!confirmar) return false;
        final ok = await _handleResponseErrorCita(
          await _citasService.eliminarCitaBorrador(citaItem.id),
          'No se pudo eliminar el borrador.',
        );
        if (ok) await onUpdated?.call();
        return ok;
      },
      cita: cita,
      programarControl: programarControl,
    );
  }

  Future<void> _mostrarDetalleCitaPaciente(
    CitaMedica cita,
    Future<void> Function() onUpdated,
  ) async {
    final payload = CitasUtils.construirDetalleModalPayload(
      cita: cita,
      theme: _theme,
      titulo: 'Detalle de cita',
      nombrePaciente: InicioCitasUtils.nombrePaciente,
      formatearGenero: InicioCitasUtils.formatearGenero,
      formatearFechaPaciente: InicioCitasUtils.formatearFechaPaciente,
      calcularEdadPaciente: InicioCitasUtils.calcularEdadPaciente,
      etiquetaPrestacion: InicioCitasUtils.etiquetaPrestacion,
      nombreMedico: InicioCitasUtils.nombreMedico,
      resolveAvatarUrl: (url) => (url ?? '').trim(),
      inicialesPersonal: InicioCitasUtils.inicialesPersonal,
      formatoFechaCita: InicioCitasUtils.formatoFechaCita,
      formatoHorarioCita: InicioCitasUtils.formatoHorarioCita,
    );

    final acciones = CitasUtils.construirAccionesDetalleCita(
      cita: cita,
      puedeGestionarSolicitada: (item) =>
          CitasUtils.puedeGestionarSolicitada(item, Auth.instance.profile),
      puedeEditarCita: (item) =>
          CitasUtils.puedeEditarCita(item, perfil: Auth.instance.profile),
      citaYaIniciada: InicioCitasUtils.citaYaIniciada,
      confirmarCitaSolicitada: (item) async {
        final result = await showCitasConfirmarSolicitadaDialog(
          context: context,
          cita: item,
          dateTimeFormat: _dateTimeFormatter,
        );
        if (result == null) return false;
        final ok = await _handleResponseErrorCita(
          await _citasService.confirmarCita(
            item.id,
            body: result.toRequestBody(item),
          ),
          'No se pudo confirmar la cita.',
        );
        if (ok) await onUpdated();
        return ok;
      },
      rechazarCitaSolicitada: (item) async {
        final motivo = await InicioCitasUtils.solicitarMotivoRechazo(context);
        if (motivo == null) return false;
        final ok = await _handleResponseErrorCita(
          await _citasService.rechazarCita(item.id, motivoRechazo: motivo),
          'No se pudo rechazar la cita.',
        );
        if (ok) await onUpdated();
        return ok;
      },
      completarCita: (item) async {
        final ok = await InicioCitasUtils.confirmarYEnviar(
          context: context,
          titulo: 'Dar alta',
          mensaje: '¿Deseas cerrar la atención y dar de alta esta cita?',
          request: () => _citasService.darAltaCita(item.id),
          fallback: 'No se pudo dar de alta la cita.',
          mounted: mounted,
          onError: (msg) => showSnackBar(
            pacientesMessenger,
            msg,
            state: StatusSnackBar.error,
            colorText: _theme.white,
          ),
        );
        if (ok) await onUpdated();
      },
      programarControl: (item) async {
        await _abrirFormularioCitaPaciente(
          cita: item,
          programarControl: true,
          onUpdated: onUpdated,
        );
      },
      marcarNoAsistioCita: (item) async {
        final ok = await InicioCitasUtils.confirmarYEnviar(
          context: context,
          titulo: 'Marcar no asistió',
          mensaje: '¿Deseas marcar la cita como no asistió?',
          request: () => _citasService.marcarNoAsistioCita(item.id),
          fallback: 'No se pudo actualizar la cita.',
          mounted: mounted,
          onError: (msg) => showSnackBar(
            pacientesMessenger,
            msg,
            state: StatusSnackBar.error,
            colorText: _theme.white,
          ),
        );
        if (ok) await onUpdated();
      },
      reprogramarCita: (item) async {
        await _abrirFormularioCitaPaciente(cita: item, onUpdated: onUpdated);
      },
      cancelarCita: (item) async {
        final confirmar = await _confirmarAccionSimpleCita(
          titulo: 'Cancelar cita',
          mensaje: '¿Confirmas cancelar esta cita?',
          accion: 'Cancelar cita',
        );
        if (!confirmar) return;
        final ok = await _handleResponseErrorCita(
          await _citasService.cancelarCita(item.id),
          'No se pudo cancelar la cita.',
        );
        if (ok) await onUpdated();
      },
      eliminarBorrador: (item) async {
        final confirmar = await _confirmarAccionSimpleCita(
          titulo: 'Eliminar borrador',
          mensaje: '¿Confirmas eliminar este borrador?',
          accion: 'Eliminar',
        );
        if (!confirmar) return;
        final ok = await _handleResponseErrorCita(
          await _citasService.eliminarCitaBorrador(item.id),
          'No se pudo eliminar el borrador.',
        );
        if (ok) await onUpdated();
      },
      abrirFormulario: (item) =>
          _abrirFormularioCitaPaciente(cita: item, onUpdated: onUpdated),
    );

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return CitasDetalleModal.fromPayload(
          cita: cita,
          theme: _theme,
          payload: payload,
          acciones: acciones,
          onClose: () => Navigator.of(sheetContext).pop(),
          onVerHistorial: () => _mostrarHistorialCitaPaciente(cita),
          onCopiarDato: _copiarDatoPaciente,
        );
      },
    );
  }

  Future<void> _verCitasPaciente(Paciente paciente) async {
    final estadoController = TextEditingController(text: 'Todos');
    final personalController = TextEditingController();
    final lugarController = TextEditingController();
    final fechaInicioController = TextEditingController();
    final fechaFinController = TextEditingController();
    final tipoCitaController = TextEditingController(text: 'Todos');

    DateTime? fechaInicio;
    DateTime? fechaFin;
    String? estadoSeleccionado;
    String? tipoCitaSeleccionado;
    String? personalIdSeleccionado;
    String? lugarIdSeleccionado;
    int page = 1;
    const limit = 10;
    int total = 0;
    bool loading = true;
    bool loadingMore = false;
    bool dialogOpen = true;
    bool initialLoadRequested = false;
    List<CitaMedica> citas = [];

    Future<void> pickDate(
      BuildContext context, {
      required bool isStart,
      required VoidCallback refresh,
    }) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: (isStart ? fechaInicio : fechaFin) ?? now,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 10),
      );
      if (picked == null) return;
      if (isStart) {
        fechaInicio = DateTime(picked.year, picked.month, picked.day);
        fechaInicioController.text = _dateFormatter.format(fechaInicio!);
      } else {
        fechaFin = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        fechaFinController.text = _dateFormatter.format(fechaFin!);
      }
      refresh();
    }

    Future<void> cargarCitas(
      StateSetter setStateSheet, {
      bool reset = false,
      bool force = false,
    }) async {
      if ((loading || loadingMore) && !force) return;

      if (reset) {
        page = 1;
        total = 0;
        citas = [];
      }

      if (!dialogOpen) return;
      setStateSheet(() {
        if (page == 1) {
          loading = true;
        } else {
          loadingMore = true;
        }
      });

      final filtros = <String, String>{
        if ((estadoSeleccionado ?? '').trim().isNotEmpty)
          'estado': estadoSeleccionado!.trim(),
        if ((tipoCitaSeleccionado ?? '').trim().isNotEmpty)
          'tipoCita': tipoCitaSeleccionado!.trim(),
        if ((personalIdSeleccionado ?? '').trim().isNotEmpty)
          'idPersonal': personalIdSeleccionado!.trim(),
        if ((lugarIdSeleccionado ?? '').trim().isNotEmpty)
          'idLugar': lugarIdSeleccionado!.trim(),
        if (fechaInicio != null) 'fechaInicioDesde': fechaInicio!.toUtc().toIso8601String(),
        if (fechaFin != null) 'fechaInicioHasta': fechaFin!.toUtc().toIso8601String(),
      };

      final result = await _service.obtenerCitasPaciente(
        pacienteId: paciente.id,
        page: page,
        limit: limit,
        filtros: filtros,
      );

      if (!mounted || !dialogOpen) return;

      setStateSheet(() {
        if (page == 1) {
          citas = result.citas;
        } else {
          citas = [...citas, ...result.citas];
        }
        total = result.total;
        if (citas.length < total && result.citas.isNotEmpty) {
          page += 1;
        }
        loading = false;
        loadingMore = false;
      });
    }

    Future<void> abrirFiltros(StateSetter setStateSheet) async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setStateFilters) {
              Future<void> seleccionarEstado() async {
                final seleccionado = await showModalBottomSheet<String?>(
                  context: sheetContext,
                  builder: (context) => SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title: const Text('Todos'),
                          onTap: () => Navigator.pop(context, ''),
                        ),
                        ...CitasEstado.values.map(
                          (estado) => ListTile(
                            title: Text(estado.label),
                            onTap: () => Navigator.pop(context, estado.value),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if ((seleccionado ?? '').isEmpty) {
                  estadoSeleccionado = null;
                  estadoController.text = 'Todos';
                } else {
                  estadoSeleccionado = seleccionado;
                  estadoController.text = CitasEstado.labelFromValue(seleccionado);
                }
                setStateFilters(() {});
              }

              Future<void> seleccionarTipo() async {
                final seleccionado = await showModalBottomSheet<String?>(
                  context: sheetContext,
                  builder: (context) => SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title: const Text('Todos'),
                          onTap: () => Navigator.pop(context, ''),
                        ),
                        ListTile(
                          title: const Text('Consulta'),
                          onTap: () => Navigator.pop(context, 'CONSULTA'),
                        ),
                        ListTile(
                          title: const Text('Estudio'),
                          onTap: () => Navigator.pop(context, 'ESTUDIO'),
                        ),
                      ],
                    ),
                  ),
                );
                tipoCitaSeleccionado = (seleccionado ?? '').isEmpty
                    ? null
                    : seleccionado;
                tipoCitaController.text = tipoCitaSeleccionado == null
                    ? 'Todos'
                    : (tipoCitaSeleccionado == 'CONSULTA'
                        ? 'Consulta'
                        : 'Estudio');
                setStateFilters(() {});
              }

              Future<void> seleccionarPersonal() async {
                final seleccionado = await showModalBottomSheet<dynamic>(
                  context: sheetContext,
                  isScrollControlled: true,
                  builder: (_) => CitasMedicoSelectorModalWidget(
                    cargarMedicos: _citasService.obtenerPersonalMedico,
                  ),
                );
                if (seleccionado == null) return;
                personalIdSeleccionado = seleccionado.id;
                personalController.text = seleccionado.nombreCompleto;
                setStateFilters(() {});
              }

              Future<void> seleccionarLugar() async {
                final seleccionado = await showModalBottomSheet<dynamic>(
                  context: sheetContext,
                  isScrollControlled: true,
                  builder: (_) => CitasLugarSelectorModalWidget(
                    cargarLugares: _citasService.obtenerLugares,
                  ),
                );
                if (seleccionado == null) return;
                lugarIdSeleccionado = seleccionado.id;
                lugarController.text = seleccionado.nombre;
                setStateFilters(() {});
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: estadoController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.expand_more),
                        ),
                        onTap: seleccionarEstado,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: tipoCitaController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de cita',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.expand_more),
                        ),
                        onTap: seleccionarTipo,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: personalController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Personal asignado',
                          border: const OutlineInputBorder(),
                          suffixIcon: personalIdSeleccionado == null
                              ? const Icon(Icons.expand_more)
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    personalIdSeleccionado = null;
                                    personalController.clear();
                                    setStateFilters(() {});
                                  },
                                ),
                        ),
                        onTap: seleccionarPersonal,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: lugarController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Lugar',
                          border: const OutlineInputBorder(),
                          suffixIcon: lugarIdSeleccionado == null
                              ? const Icon(Icons.expand_more)
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    lugarIdSeleccionado = null;
                                    lugarController.clear();
                                    setStateFilters(() {});
                                  },
                                ),
                        ),
                        onTap: seleccionarLugar,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: fechaInicioController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Desde',
                                border: OutlineInputBorder(),
                              ),
                              onTap: () => pickDate(
                                sheetContext,
                                isStart: true,
                                refresh: () => setStateFilters(() {}),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: fechaFinController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Hasta',
                                border: OutlineInputBorder(),
                              ),
                              onTap: () => pickDate(
                                sheetContext,
                                isStart: false,
                                refresh: () => setStateFilters(() {}),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              estadoSeleccionado = null;
                              tipoCitaSeleccionado = null;
                              personalIdSeleccionado = null;
                              lugarIdSeleccionado = null;
                              estadoController.text = 'Todos';
                              tipoCitaController.text = 'Todos';
                              personalController.clear();
                              lugarController.clear();
                              fechaInicio = null;
                              fechaFin = null;
                              fechaInicioController.clear();
                              fechaFinController.clear();
                              setStateFilters(() {});
                            },
                            child: const Text('Limpiar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              await cargarCitas(setStateSheet, reset: true);
                            },
                            child: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            if (loading && citas.isEmpty && page == 1) {
              if (!initialLoadRequested) {
                initialLoadRequested = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    cargarCitas(setStateSheet, force: true);
                  }
                });
              }
            }
            final hasMore = citas.length < total;

            return Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Citas de ${paciente.nombreCompleto}'),
                  actions: [
                    IconButton(
                      onPressed: () => abrirFiltros(setStateSheet),
                      icon: const Icon(Icons.filter_list),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (estadoSeleccionado != null ||
                        tipoCitaSeleccionado != null ||
                        personalIdSeleccionado != null ||
                        lugarIdSeleccionado != null ||
                        fechaInicio != null ||
                        fechaFin != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (estadoSeleccionado != null)
                                  Chip(
                                    label: Text(
                                      'Estado: ${CitasEstado.labelFromValue(estadoSeleccionado)}',
                                    ),
                                  ),
                                if (tipoCitaSeleccionado != null)
                                  Chip(label: Text('Tipo: ${tipoCitaController.text}')),
                                if (personalIdSeleccionado != null)
                                  Chip(label: Text('Personal: ${personalController.text}')),
                                if (lugarIdSeleccionado != null)
                                  Chip(label: Text('Lugar: ${lugarController.text}')),
                                if (fechaInicio != null)
                                  Chip(
                                    label: Text(
                                      'Desde: ${_dateFormatter.format(fechaInicio!)}',
                                    ),
                                  ),
                                if (fechaFin != null)
                                  Chip(
                                    label: Text(
                                      'Hasta: ${_dateFormatter.format(fechaFin!)}',
                                    ),
                                  ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () async {
                                  estadoSeleccionado = null;
                                  tipoCitaSeleccionado = null;
                                  personalIdSeleccionado = null;
                                  lugarIdSeleccionado = null;
                                  estadoController.text = 'Todos';
                                  tipoCitaController.text = 'Todos';
                                  personalController.clear();
                                  lugarController.clear();
                                  fechaInicio = null;
                                  fechaFin = null;
                                  fechaInicioController.clear();
                                  fechaFinController.clear();
                                  await cargarCitas(setStateSheet, reset: true);
                                },
                                child: const Text('Limpiar filtros'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (loading && citas.isEmpty)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (citas.isEmpty)
                      const Expanded(child: Center(child: Text('No hay citas para este paciente.')))
                    else
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: CitasListado(
                            citas: citas,
                            theme: _theme,
                            controller: null,
                            onRefresh: () => cargarCitas(setStateSheet, reset: true),
                            colorEstado: (estado) => CitasUtils.colorEstado(estado, _theme),
                            colorOcupacion: (cita) =>
                                CitasUtils.colorEstado(cita.estado, _theme),
                            formatoFecha: InicioCitasUtils.formatoFechaCita,
                            formatoHorario: InicioCitasUtils.formatoHorarioCita,
                            tituloCita: (cita) =>
                                (cita.detalle.trim().isNotEmpty ? cita.detalle : 'Cita'),
                            iconoTipoCita: _iconoTipoCitaPaciente,
                            nombreMedico: InicioCitasUtils.nombreMedico,
                            nombrePaciente: InicioCitasUtils.nombrePaciente,
                            onVerDetalle: (cita) => () => _mostrarDetalleCitaPaciente(
                              cita,
                              () => cargarCitas(setStateSheet, reset: true),
                            ),
                            onEditar: (cita) => () => _abrirFormularioCitaPaciente(
                              cita: cita,
                              onUpdated: () => cargarCitas(setStateSheet, reset: true),
                            ),
                            puedeEditar: (cita) =>
                                CitasUtils.puedeEditarCita(cita, perfil: Auth.instance.profile),
                            showActionIcons: false,
                          ),
                        ),
                      ),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: loadingMore
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  onPressed: () => cargarCitas(setStateSheet),
                                  child: const Text('Cargar más'),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      dialogOpen = false;
    });

    estadoController.dispose();
    personalController.dispose();
    lugarController.dispose();
    fechaInicioController.dispose();
    fechaFinController.dispose();
    tipoCitaController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    final isNarrowHeader = MediaQuery.of(context).size.width < 560;
    return ScaffoldMessenger(
      key: pacientesMessenger,
      child: TemplatePage(
        showEnvironmentBanner: false,
        page: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
            titulo: 'Pacientes',
            subtitulo: 'Gestiona el listado de pacientes registrados.',
            isCompact: isNarrowHeader,
            actions: [
              IconButton(
                onPressed: _abrirFiltros,
                icon: Icon(Icons.filter_list, color: _theme.white),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  side: BorderSide(
                    color: _theme.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
              if (_puedeCrearPacientes)
                IconButton(
                  onPressed: () => _abrirFormulario(),
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
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterSummary(),
                const SizedBox(height: 12),
                if (!isCompact)
                  CustomDesktopDataTable(
                    titulo: 'Gestión de pacientes',
                    descripcion:
                        'Consulta, filtra y administra pacientes registrados.',
                    acciones: [
                      IconButton(
                        onPressed: _cargarPacientes,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                    columnas: [
                      CriterioOrdenType(nombre: 'Nombre'),
                      CriterioOrdenType(nombre: 'Documento'),
                      CriterioOrdenType(nombre: 'Celular'),
                      CriterioOrdenType(nombre: 'Género'),
                      CriterioOrdenType(nombre: 'Estado'),
                      CriterioOrdenType(nombre: 'Acciones'),
                    ],
                    contenidoTabla: _pacientes
                        .map(
                          (paciente) => [
                            Text(paciente.nombreCompleto),
                            Text(paciente.nroDocumento ?? '-'),
                            Text(paciente.telefono ?? '-'),
                            Text(_formatearGenero(paciente.genero)),
                            TrayStatusBadge(
                              status: paciente.estado,
                              activeColor: _theme.success,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Ver detalle',
                                  icon: const Icon(Icons.visibility_outlined),
                                  onPressed: () => _verDetalle(paciente),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _abrirFormulario(
                                    paciente: paciente,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Ver citas',
                                  icon: const Icon(Icons.calendar_month_outlined),
                                  onPressed: () => _verCitasPaciente(paciente),
                                ),
                                IconButton(
                                  tooltip: paciente.estado.toUpperCase() ==
                                          'ACTIVO'
                                      ? 'Desactivar'
                                      : 'Activar',
                                  icon: Icon(
                                    paciente.estado.toUpperCase() == 'ACTIVO'
                                        ? Icons.toggle_off
                                        : Icons.toggle_on,
                                    color: _theme.primary,
                                  ),
                                  onPressed: () => _cambiarEstado(paciente),
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
                    child: _buildCompactList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final inicio = _pacientes.isEmpty ? 0 : ((_page - 1) * _limit) + 1;
    final fin = (_page - 1) * _limit + _pacientes.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mostrando $inicio - $fin de $_total pacientes'),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1 && !_loading
                    ? () => _cargarPacientes(page: _page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page'),
              IconButton(
                onPressed: (_page * _limit) < _total && !_loading
                    ? () => _cargarPacientes(page: _page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _datosPrioritariosPaciente(Paciente paciente) {
    final candidatos = <MapEntry<String, String>>[
      MapEntry('Celular', (paciente.telefono ?? '').trim()),
      MapEntry('Género', _formatearGenero(paciente.genero).trim()),
      MapEntry('Edad', _edadPaciente(paciente.fechaNacimiento).trim()),
      MapEntry('Documento', (paciente.nroDocumento ?? '').trim()),
    ];

    final disponibles = candidatos.where((dato) {
      final valor = dato.value.trim();
      return valor.isNotEmpty &&
          valor.toLowerCase() != 'sin género' &&
          valor.toLowerCase() != 'sin edad';
    }).toList();

    final seleccionados = <MapEntry<String, String>>[];
    seleccionados.addAll(disponibles.take(2));

    if (seleccionados.length < 2) {
      for (final candidato in candidatos) {
        if (seleccionados.any((dato) => dato.key == candidato.key)) {
          continue;
        }
        final valor = candidato.value.trim();
        final fallback = valor.isEmpty ? 'Sin ${candidato.key.toLowerCase()}' : valor;
        seleccionados.add(MapEntry(candidato.key, fallback));
        if (seleccionados.length == 2) break;
      }
    }

    return seleccionados;
  }

  IconData _iconoDatoPaciente(String label) {
    switch (label) {
      case 'Celular':
        return Icons.phone_outlined;
      case 'Género':
        return Icons.wc_outlined;
      case 'Edad':
        return Icons.cake_outlined;
      case 'Documento':
        return Icons.badge_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _estadoPacienteIcono(String estado) {
    final activo = estado.trim().toUpperCase() == 'ACTIVO';
    final color = activo ? _theme.success : Colors.grey;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Icon(
        activo ? Icons.check : Icons.pause,
        size: 14,
        color: color,
      ),
    );
  }

  Widget _buildCompactList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pacientes.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _cargarPacientes(page: 1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  'No hay pacientes registrados.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cargarPacientes(page: 1),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _pacientes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final paciente = _pacientes[index];
          final datos = _datosPrioritariosPaciente(paciente);

          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _verDetalle(paciente),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _theme.bgCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _theme.monochromatic500.withValues(
                              alpha: _theme.isDark ? 0.85 : 0.55,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.userCircle,
                                    color: _theme.primary,
                                    size: 34,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      paciente.nombreCompleto,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _estadoPacienteIcono(paciente.estado),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final usarDosColumnas = constraints.maxWidth >= 300;
                                  if (usarDosColumnas) {
                                    return Row(
                                      children: [
                                        for (var i = 0; i < datos.length; i++) ...[
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _iconoDatoPaciente(datos[i].key),
                                                  size: 14,
                                                  color: _theme.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    datos[i].value,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (i == 0) const SizedBox(width: 10),
                                        ],
                                      ],
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: datos
                                        .map(
                                          (dato) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _iconoDatoPaciente(dato.key),
                                                  size: 14,
                                                  color: _theme.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    dato.value,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_loadingMore && index == _pacientes.length - 1) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          );
        },
      ),
    );
  }
}
