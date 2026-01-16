import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/form_controller.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/extensions/colores_extension.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/especialidades/especialidades_service.dart';

final GlobalKey<ScaffoldMessengerState> especialidadesMessenger =
    GlobalKey<ScaffoldMessengerState>();

class EspecialidadesPage extends StatefulWidget {
  const EspecialidadesPage({super.key});

  @override
  State<EspecialidadesPage> createState() => _EspecialidadesPageState();
}

class _EspecialidadesPageState extends State<EspecialidadesPage>
    with FormController {
  final _theme = ThemeController.instance;
  late final EspecialidadesService _service;

  List<Especialidad> _especialidades = [];
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
    _service = EspecialidadesService(context);
    _cargarEspecialidades();
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
    if (current >= maxScroll - 200 && _especialidades.length < _total) {
      _cargarEspecialidades(page: _page + 1, append: true);
    }
  }

  Future<void> _cargarEspecialidades({int? page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    final result = await _service.obtenerEspecialidades(
      page: page ?? _page,
      limit: _limit,
      filtro: _filtro,
    );

    setState(() {
      if (append) {
        _especialidades = [..._especialidades, ...result.especialidades];
      } else {
        _especialidades = result.especialidades;
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
        especialidadesMessenger,
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
    _cargarEspecialidades(page: 1);
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
              _cargarEspecialidades(page: 1);
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

  String _normalizarColor(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('#')) return trimmed;
    return '#$trimmed';
  }

  String _colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }

  Future<void> _abrirFormulario({Especialidad? especialidad}) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: especialidad?.nombre ?? '',
    );
    final descripcionController = TextEditingController(
      text: especialidad?.descripcion ?? '',
    );
    Color selectedColor = HexColor.fromHex(
      _normalizarColor(especialidad?.colorHex ?? '#0ea5e9'),
    );
    HSVColor hsvColor = HSVColor.fromColor(selectedColor);
    final baseColors = <String>[
      '#0ea5e9',
      '#22c55e',
      '#f59e0b',
      '#ef4444',
      '#8b5cf6',
      '#1f2937',
    ];

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
                    especialidad == null
                        ? 'Nueva especialidad'
                        : 'Editar especialidad',
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
                    lines: 3,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Color (rueda)',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setColorState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selectedColor,
                                  border: Border.all(
                                    color: _theme.grey.withValues(alpha: .4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _colorToHex(selectedColor),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tono',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Slider(
                            min: 0,
                            max: 360,
                            value: hsvColor.hue,
                            onChanged: (value) {
                              setColorState(() {
                                hsvColor = hsvColor.withHue(value);
                                selectedColor = hsvColor.toColor();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Colores básicos',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: baseColors.map((colorHex) {
                              return GestureDetector(
                                onTap: () {
                                  setColorState(() {
                                    selectedColor =
                                        HexColor.fromHex(colorHex);
                                    hsvColor =
                                        HSVColor.fromColor(selectedColor);
                                  });
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: HexColor.fromHex(colorHex),
                                    border: Border.all(
                                      color: _theme.grey.withValues(
                                        alpha: .4,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          Text(
                            'Saturación',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Slider(
                            min: 0,
                            max: 1,
                            value: hsvColor.saturation,
                            onChanged: (value) {
                              setColorState(() {
                                hsvColor = hsvColor.withSaturation(value);
                                selectedColor = hsvColor.toColor();
                              });
                            },
                          ),
                          Text(
                            'Brillo',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Slider(
                            min: 0,
                            max: 1,
                            value: hsvColor.value,
                            onChanged: (value) {
                              setColorState(() {
                                hsvColor = hsvColor.withValue(value);
                                selectedColor = hsvColor.toColor();
                              });
                            },
                          ),
                        ],
                      );
                    },
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
                          title: especialidad == null ? 'Crear' : 'Guardar',
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
      'colorHex': _colorToHex(selectedColor),
    };

    final response = especialidad == null
        ? await _service.crearEspecialidad(payload)
        : await _service.actualizarEspecialidad(especialidad.id, payload);

    if (!mounted) return;

    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        especialidadesMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarEspecialidades();
    } else {
      showSnackBar(
        especialidadesMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _confirmarEliminacion(Especialidad especialidad) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar especialidad'),
          content: Text(
            '¿Deseas eliminar la especialidad "${especialidad.nombre}"?',
          ),
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

    final response = await _service.eliminarEspecialidad(especialidad.id);

    if (!mounted) return;
    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        especialidadesMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarEspecialidades();
    } else {
      showSnackBar(
        especialidadesMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _cambiarEstado(Especialidad especialidad) async {
    final response = await _service.cambiarEstadoEspecialidad(especialidad.id);

    if (!mounted) return;
    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        especialidadesMessenger,
        response.message,
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarEspecialidades();
    } else {
      showSnackBar(
        especialidadesMessenger,
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
      key: especialidadesMessenger,
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
                        'Especialidades',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Administra las especialidades médicas disponibles.',
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
                              'Especialidades',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Administra las especialidades médicas disponibles.',
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
                    titulo: 'Gestión de especialidades',
                    descripcion:
                        'Consulta, filtra y administra las especialidades médicas.',
                    acciones: [
                      IconButton(
                        onPressed: _cargarEspecialidades,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                    columnas: [
                      CriterioOrdenType(nombre: 'Nombre'),
                      CriterioOrdenType(nombre: 'Descripción'),
                      CriterioOrdenType(nombre: 'Color'),
                      CriterioOrdenType(nombre: 'Estudios'),
                      CriterioOrdenType(nombre: 'Estado'),
                      CriterioOrdenType(nombre: 'Acciones'),
                    ],
                    contenidoTabla: _especialidades
                        .map(
                          (especialidad) => [
                            Text(especialidad.nombre),
                            Text(especialidad.descripcion ?? '-'),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: HexColor.fromHex(
                                      especialidad.colorHex,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(especialidad.colorHex),
                              ],
                            ),
                            Text('${especialidad.estudios.length} asociados'),
                            Chip(
                              label: Text(especialidad.estado.toUpperCase()),
                              backgroundColor: (especialidad.estado)
                                          .toUpperCase() ==
                                      'ACTIVO'
                                  ? _theme.success.withValues(alpha: .15)
                                  : _theme.error.withValues(alpha: .15),
                              labelStyle: TextStyle(
                                color: (especialidad.estado).toUpperCase() ==
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
                                  onPressed: () => _abrirFormulario(
                                    especialidad: especialidad,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      _confirmarEliminacion(especialidad),
                                ),
                                IconButton(
                                  tooltip: especialidad.estado.toUpperCase() ==
                                          'ACTIVO'
                                      ? 'Desactivar'
                                      : 'Activar',
                                  icon: Icon(
                                    especialidad.estado.toUpperCase() ==
                                            'ACTIVO'
                                        ? Icons.toggle_off
                                        : Icons.toggle_on,
                                    color: _theme.primary,
                                  ),
                                  onPressed: () => _cambiarEstado(especialidad),
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
    final inicio = _especialidades.isEmpty ? 0 : ((_page - 1) * _limit) + 1;
    final fin = (_page - 1) * _limit + _especialidades.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mostrando $inicio - $fin de $_total especialidades'),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1 && !_loading
                    ? () => _cargarEspecialidades(page: _page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page'),
              IconButton(
                onPressed: (_page * _limit) < _total && !_loading
                    ? () => _cargarEspecialidades(page: _page + 1)
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
    if (_especialidades.isEmpty) {
      return Center(
        child: Text(
          'No hay especialidades registradas.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: _especialidades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final especialidad = _especialidades[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: HexColor.fromHex(especialidad.colorHex),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        especialidad.nombre,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Chip(
                      label: Text(especialidad.estado.toUpperCase()),
                      backgroundColor:
                          (especialidad.estado).toUpperCase() == 'ACTIVO'
                              ? _theme.success.withValues(alpha: .15)
                              : _theme.error.withValues(alpha: .15),
                      labelStyle: TextStyle(
                        color: (especialidad.estado).toUpperCase() == 'ACTIVO'
                            ? _theme.success
                            : _theme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if ((especialidad.descripcion ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(especialidad.descripcion ?? '-'),
                ],
                const SizedBox(height: 8),
                Text(
                  'Color: ${especialidad.colorHex}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Estudios asociados: ${especialidad.estudios.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _abrirFormulario(especialidad: especialidad),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _confirmarEliminacion(especialidad),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                    TextButton.icon(
                      onPressed: () => _cambiarEstado(especialidad),
                      icon: Icon(
                        especialidad.estado.toUpperCase() == 'ACTIVO'
                            ? Icons.toggle_off
                            : Icons.toggle_on,
                      ),
                      label: Text(
                        especialidad.estado.toUpperCase() == 'ACTIVO'
                            ? 'Desactivar'
                            : 'Activar',
                      ),
                    ),
                  ],
                ),
                if (_loadingMore && index == _especialidades.length - 1) ...[
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
