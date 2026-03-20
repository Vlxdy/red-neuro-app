import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/models/lugar.dart';
import 'package:red_neuro_app/src/models/personal_medico.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';

typedef CatalogoLoader<T> = Future<CatalogoPageResult<T>> Function({
  int page,
  int limit,
  String? filtro,
});

class CitasMedicoSelectorModalWidget extends StatelessWidget {
  final CatalogoLoader<PersonalMedico> cargarMedicos;
  final double maxHeightFactor;

  const CitasMedicoSelectorModalWidget({
    super.key,
    required this.cargarMedicos,
    this.maxHeightFactor = .9,
  });

  @override
  Widget build(BuildContext context) {
    return _CitasCatalogoSelectorModal<PersonalMedico>(
      titulo: 'Selecciona personal asignado',
      buscarLabel: 'Buscar personal asignado',
      cargarCatalogo: cargarMedicos,
      itemTitleBuilder: (item) => item.nombreCompleto,
      itemSubtitleBuilder: (item) =>
          (item.nroDocumento?.isNotEmpty ?? false)
          ? 'Documento: ${item.nroDocumento}'
          : null,
      maxHeightFactor: maxHeightFactor,
    );
  }
}

class CitasLugarSelectorModalWidget extends StatelessWidget {
  final CatalogoLoader<Lugar> cargarLugares;
  final double maxHeightFactor;

  const CitasLugarSelectorModalWidget({
    super.key,
    required this.cargarLugares,
    this.maxHeightFactor = .85,
  });

  @override
  Widget build(BuildContext context) {
    return _CitasCatalogoSelectorModal<Lugar>(
      titulo: 'Selecciona lugar',
      buscarLabel: 'Buscar lugar',
      cargarCatalogo: cargarLugares,
      itemTitleBuilder: (item) => item.nombre,
      itemSubtitleBuilder: (item) {
        if (item.direccion.trim().isEmpty) return null;
        return item.direccion;
      },
      maxHeightFactor: maxHeightFactor,
    );
  }
}

class _CitasCatalogoSelectorModal<T> extends StatefulWidget {
  final String titulo;
  final String buscarLabel;
  final CatalogoLoader<T> cargarCatalogo;
  final String Function(T item) itemTitleBuilder;
  final String? Function(T item) itemSubtitleBuilder;
  final double maxHeightFactor;

  const _CitasCatalogoSelectorModal({
    required this.titulo,
    required this.buscarLabel,
    required this.cargarCatalogo,
    required this.itemTitleBuilder,
    required this.itemSubtitleBuilder,
    required this.maxHeightFactor,
  });

  @override
  State<_CitasCatalogoSelectorModal<T>> createState() =>
      _CitasCatalogoSelectorModalState<T>();
}

class _CitasCatalogoSelectorModalState<T>
    extends State<_CitasCatalogoSelectorModal<T>> {
  final _searchController = TextEditingController();
  final List<T> _items = [];
  Timer? _debounce;

  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    unawaited(_cargar(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar({required bool reset}) async {
    if (_loading) return;
    setState(() => _loading = true);

    if (reset) {
      _page = 1;
      _hasMore = true;
      _items.clear();
    }

    final result = await widget.cargarCatalogo(
      page: _page,
      limit: 10,
      filtro: _filtro,
    );

    if (!mounted) return;
    if (result.items.isNotEmpty) {
      _items.addAll(result.items);
    }

    _hasMore = _items.length < result.total;
    _page += 1;

    setState(() => _loading = false);
  }

  void _onSearchChanged(String value) {
    _filtro = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_cargar(reset: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: widget.maxHeightFactor,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  widget.titulo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: widget.buscarLabel,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildList(context)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Sin resultados'));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length && _hasMore) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: _loading ? null : () => _cargar(reset: false),
                icon: const Icon(Icons.expand_more),
                label: const Text('Cargar más'),
              ),
            ),
          );
        }

        final option = _items[index];
        final subtitle = widget.itemSubtitleBuilder(option);
        return ListTile(
          title: Text(widget.itemTitleBuilder(option)),
          subtitle: subtitle != null ? Text(subtitle) : null,
          onTap: () => Navigator.pop(context, option),
        );
      },
    );
  }
}
