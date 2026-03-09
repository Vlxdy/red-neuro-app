import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/lugar.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/lugares/lugares_service.dart';

final GlobalKey<ScaffoldMessengerState> lugaresMessenger =
    GlobalKey<ScaffoldMessengerState>();

class LugaresPage extends StatefulWidget {
  const LugaresPage({super.key});

  @override
  State<LugaresPage> createState() => _LugaresPageState();
}

class _LugaresPageState extends State<LugaresPage> {
  final _theme = ThemeController.instance;
  late final LugaresService _service;

  final ScrollController _scrollController = ScrollController();

  List<Lugar> _lugares = [];
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  String _filtro = '';
  bool _hasMore = true;

  static const _tiposLugar = [
    'HOSPITAL',
    'CLINICA',
    'CENTRO_SALUD',
    'DOMICILIO',
    'OTRO',
  ];

  String? _validarTextoRequerido(
    String? value, {
    required String campo,
    required int maxLength,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'El campo $campo es obligatorio';
    }
    if (text.length > maxLength) {
      return 'El campo $campo permite máximo $maxLength caracteres';
    }
    return null;
  }

  String? _validarTipoLugar(String? value) {
    if (value == null || !_tiposLugar.contains(value)) {
      return 'Selecciona un tipo de lugar válido';
    }
    return null;
  }

  String? _validarTextoOpcional(String? value, {required int maxLength}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > maxLength) {
      return 'Máximo $maxLength caracteres';
    }
    return null;
  }

  Widget _requiredLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: ' *', style: TextStyle(color: _theme.error)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _service = LugaresService(context);
    _cargarLugares();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) {
      return;
    }
    final current = _scrollController.position.pixels;
    final max = _scrollController.position.maxScrollExtent;
    if (current >= max - 200) {
      _cargarLugares(page: _page + 1, append: true);
    }
  }

  Future<void> _cargarLugares({int? page, bool append = false}) async {
    final requestedPage = page ?? 1;
    if (append && !_hasMore) return;

    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _hasMore = true;
      });
    }

    final result = await _service.obtenerLugares(
      page: requestedPage,
      limit: _limit,
      filtro: _filtro,
    );

    if (!mounted) return;

    final nextData = append ? [..._lugares, ...result.lugares] : result.lugares;
    final hasMore = nextData.length < result.total;

    setState(() {
      _lugares = nextData;
      _page = requestedPage;
      _limit = result.limit;
      _total = result.total;
      _hasMore = hasMore;
      _loading = false;
      _loadingMore = false;
    });

    if (result.status != StatusNetwork.connected) {
      showSnackBar(
        lugaresMessenger,
        result.message,
        state: StatusSnackBar.error,
        colorText: _theme.white,
      );
    }
  }

  Future<void> _abrirFiltros() async {
    final filtroController = TextEditingController(text: _filtro);
    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: filtroController,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre, sigla o dirección',
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
        );
      },
    );

    if (result != true) return;
    setState(() {
      _filtro = filtroController.text.trim();
    });
    _cargarLugares(page: 1);
  }

  Future<void> _abrirFormulario({Lugar? lugar}) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: lugar?.nombre ?? '');
    final siglaController = TextEditingController(text: lugar?.sigla ?? '');
    final direccionController = TextEditingController(
      text: lugar?.direccion ?? '',
    );
    String tipo = lugar?.tipo.isNotEmpty == true ? lugar!.tipo : _tiposLugar[0];
    String estado = lugar?.estado.isNotEmpty == true ? lugar!.estado : 'ACTIVO';
    bool loading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lugar == null ? 'Nuevo lugar' : 'Editar lugar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(label: _requiredLabel('Nombre')),
                        maxLength: 120,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(120),
                        ],
                        validator: (value) => _validarTextoRequerido(
                          value,
                          campo: 'nombre',
                          maxLength: 120,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: siglaController,
                        decoration: const InputDecoration(labelText: 'Sigla (opcional)'),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 20,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(20),
                        ],
                        validator: (value) => _validarTextoOpcional(
                          value,
                          maxLength: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: direccionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Dirección (opcional)',
                        ),
                        maxLength: 255,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(255),
                        ],
                        validator: (value) => _validarTextoOpcional(
                          value,
                          maxLength: 255,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: tipo,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(label: _requiredLabel('Tipo')),
                        items: _tiposLugar
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.replaceAll('_', ' ')),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setStateDialog(() => tipo = value);
                        },
                        validator: _validarTipoLugar,
                      ),
                      if (lugar != null) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: estado,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ACTIVO',
                              child: Text('ACTIVO'),
                            ),
                            DropdownMenuItem(
                              value: 'INACTIVO',
                              child: Text('INACTIVO'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setStateDialog(() => estado = value);
                          },
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
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SimpleButton(
                              title: loading ? 'Guardando...' : 'Guardar',
                              disabled: loading,
                              onTap: () async {
                                if (!formKey.currentState!.validate()) return;
                                setStateDialog(() => loading = true);

                                final body = {
                                  'nombre': nombreController.text.trim(),
                                  if (siglaController.text.trim().isNotEmpty)
                                    'sigla': siglaController.text.trim().toUpperCase(),
                                  if (direccionController.text.trim().isNotEmpty)
                                    'direccion': direccionController.text.trim(),
                                  'tipo': tipo,
                                  if (lugar != null) 'estado': estado,
                                };

                                final response = lugar == null
                                    ? await _service.crearLugar(body)
                                    : await _service.actualizarLugar(
                                        lugar.id,
                                        body,
                                      );

                                if (!mounted) return;

                                if (response.status == StatusNetwork.connected) {
                                  Navigator.of(context).pop();
                                  showSnackBar(
                                    lugaresMessenger,
                                    lugar == null
                                        ? 'Lugar creado correctamente'
                                        : 'Lugar actualizado correctamente',
                                    state: StatusSnackBar.success,
                                    colorText: _theme.white,
                                  );
                                  _cargarLugares(page: 1);
                                } else {
                                  setStateDialog(() => loading = false);
                                  showSnackBar(
                                    lugaresMessenger,
                                    response.message,
                                    state: StatusSnackBar.error,
                                    colorText: _theme.white,
                                  );
                                }
                              },
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
  }

  Future<void> _cambiarEstado(Lugar lugar) async {
    final response = await _service.cambiarEstadoLugar(lugar.id);
    if (!mounted) return;
    if (response.status == StatusNetwork.connected) {
      showSnackBar(
        lugaresMessenger,
        'Estado actualizado correctamente',
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
      _cargarLugares(page: 1);
      return;
    }

    showSnackBar(
      lugaresMessenger,
      response.message,
      state: StatusSnackBar.error,
      colorText: _theme.white,
    );
  }

  Widget _estadoBadge(String estado) {
    final isActivo = estado.toUpperCase() == 'ACTIVO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isActivo ? _theme.success : _theme.error).withValues(alpha: .2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isActivo ? _theme.success : _theme.error,
        ),
      ),
    );
  }


  Widget _buildFiltroActivo() {
    if (_filtro.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _theme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtro aplicado: $_filtro',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _filtro = '');
              _cargarLugares(page: 1, append: false);
            },
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLugarCard(Lugar lugar) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lugar.nombre.isEmpty ? '-' : lugar.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _estadoBadge(lugar.estado),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Tipo: ${lugar.tipo.replaceAll('_', ' ')}')),
                if (lugar.sigla.trim().isNotEmpty)
                  Chip(label: Text('Sigla: ${lugar.sigla}')),
              ],
            ),
            if (lugar.direccion.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(lugar.direccion)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _abrirFormulario(lugar: lugar),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: lugar.estado.toUpperCase() == 'ACTIVO'
                      ? 'Inactivar'
                      : 'Activar',
                  onPressed: () => _cambiarEstado(lugar),
                  icon: Icon(
                    lugar.estado.toUpperCase() == 'ACTIVO'
                        ? Icons.toggle_on
                        : Icons.toggle_off,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePage(
      showEnvironmentBanner: false,
      page: ScaffoldMessenger(
        key: lugaresMessenger,
        child: Scaffold(
          backgroundColor: _theme.transparent,
          appBar: TrayModuleHeader(
            titulo: 'Lugares',
            subtitulo: 'Gestiona instituciones y lugares de atención disponibles.',
            actions: [
              IconButton(
                tooltip: 'Filtrar',
                onPressed: _abrirFiltros,
                icon: Icon(Icons.filter_alt_rounded, color: _theme.white),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  side: BorderSide(
                    color: _theme.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _abrirFormulario(),
            backgroundColor: _theme.primary,
            foregroundColor: _theme.white,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo lugar'),
          ),
          body: RefreshIndicator(
            onRefresh: () => _cargarLugares(page: 1, append: false),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildFiltroActivo(),
                if (_loading && _lugares.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_lugares.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Sin registros')),
                  )
                else
                  ..._lugares.map(_buildLugarCard),
                if (_loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}