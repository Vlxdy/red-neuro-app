import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/extensions/colores_extension.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/components/tray_ui_helpers.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/common/form_stepper/step_form_dialog_layout.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/estudios/estudios_service.dart';

final GlobalKey<ScaffoldMessengerState> estudiosMessenger =
    GlobalKey<ScaffoldMessengerState>();

class EstudiosPage extends StatefulWidget {
  const EstudiosPage({super.key});

  @override
  State<EstudiosPage> createState() => _EstudiosPageState();
}

class _EstudiosPageState extends State<EstudiosPage> with FormController {
  final _theme = ThemeController.instance;
  late final EstudiosService _service;

  List<Servicio> _servicios = [];
  List<Especialidad> _especialidadesDisponibles = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _loadingEspecialidades = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  String _filtro = '';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _service = EstudiosService(context);
    _cargarEspecialidadesDisponibles();
    _cargarServicios();
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
    if (current >= maxScroll - 200 && _servicios.length < _total) {
      _cargarServicios(page: _page + 1, append: true);
    }
  }

  Future<void> _cargarEspecialidadesDisponibles() async {
    setState(() => _loadingEspecialidades = true);
    final especialidades = await _service.obtenerEspecialidades();
    setState(() {
      _especialidadesDisponibles = especialidades;
      _loadingEspecialidades = false;
    });
  }

  Future<void> _cargarServicios({int? page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    final result = await _service.obtenerServicios(
      page: page ?? _page,
      limit: _limit,
      filtro: _filtro,
    );

    setState(() {
      if (append) {
        _servicios = [..._servicios, ...result.servicios];
      } else {
        _servicios = result.servicios;
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

    if (!mounted) return;
    if (result.status != StatusNetwork.connected) {
      showSnackBar(
        estudiosMessenger,
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
    _cargarServicios(page: 1);
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
              'Filtro de servicios: $_filtro',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filtro = '';
                _searchController.clear();
              });
              _cargarServicios(page: 1);
            },
            child: const Text('Quitar filtros'),
          ),
        ],
      ),
    );
  }

  String _validarRequerido(String? value, String alias) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Campo requerido';
    }
    return '';
  }

  String _validarDuracion(String? value, String alias) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Campo requerido';
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un número válido';
    }
    return '';
  }

  Future<void> _abrirFormulario({Servicio? servicio}) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: servicio?.nombre ?? '',
    );
    final descripcionController = TextEditingController(
      text: servicio?.descripcion ?? '',
    );
    final duracionController = TextEditingController(
      text: (servicio?.duracionMinutos ?? 30).toString(),
    );
    final costoController = TextEditingController(
      text: (servicio?.costo ?? 0).toStringAsFixed(2),
    );
    var tipoSeleccionado = (servicio?.tipo ?? 'ESTUDIO').toUpperCase();
    final especialidadesSeleccionadas =
        servicio?.especialidades.map((item) => item.id).toSet() ?? <String>{};
    const mostrarPasoEspecialidades = true;
    var currentStep = 0;
    String? modalError;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildStepContent() {
              if (!mostrarPasoEspecialidades || currentStep == 0) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextInput(
                      title: 'Nombre',
                      controller: nombreController,
                      requiredData: true,
                      validate: _validarRequerido,
                    ),
                    const SizedBox(height: 12),
                    CustomTextInput(
                      title: 'Descripción',
                      controller: descripcionController,
                      requiredData: true,
                      validate: _validarRequerido,
                      lines: 3,
                    ),
                    const SizedBox(height: 12),
                    CustomTextInput(
                      title: 'Duración (minutos)',
                      controller: duracionController,
                      requiredData: true,
                      validate: _validarDuracion,
                      onlyNumbers: true,
                    ),
                    const SizedBox(height: 12),
                    CustomTextInput(
                      title: 'Costo',
                      controller: costoController,
                      requiredData: true,
                      textFiltering: RegExp(r'[0-9.,]'),
                      validate: (value, alias) {
                        final raw = (value ?? '').trim();
                        if (raw.isEmpty) return 'Campo requerido';
                        if (!RegExp(r'^\d+(?:[\.,]\d{1,2})?$').hasMatch(raw)) {
                          return 'Ingresa un monto válido (máx. 2 decimales)';
                        }
                        final parsed = double.tryParse(
                          raw.replaceAll(',', '.'),
                        );
                        if (parsed == null || parsed < 0) {
                          return 'Ingresa un monto válido';
                        }
                        return '';
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tipo de servicio',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    RadioGroup<String>(
                      groupValue: tipoSeleccionado,
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => tipoSeleccionado = value);
                      },
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Consulta'),
                            value: 'CONSULTA',
                          ),
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Estudio'),
                            value: 'ESTUDIO',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (_loadingEspecialidades) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Especialidades asociadas',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_especialidadesDisponibles.isEmpty)
                    Text(
                      'No hay especialidades disponibles.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        itemCount: _especialidadesDisponibles.length,
                        itemBuilder: (context, index) {
                          final especialidad =
                              _especialidadesDisponibles[index];
                          return CheckboxListTile(
                            value: especialidadesSeleccionadas.contains(
                              especialidad.id,
                            ),
                            title: Text(especialidad.nombre),
                            subtitle: Text(especialidad.descripcion ?? '-'),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  especialidadesSeleccionadas.add(
                                    especialidad.id,
                                  );
                                } else {
                                  especialidadesSeleccionadas.remove(
                                    especialidad.id,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            }

            final totalSteps = mostrarPasoEspecialidades ? 2 : 1;
            final isLastStep = currentStep == totalSteps - 1;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      child: StepFormDialogLayout(
                        title: servicio == null
                            ? 'Nuevo servicio'
                            : 'Editar servicio',
                        totalSteps: totalSteps,
                        currentStep: currentStep,
                        stepErrorText: modalError,
                        isSubmitting: false,
                        stepContent: buildStepContent(),
                        onClose: () => Navigator.of(context).pop(false),
                        onBack: currentStep == 0
                            ? null
                            : () => setDialogState(() {
                                currentStep -= 1;
                                modalError = null;
                              }),
                        nextLabel: isLastStep
                            ? (servicio == null ? 'Crear' : 'Guardar')
                            : 'Siguiente',
                        onNext: () async {
                          if ((!mostrarPasoEspecialidades ||
                                  currentStep == 0) &&
                              (nombreController.text.trim().isEmpty ||
                                  descripcionController.text.trim().isEmpty)) {
                            setDialogState(() {
                              modalError =
                                  'Completa nombre y descripción para continuar.';
                            });
                            return;
                          }
                          final valid = validateForm(formKey);
                          if (!valid) return;
                          if (!isLastStep) {
                            if (_especialidadesDisponibles.isEmpty &&
                                !_loadingEspecialidades) {
                              await _cargarEspecialidadesDisponibles();
                            }
                            setDialogState(() {
                              currentStep += 1;
                              modalError = null;
                            });
                            return;
                          }
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
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

    final payload = {
      'nombre': nombreController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'duracionMinutos': int.parse(duracionController.text.trim()),
      'costo': double.parse(costoController.text.trim().replaceAll(',', '.')),
      'tipo': tipoSeleccionado,
      'especialidadIds': especialidadesSeleccionadas.toList(),
    };

    final response = servicio == null
        ? await _service.crearServicio(payload)
        : await _service.actualizarServicio(servicio.id, payload);

    if (!mounted) return;

    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarServicios();
    } else {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _cambiarEstado(Servicio servicio) async {
    final activando = servicio.estado.toUpperCase() != 'ACTIVO';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(activando ? 'Activar servicio' : 'Desactivar servicio'),
          content: Text(
            activando
                ? '¿Deseas activar el servicio "${servicio.nombre}"?'
                : '¿Deseas desactivar el servicio "${servicio.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(activando ? 'Activar' : 'Desactivar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final response = await _service.cambiarEstadoServicio(servicio.id);

    if (!mounted) return;
    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarServicios();
    } else {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Widget _buildEspecialidadesCell(Servicio servicio) {
    if (servicio.especialidades.isEmpty) {
      return const Text('-');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: servicio.especialidades
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

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    final isNarrowHeader = MediaQuery.of(context).size.width < 560;
    return ScaffoldMessenger(
      key: estudiosMessenger,
      child: TemplatePage(
        showEnvironmentBanner: false,
        page: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
            titulo: 'Servicios',
            subtitulo:
                'Administra servicios (consultas y estudios) y sus especialidades.',
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
                    titulo: 'Gestión de servicios médicos',
                    descripcion: 'Consulta y administra servicios clínicos.',
                    acciones: const [],
                    columnas: [
                      CriterioOrdenType(nombre: 'Nombre'),
                      CriterioOrdenType(nombre: 'Descripción'),
                      CriterioOrdenType(nombre: 'Tipo'),
                      CriterioOrdenType(nombre: 'Duración'),
                      CriterioOrdenType(nombre: 'Costo'),
                      CriterioOrdenType(nombre: 'Especialidades'),
                      CriterioOrdenType(nombre: 'Estado'),
                      CriterioOrdenType(nombre: 'Acciones'),
                    ],
                    contenidoTabla: _servicios
                        .map(
                          (servicio) => [
                            Text(servicio.nombre),
                            Text(servicio.descripcion),
                            Text(servicio.tipo.toUpperCase()),
                            Text('${servicio.duracionMinutos} min'),
                            Text('Bs ${servicio.costo.toStringAsFixed(2)}'),
                            _buildEspecialidadesCell(servicio),
                            TrayStatusBadge(
                              status: servicio.estado,
                              activeColor: _theme.success,
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _abrirFormulario(servicio: servicio),
                                ),
                                IconButton(
                                  tooltip:
                                      servicio.estado.toUpperCase() == 'ACTIVO'
                                      ? 'Desactivar'
                                      : 'Activar',
                                  icon: Icon(
                                    servicio.estado.toUpperCase() == 'ACTIVO'
                                        ? Icons.toggle_off
                                        : Icons.toggle_on,
                                    color: _theme.primary,
                                  ),
                                  onPressed: () => _cambiarEstado(servicio),
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
    final inicio = _servicios.isEmpty ? 0 : ((_page - 1) * _limit) + 1;
    final fin = (_page - 1) * _limit + _servicios.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mostrando $inicio - $fin de $_total servicios'),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1 && !_loading
                    ? () => _cargarServicios(page: _page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page'),
              IconButton(
                onPressed: (_page * _limit) < _total && !_loading
                    ? () => _cargarServicios(page: _page + 1)
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
    if (_servicios.isEmpty) {
      return Center(
        child: Text(
          'No hay servicios registrados.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cargarServicios(page: 1),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _servicios.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final servicio = _servicios[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _mostrarDetalleServicio(servicio),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      servicio.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text('Tipo: ${servicio.tipo.toUpperCase()}'),
                    trailing: TrayStatusBadge(
                      status: servicio.estado,
                      activeColor: _theme.success,
                    ),
                  ),
                  Text(
                    servicio.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      CopyableInfoPill(
                        icon: Icons.schedule_outlined,
                        label: 'Duración',
                        value: '${servicio.duracionMinutos} min',
                      ),
                      CopyableInfoPill(
                        icon: Icons.payments_outlined,
                        label: 'Costo',
                        value: 'Bs ${servicio.costo.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (servicio.especialidades.isEmpty)
                    Text(
                      'Sin especialidades asignadas.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: servicio.especialidades
                          .map(
                            (especialidad) => Chip(
                              label: Text(especialidad.nombre),
                              backgroundColor: HexColor.fromHex(
                                especialidad.colorHex,
                              ).withValues(alpha: .15),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 4),
                  if (_loadingMore && index == _servicios.length - 1) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalleServicio(Servicio servicio) {
    showModalBottomSheet<void>(
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle del servicio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(servicio.nombre,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TrayStatusBadge(
                  status: servicio.estado,
                  activeColor: _theme.success,
                ),
                const SizedBox(height: 8),
                Text(servicio.descripcion),
                Text('Tipo: ${servicio.tipo.toUpperCase()}'),
                Text('Duración: ${servicio.duracionMinutos} min'),
                Text('Costo: Bs ${servicio.costo.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                if (servicio.especialidades.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: servicio.especialidades
                        .map(
                          (especialidad) => Chip(
                            label: Text(especialidad.nombre),
                            backgroundColor: HexColor.fromHex(
                              especialidad.colorHex,
                            ).withValues(alpha: .15),
                          ),
                        )
                        .toList(),
                  ),
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
                          _abrirFormulario(servicio: servicio);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _cambiarEstado(servicio);
                        },
                        icon: Icon(
                          servicio.estado.toUpperCase() == 'ACTIVO'
                              ? Icons.toggle_off
                              : Icons.toggle_on,
                        ),
                        label: Text(
                          servicio.estado.toUpperCase() == 'ACTIVO'
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
  }
}
