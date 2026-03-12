import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/ocupacion.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/components/tray_ui_helpers.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/form_stepper/step_form_dialog_layout.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/ocupaciones/ocupaciones_service.dart';

final GlobalKey<ScaffoldMessengerState> ocupacionesMessenger =
    GlobalKey<ScaffoldMessengerState>();

class OcupacionesPage extends StatefulWidget {
  const OcupacionesPage({super.key});

  @override
  State<OcupacionesPage> createState() => _OcupacionesPageState();
}

class _OcupacionesPageState extends State<OcupacionesPage>
    with FormController {
  final _theme = ThemeController.instance;
  late final OcupacionesService _service;

  List<Ocupacion> _ocupaciones = [];
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  String _filtro = '';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _service = OcupacionesService(context);
    _cargarOcupaciones();
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
    if (current >= maxScroll - 200 && _ocupaciones.length < _total) {
      _cargarOcupaciones(page: _page + 1, append: true);
    }
  }

  Future<void> _cargarOcupaciones({int? page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    final result = await _service.obtenerOcupaciones(
      page: page ?? _page,
      limit: _limit,
      filtro: _filtro,
    );

    setState(() {
      if (append) {
        _ocupaciones = [..._ocupaciones, ...result.ocupaciones];
      } else {
        _ocupaciones = result.ocupaciones;
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
        ocupacionesMessenger,
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
    _cargarOcupaciones(page: 1);
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
              _cargarOcupaciones(page: 1);
            },
            child: const Text('Quitar filtros'),
          ),
        ],
      ),
    );
  }

  String _validarRequerido(String? value, String alias) {
    return validateData(context, value, alias, required: true);
  }

  Future<void> _abrirFormulario({Ocupacion? ocupacion}) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: ocupacion?.nombre ?? '');
    final descripcionController = TextEditingController(
      text: ocupacion?.descripcion ?? '',
    );
    final gradoController = TextEditingController(text: ocupacion?.grado ?? '');

    const gradosSugeridos = <String>[
      'Auxiliar de enfermería',
      'Licenciatura en enfermería',
      'Técnico en laboratorio clínico',
      'Tecnólogo en imagenología',
      'Médico general',
      'Médico especialista',
      'Residente de medicina',
      'Interno de medicina',
      'Odontología general',
      'Fisioterapia',
      'Terapia ocupacional',
      'Nutrición clínica',
      'Psicología clínica',
      'Farmacia hospitalaria',
      'Bioquímica clínica',
    ];

    String? submitErrorText;
    bool submitting = false;

    await showModalBottomSheet<void>(
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
            return PopScope(
              canPop: !submitting,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * .9,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      child: AbsorbPointer(
                        absorbing: submitting,
                        child: StepFormDialogLayout(
                          title: ocupacion == null
                              ? 'Nueva ocupación'
                              : 'Editar ocupación',
                          totalSteps: 1,
                          currentStep: 0,
                          submitErrorText: submitErrorText,
                          isSubmitting: submitting,
                          onClose: submitting
                              ? null
                              : () => Navigator.pop(context),
                          nextLabel: ocupacion == null ? 'Crear' : 'Guardar',
                          stepContent: Column(
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
                                lines: 3,
                              ),
                              const SizedBox(height: 12),
                              CustomTextInput(
                                title: 'Grado (opcional)',
                                controller: gradoController,
                                hintText: 'Ej: Médico especialista',
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Sugeridos',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: gradosSugeridos
                                    .map(
                                      (grado) => ActionChip(
                                        label: Text(grado),
                                        onPressed: () {
                                          setStateDialog(() {
                                            gradoController.text = grado;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                          onNext: () async {
                            final navigator = Navigator.of(context);
                            final isValid = validateForm(formKey);
                            if (!isValid) return;

                            final payload = {
                              'nombre': nombreController.text.trim(),
                              'descripcion': descripcionController.text.trim(),
                              if (gradoController.text.trim().isNotEmpty)
                                'grado': gradoController.text.trim(),
                            };

                            setStateDialog(() {
                              submitting = true;
                              submitErrorText = null;
                            });

                            final response = ocupacion == null
                                ? await _service.crearOcupacion(payload)
                                : await _service.actualizarOcupacion(
                                    ocupacion.id,
                                    payload,
                                  );

                            if (!context.mounted) return;

                            if (response.status == StatusNetwork.connected) {
                              navigator.pop();
                              showSnackBar(
                                ocupacionesMessenger,
                                response.message,
                                state: StatusSnackBar.success,
                                colorText: _theme.white,
                              );
                              _cargarOcupaciones();
                              return;
                            }

                            setStateDialog(() {
                              submitting = false;
                              submitErrorText = response.message;
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
    );
  }


  String _textoGrado(String? grado) {
    final value = (grado ?? '').trim();
    return value.isEmpty ? '-' : value;
  }

  Future<void> _cambiarEstado(Ocupacion ocupacion) async {
    final response = await _service.cambiarEstadoOcupacion(ocupacion.id);

    if (!mounted) return;
    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        ocupacionesMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarOcupaciones();
    } else {
      showSnackBar(
        ocupacionesMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    final isNarrowHeader = MediaQuery.of(context).size.width < 560;
    return ScaffoldMessenger(
      key: ocupacionesMessenger,
      child: TemplatePage(
        showEnvironmentBanner: false,
        page: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
            titulo: 'Ocupaciones',
            subtitulo: 'Administra las ocupaciones médicas disponibles.',
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
                    titulo: 'Gestión de ocupaciones',
                    descripcion:
                        'Consulta, filtra y administra las ocupaciones médicas.',
                    acciones: [
                      IconButton(
                        onPressed: _cargarOcupaciones,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                    columnas: [
                      CriterioOrdenType(nombre: 'Nombre'),
                      CriterioOrdenType(nombre: 'Descripción'),
                      CriterioOrdenType(nombre: 'Grado'),
                      CriterioOrdenType(nombre: 'Servicios'),
                      CriterioOrdenType(nombre: 'Estado'),
                      CriterioOrdenType(nombre: 'Acciones'),
                    ],
                    contenidoTabla: _ocupaciones
                        .map(
                          (ocupacion) => [
                            Text(ocupacion.nombre),
                            Text(ocupacion.descripcion ?? '-'),
                            Text(_textoGrado(ocupacion.grado)),
                            Text('${ocupacion.estudios.length} asociados'),
                            TrayStatusBadge(
                              status: ocupacion.estado,
                              activeColor: _theme.success,
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _abrirFormulario(ocupacion: ocupacion),
                                ),
                                IconButton(
                                  tooltip:
                                      ocupacion.estado.toUpperCase() ==
                                              'ACTIVO'
                                          ? 'Desactivar'
                                          : 'Activar',
                                  icon: Icon(
                                    ocupacion.estado.toUpperCase() ==
                                            'ACTIVO'
                                        ? Icons.toggle_off
                                        : Icons.toggle_on,
                                    color: _theme.primary,
                                  ),
                                  onPressed: () => _cambiarEstado(ocupacion),
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
    final inicio = _ocupaciones.isEmpty ? 0 : ((_page - 1) * _limit) + 1;
    final fin = (_page - 1) * _limit + _ocupaciones.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mostrando $inicio - $fin de $_total ocupaciones'),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1 && !_loading
                    ? () => _cargarOcupaciones(page: _page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page'),
              IconButton(
                onPressed: (_page * _limit) < _total && !_loading
                    ? () => _cargarOcupaciones(page: _page + 1)
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
    if (_ocupaciones.isEmpty) {
      return Center(
        child: Text(
          'No hay ocupaciones registradas.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: _ocupaciones.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ocupacion = _ocupaciones[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _mostrarDetalleOcupacion(ocupacion),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.work_outline, size: 18),
                    title: Text(
                      ocupacion.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Servicios: ${ocupacion.estudios.length}',
                    ),
                    trailing: TrayStatusBadge(
                      status: ocupacion.estado,
                      activeColor: _theme.success,
                    ),
                  ),
                if ((ocupacion.descripcion ?? '').isNotEmpty) ...[
                  Text(
                    ocupacion.descripcion ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Grado: ${_textoGrado(ocupacion.grado)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                if (_loadingMore && index == _ocupaciones.length - 1) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDetalleOcupacion(Ocupacion ocupacion) {
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
                        'Detalle de ocupacion',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(ocupacion.nombre,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TrayStatusBadge(
                  status: ocupacion.estado,
                  activeColor: _theme.success,
                ),
                const SizedBox(height: 8),
                if ((ocupacion.descripcion ?? '').isNotEmpty)
                  Text(ocupacion.descripcion!),
                const SizedBox(height: 8),
                Text('Grado: ${_textoGrado(ocupacion.grado)}'),
                Text('Servicios asociados: ${ocupacion.estudios.length}'),
                const SizedBox(height: 14),
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
                          _abrirFormulario(ocupacion: ocupacion);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _cambiarEstado(ocupacion);
                        },
                        icon: Icon(
                          ocupacion.estado.toUpperCase() == 'ACTIVO'
                              ? Icons.toggle_off
                              : Icons.toggle_on,
                        ),
                        label: Text(
                          ocupacion.estado.toUpperCase() == 'ACTIVO'
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
