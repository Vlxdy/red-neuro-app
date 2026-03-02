import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/paciente.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/pacientes/pacientes_service.dart';

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

  late final PacientesService _service;

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

  @override
  void initState() {
    super.initState();
    _service = PacientesService(context);
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

  Future<void> _confirmarEliminacion(Paciente paciente) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar paciente'),
          content:
              Text('¿Deseas eliminar a "${paciente.nombreCompleto}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final response = await _service.eliminarPaciente(paciente.id);

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
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Detalle del paciente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paciente.nombreCompleto,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Documento', paciente.nroDocumento),
                _buildDetailRow(
                  'Fecha de nacimiento',
                  _formatearFechaInicial(paciente.fechaNacimiento),
                ),
                _buildDetailRow('Celular', paciente.telefono),
                _buildDetailRow('Género', _formatearGenero(paciente.genero)),
                _buildDetailRow('Estado', paciente.estado),
                _buildDetailRow('Observación', paciente.observacion),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    final safeValue = (value ?? '').trim().isEmpty ? '-' : value!.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              safeValue,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
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
                            Chip(
                              label: Text(paciente.estado.toUpperCase()),
                              backgroundColor:
                                  (paciente.estado).toUpperCase() == 'ACTIVO'
                                      ? _theme.success.withValues(alpha: .15)
                                      : _theme.error.withValues(alpha: .15),
                              labelStyle: TextStyle(
                                color: (paciente.estado).toUpperCase() ==
                                        'ACTIVO'
                                    ? _theme.success
                                    : _theme.error,
                                fontWeight: FontWeight.w600,
                              ),
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
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      _confirmarEliminacion(paciente),
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
          return Card(
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
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          paciente.nombreCompleto,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        label: Text(paciente.estado.toUpperCase()),
                        backgroundColor:
                            (paciente.estado).toUpperCase() == 'ACTIVO'
                                ? _theme.success.withValues(alpha: .15)
                                : _theme.error.withValues(alpha: .15),
                        labelStyle: TextStyle(
                          color: (paciente.estado).toUpperCase() == 'ACTIVO'
                              ? _theme.success
                              : _theme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if ((paciente.nroDocumento ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Documento: ${paciente.nroDocumento}'),
                  ],
                  if ((paciente.telefono ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Celular: ${paciente.telefono}'),
                  ],
                  if ((paciente.fechaNacimiento ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Nacimiento: ${_formatearFechaInicial(paciente.fechaNacimiento)}',
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Género: ${_formatearGenero(paciente.genero)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if ((paciente.observacion ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(paciente.observacion ?? ''),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _verDetalle(paciente),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Ver detalle'),
                      ),
                      TextButton.icon(
                        onPressed: () => _abrirFormulario(paciente: paciente),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmarEliminacion(paciente),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                      ),
                      TextButton.icon(
                        onPressed: () => _cambiarEstado(paciente),
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
                  if (_loadingMore && index == _pacientes.length - 1) ...[
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
}
