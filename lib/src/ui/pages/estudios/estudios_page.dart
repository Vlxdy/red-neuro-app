import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/extensions/colores_extension.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
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

  List<Estudio> _estudios = [];
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
    _cargarEstudios();
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
    if (current >= maxScroll - 200 && _estudios.length < _total) {
      _cargarEstudios(page: _page + 1, append: true);
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

  Future<void> _cargarEstudios({int? page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    final result = await _service.obtenerEstudios(
      page: page ?? _page,
      limit: _limit,
      filtro: _filtro,
    );

    setState(() {
      if (append) {
        _estudios = [..._estudios, ...result.estudios];
      } else {
        _estudios = result.estudios;
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
    _cargarEstudios(page: 1);
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
              _cargarEstudios(page: 1);
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

  Future<void> _abrirFormulario({Estudio? estudio}) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: estudio?.nombre ?? '');
    final descripcionController = TextEditingController(
      text: estudio?.descripcion ?? '',
    );
    final duracionController = TextEditingController(
      text: estudio?.duracionMinutos.toString() ?? '30',
    );

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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    estudio == null ? 'Nuevo estudio' : 'Editar estudio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
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
                          title: estudio == null ? 'Crear' : 'Guardar',
                          onTap: () =>
                              Navigator.of(context).pop(validateForm(formKey)),
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

    if (result != true) {
      return;
    }

    final payload = {
      'nombre': nombreController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'duracionMinutos': int.parse(duracionController.text.trim()),
    };

    final response = estudio == null
        ? await _service.crearEstudio(payload)
        : await _service.actualizarEstudio(estudio.id, payload);

    if (!mounted) return;

    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarEstudios();
    } else {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _confirmarEliminacion(Estudio estudio) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar estudio'),
          content: Text('¿Deseas eliminar el estudio "${estudio.nombre}"?'),
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

    final response = await _service.eliminarEstudio(estudio.id);

    if (!mounted) return;
    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarEstudios();
    } else {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _cambiarEstado(Estudio estudio) async {
    final response = await _service.cambiarEstadoEstudio(estudio.id);

    if (!mounted) return;
    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarEstudios();
    } else {
      showSnackBar(
        estudiosMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _abrirAsignacion(Estudio estudio) async {
    if (_especialidadesDisponibles.isEmpty && !_loadingEspecialidades) {
      await _cargarEspecialidadesDisponibles();
      if (!mounted) return;
    }

    final asignadasIds = estudio.especialidades
        .map((especialidad) => especialidad.id)
        .toSet();
    final disponibles = _especialidadesDisponibles
        .where((especialidad) => !asignadasIds.contains(especialidad.id))
        .toList();
    final seleccionadas = <String>{};

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Asignar especialidades a "${estudio.nombre}"'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (estudio.especialidades.isNotEmpty) ...[
                      Text(
                        'Especialidades actuales',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: estudio.especialidades
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
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Selecciona nuevas especialidades',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (disponibles.isEmpty)
                      Text(
                        'No hay especialidades disponibles para asignar.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: disponibles.length,
                          itemBuilder: (context, index) {
                            final especialidad = disponibles[index];
                            final selected = seleccionadas.contains(
                              especialidad.id,
                            );
                            return CheckboxListTile(
                              value: selected,
                              title: Text(especialidad.nombre),
                              subtitle: Text(especialidad.descripcion ?? '-'),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    seleccionadas.add(especialidad.id);
                                  } else {
                                    seleccionadas.remove(especialidad.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: seleccionadas.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: const Text('Asignar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || seleccionadas.isEmpty) {
      return;
    }

    bool allSuccess = true;
    String lastMessage = '';

    for (final especialidadId in seleccionadas) {
      final response = await _service.asignarEspecialidad(
        estudioId: estudio.id,
        especialidadId: especialidadId,
      );
      lastMessage = response.message;
      if (response.status != StatusNetwork.connected) {
        allSuccess = false;
        break;
      }
    }

    if (!mounted) return;
    showSnackBar(
      estudiosMessenger,
      lastMessage.isNotEmpty
          ? lastMessage
          : allSuccess
          ? 'Especialidades asignadas.'
          : 'No se pudieron asignar las especialidades.',
      state: allSuccess ? StatusSnackBar.success : StatusSnackBar.error,
      colorText: _theme.white,
    );
    if (allSuccess) {
      _cargarEstudios();
    }
  }

  Widget _buildEspecialidadesCell(Estudio estudio) {
    if (estudio.especialidades.isEmpty) {
      return const Text('-');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: estudio.especialidades
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
        page: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNarrowHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estudios',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Administra estudios y asigna especialidades médicas.',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: _abrirFiltros,
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filtros'),
                          ),
                          TextButton.icon(
                            onPressed: _cargarEspecialidadesDisponibles,
                            icon: const Icon(Icons.sync),
                            label: const Text('Actualizar'),
                          ),
                          TextButton.icon(
                            onPressed: () => _abrirFormulario(),
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo'),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estudios',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Administra estudios y asigna especialidades médicas.',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
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
                            onPressed: _cargarEspecialidadesDisponibles,
                            icon: const Icon(Icons.sync),
                            label: const Text('Actualizar'),
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
                _buildFilterSummary(),
                const SizedBox(height: 12),
                if (!isCompact)
                  CustomDesktopDataTable(
                    titulo: 'Gestión de estudios',
                    descripcion: 'Consulta y administra estudios clínicos.',
                    acciones: [
                      IconButton(
                        onPressed: _cargarEstudios,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                    columnas: [
                      CriterioOrdenType(nombre: 'Nombre'),
                      CriterioOrdenType(nombre: 'Descripción'),
                      CriterioOrdenType(nombre: 'Duración'),
                      CriterioOrdenType(nombre: 'Especialidades'),
                      CriterioOrdenType(nombre: 'Estado'),
                      CriterioOrdenType(nombre: 'Acciones'),
                    ],
                    contenidoTabla: _estudios
                        .map(
                          (estudio) => [
                            Text(estudio.nombre),
                            Text(estudio.descripcion),
                            Text('${estudio.duracionMinutos} min'),
                            _buildEspecialidadesCell(estudio),
                            Chip(
                              label: Text(estudio.estado.toUpperCase()),
                              backgroundColor:
                                  (estudio.estado).toUpperCase() == 'ACTIVO'
                                  ? _theme.success.withValues(alpha: .15)
                                  : _theme.error.withValues(alpha: .15),
                              labelStyle: TextStyle(
                                color:
                                    (estudio.estado).toUpperCase() == 'ACTIVO'
                                    ? _theme.success
                                    : _theme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _abrirFormulario(estudio: estudio),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      _confirmarEliminacion(estudio),
                                ),
                                IconButton(
                                  tooltip:
                                      estudio.estado.toUpperCase() == 'ACTIVO'
                                      ? 'Desactivar'
                                      : 'Activar',
                                  icon: Icon(
                                    estudio.estado.toUpperCase() == 'ACTIVO'
                                        ? Icons.toggle_off
                                        : Icons.toggle_on,
                                    color: _theme.primary,
                                  ),
                                  onPressed: () => _cambiarEstado(estudio),
                                ),
                                IconButton(
                                  tooltip: 'Asignar especialidades',
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _abrirAsignacion(estudio),
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

  Widget _buildPagination() {
    final inicio = _estudios.isEmpty ? 0 : ((_page - 1) * _limit) + 1;
    final fin = (_page - 1) * _limit + _estudios.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mostrando $inicio - $fin de $_total estudios'),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1 && !_loading
                    ? () => _cargarEstudios(page: _page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page'),
              IconButton(
                onPressed: (_page * _limit) < _total && !_loading
                    ? () => _cargarEstudios(page: _page + 1)
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
    if (_estudios.isEmpty) {
      return Center(
        child: Text(
          'No hay estudios registrados.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: _estudios.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final estudio = _estudios[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        estudio.nombre,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Chip(
                      label: Text(estudio.estado.toUpperCase()),
                      backgroundColor:
                          (estudio.estado).toUpperCase() == 'ACTIVO'
                          ? _theme.success.withValues(alpha: .15)
                          : _theme.error.withValues(alpha: .15),
                      labelStyle: TextStyle(
                        color: (estudio.estado).toUpperCase() == 'ACTIVO'
                            ? _theme.success
                            : _theme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(estudio.descripcion),
                const SizedBox(height: 8),
                Text(
                  'Duración: ${estudio.duracionMinutos} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Especialidades',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                if (estudio.especialidades.isEmpty)
                  Text(
                    'Sin especialidades asignadas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: estudio.especialidades
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
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _abrirFormulario(estudio: estudio),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmarEliminacion(estudio),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                    TextButton.icon(
                      onPressed: () => _cambiarEstado(estudio),
                      icon: Icon(
                        estudio.estado.toUpperCase() == 'ACTIVO'
                            ? Icons.toggle_off
                            : Icons.toggle_on,
                      ),
                      label: Text(
                        estudio.estado.toUpperCase() == 'ACTIVO'
                            ? 'Desactivar'
                            : 'Activar',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _abrirAsignacion(estudio),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Asignar'),
                    ),
                  ],
                ),
                if (_loadingMore && index == _estudios.length - 1) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
