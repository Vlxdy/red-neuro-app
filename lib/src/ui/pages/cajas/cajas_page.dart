import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/ui/common/layout/tray_module_header.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/cajas/cajas_service.dart';

final GlobalKey<ScaffoldMessengerState> cajasMessenger =
    GlobalKey<ScaffoldMessengerState>();

class CajasPage extends StatefulWidget {
  const CajasPage({super.key});

  @override
  State<CajasPage> createState() => _CajasPageState();
}

class _CajasPageState extends State<CajasPage> {
  final theme = ThemeController.instance;
  final NumberFormat _money = NumberFormat.currency(
    locale: 'es_BO',
    symbol: 'Bs ',
    decimalDigits: 2,
  );
  final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static const int _limiteMovimientos = 20;
  static const int _limiteCajas = 10;

  late final CajasService _service;

  List<CajaDetalle> _cajas = const [];
  int _totalCajas = 0;
  String? _defaultCajaId;
  String? _selectedCajaId;
  CajaDetalle? _cajaDetalle;
  List<CajaMovimiento> _movimientos = const [];

  int _totalMovimientos = 0;
  int _pagina = 1;
  String? _filtroEstadoPago;

  bool _loading = false;
  bool _loadingMovimientos = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = CajasService(context);
    _loadInicial();
  }

  Future<void> _loadInicial() async {
    setState(() => _loading = true);
    final listado = await _service.listarCajas(pagina: 1, limite: _limiteCajas);

    if (!mounted) return;
    final nextSelected = _resolveCajaInicial(listado.rows, listado.defaultCajaId);
    setState(() {
      _cajas = listado.rows;
      _totalCajas = listado.total;
      _defaultCajaId = listado.defaultCajaId;
      _selectedCajaId = nextSelected;
      _loading = false;
    });

    if (listado.status != StatusNetwork.connected && listado.message.trim().isNotEmpty) {
      _showError(listado.message);
      return;
    }

    if (nextSelected != null && nextSelected.isNotEmpty) {
      await _loadCaja(nextSelected, resetPagination: true);
    }
  }

  String? _resolveCajaInicial(List<CajaDetalle> cajas, String? defaultCajaId) {
    if (cajas.isEmpty) return null;
    if ((defaultCajaId ?? '').isNotEmpty && cajas.any((c) => c.id == defaultCajaId)) {
      return defaultCajaId;
    }
    return cajas.first.id;
  }

  Future<void> _loadCaja(
    String idCaja, {
    required bool resetPagination,
  }) async {
    final paginaSolicitada = resetPagination ? 1 : _pagina;

    setState(() {
      if (resetPagination) {
        _loading = true;
        _movimientos = const [];
      } else {
        _loadingMovimientos = true;
      }
    });

    final detalleFuture = _service.obtenerCaja(idCaja);
    final movimientosFuture = _service.obtenerMovimientos(
      idCaja,
      pagina: paginaSolicitada,
      limite: _limiteMovimientos,
      estadoPago: _filtroEstadoPago,
    );

    final detalle = await detalleFuture;
    final movimientos = await movimientosFuture;

    if (!mounted) return;

    setState(() {
      _loading = false;
      _loadingMovimientos = false;
      _selectedCajaId = idCaja;
      _cajaDetalle = detalle.caja;
      _totalMovimientos = movimientos.total;
      _pagina = paginaSolicitada + 1;
      _movimientos = resetPagination
          ? movimientos.rows
          : [..._movimientos, ...movimientos.rows];
    });

    if (detalle.status != StatusNetwork.connected && detalle.message.trim().isNotEmpty) {
      _showError(detalle.message);
    }
    if (movimientos.status != StatusNetwork.connected && movimientos.message.trim().isNotEmpty) {
      _showError(movimientos.message);
    }
  }

  Future<void> _cambiarCaja(String? idCaja) async {
    if (idCaja == null || idCaja == _selectedCajaId) return;
    await _loadCaja(idCaja, resetPagination: true);
  }

  Future<void> _abrirSelectorCajas() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CajaSelectorBottomSheet(
        service: _service,
        selectedCajaId: _selectedCajaId,
        defaultCajaId: _defaultCajaId,
        initialRows: _cajas,
        initialTotal: _totalCajas,
        limit: _limiteCajas,
      ),
    );

    if (!mounted || selected == null) return;
    await _cambiarCaja(selected);
  }

  Future<void> _aplicarFiltroEstado(String? estadoPago) async {
    setState(() => _filtroEstadoPago = estadoPago);
    final idCaja = _selectedCajaId;
    if (idCaja == null) return;
    await _loadCaja(idCaja, resetPagination: true);
  }

  Future<void> _cargarMasMovimientos() async {
    final idCaja = _selectedCajaId;
    if (idCaja == null || _loadingMovimientos || !_hasMoreMovimientos) return;
    await _loadCaja(idCaja, resetPagination: false);
  }

  bool get _hasMoreMovimientos => _movimientos.length < _totalMovimientos;

  Future<void> _abrirCaja() async {
    final request = await _solicitarMonto(
      titulo: 'Aperturar caja',
      hintText: 'Monto de apertura (opcional)',
      confirmLabel: 'Abrir caja',
    );
    if (!mounted || request == null || !request.confirmed) return;

    await _ejecutarOperacion(
      () => _service.abrirCaja(montoApertura: request.monto),
      successFallbackMessage: 'Caja abierta correctamente.',
    );
  }

  Future<void> _cerrarCaja() async {
    final idCaja = _selectedCajaId;
    if (idCaja == null || idCaja.isEmpty) return;

    final request = await _solicitarMonto(
      titulo: 'Cerrar caja',
      hintText: 'Monto declarado de cierre (opcional)',
      confirmLabel: 'Cerrar caja',
    );
    if (!mounted || request == null || !request.confirmed) return;

    await _ejecutarOperacion(
      () => _service.cerrarCaja(idCaja, montoCierreDeclarado: request.monto),
      successFallbackMessage: 'Caja cerrada correctamente.',
    );
  }

  Future<void> _ejecutarOperacion(
    Future<CajaResponse> Function() request, {
    required String successFallbackMessage,
  }) async {
    setState(() => _submitting = true);
    final response = await request();
    if (!mounted) return;

    setState(() => _submitting = false);

    final isSuccess = response.status == StatusNetwork.connected;
    final message = response.message.trim().isEmpty ? successFallbackMessage : response.message;
    showSnackBar(
      cajasMessenger,
      message,
      state: isSuccess ? StatusSnackBar.success : StatusSnackBar.error,
      colorText: theme.white,
    );

    await _loadInicial();
  }

  Future<_MontoDialogResult?> _solicitarMonto({
    required String titulo,
    required String hintText,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController();
    String? error;

    return showDialog<_MontoDialogResult?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            return AlertDialog(
              title: Text(titulo),
              content: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: hintText,
                  prefixText: 'Bs ',
                  errorText: error,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(const _MontoDialogResult.cancelled()),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw = controller.text.trim();
                    if (raw.isEmpty) {
                      Navigator.of(
                        dialogContext,
                      ).pop(const _MontoDialogResult.confirmed());
                      return;
                    }

                    final parsed = double.tryParse(raw.replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) {
                      setLocalState(() => error = 'Ingrese un monto válido mayor o igual a 0');
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(_MontoDialogResult.confirmed(monto: parsed));
                  },
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showError(String message) {
    if (message.trim().isEmpty) return;
    showSnackBar(
      cajasMessenger,
      message,
      state: StatusSnackBar.error,
      colorText: theme.white,
    );
  }

  Color _chipColorByEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return theme.success;
      case 'PENDIENTE':
        return theme.warning;
      case 'ANULADO':
      case 'REEMPLAZADO':
        return theme.error;
      default:
        return theme.secondary;
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return _dateTime.format(value.toLocal());
  }

  String _formatMonto(double value) => _money.format(value);

  @override
  Widget build(BuildContext context) {
    final caja = _cajaDetalle;
    final abierta = caja?.estaAbierta ?? false;

    return TemplatePage(
      showEnvironmentBanner: false,
      cargando: _submitting,
      page: ScaffoldMessenger(
        key: cajasMessenger,
        child: Scaffold(
          backgroundColor: theme.transparent,
          appBar: const TrayModuleHeader(
            titulo: 'Cajas',
            subtitulo: 'Bandeja unificada de cajas, detalle y movimientos paginados.',
          ),
          body: RefreshIndicator(
            onRefresh: _loadInicial,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSelector(),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    abierta ? Icons.lock_open_rounded : Icons.lock_rounded,
                                    color: abierta ? theme.success : theme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    caja == null ? 'Sin caja seleccionada' : 'Caja ${caja.estado}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: theme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(label: 'ID caja', value: caja?.id ?? '-'),
                              _InfoRow(label: 'Fecha apertura', value: _formatDateTime(caja?.fechaApertura)),
                              _InfoRow(label: 'Fecha cierre', value: _formatDateTime(caja?.fechaCierre)),
                              _InfoRow(label: 'Monto apertura', value: _formatMonto(caja?.montoApertura ?? 0)),
                              _InfoRow(label: 'Monto recaudado', value: _formatMonto(caja?.montoRecaudado ?? 0)),
                              _InfoRow(
                                label: 'Monto cierre declarado',
                                value: caja?.montoCierreDeclarado == null
                                    ? '-'
                                    : _formatMonto(caja!.montoCierreDeclarado!),
                              ),
                              _InfoRow(
                                label: 'Pagos pendientes',
                                value: '${caja?.pagosPendientes ?? 0}',
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActions(abierta),
                const SizedBox(height: 12),
                _buildMovimientosHeader(),
                const SizedBox(height: 8),
                _buildMovimientosList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelector() {
    CajaDetalle? selectedCaja;
    for (final caja in _cajas) {
      if (caja.id == _selectedCajaId) {
        selectedCaja = caja;
        break;
      }
    }
    final subtitle = selectedCaja == null
        ? (_selectedCajaId == null ? 'Sin selección' : '${_selectedCajaId!} · Seleccionada')
        : '${selectedCaja.id} · ${selectedCaja.estado}';

    return Card(
      child: ListTile(
        onTap: _loading ? null : _abrirSelectorCajas,
        leading: const Icon(Icons.point_of_sale_outlined),
        title: const Text('Seleccionar caja'),
        subtitle: Text('$subtitle\nMostrando ${_cajas.length}/$_totalCajas'),
        isThreeLine: true,
        trailing: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
    );
  }

  Widget _buildActions(bool abierta) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loading || abierta ? null : _abrirCaja,
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Abrir caja'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _loading || !abierta ? null : _cerrarCaja,
            icon: const Icon(Icons.lock_rounded),
            label: const Text('Cerrar caja'),
          ),
        ),
      ],
    );
  }

  Widget _buildMovimientosHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Movimientos (${_movimientos.length}/$_totalMovimientos)',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.secondary,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String?>(
            value: _filtroEstadoPago,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
              DropdownMenuItem(value: 'PAGADO', child: Text('Pagado')),
              DropdownMenuItem(value: 'ANULADO', child: Text('Anulado')),
              DropdownMenuItem(value: 'REEMPLAZADO', child: Text('Reemplazado')),
            ],
            onChanged: _loading ? null : _aplicarFiltroEstado,
          ),
        ),
      ],
    );
  }

  Widget _buildMovimientosList() {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_movimientos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay movimientos para los filtros seleccionados.'),
        ),
      );
    }

    return Column(
      children: [
        ..._movimientos.map(
          (mov) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              title: Text(_formatMonto(mov.monto)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pago: ${mov.id}'),
                  Text('Cita: ${mov.idCita.isEmpty ? '-' : mov.idCita}'),
                  Text('Método: ${mov.metodoPago}'),
                  Text('Fecha: ${_formatDateTime(mov.fechaPago)}'),
                  if (mov.observacion.trim().isNotEmpty)
                    Text('Obs: ${mov.observacion.trim()}'),
                ],
              ),
              trailing: Chip(
                label: Text(mov.estadoPago.toUpperCase()),
                backgroundColor: _chipColorByEstado(mov.estadoPago).withValues(alpha: 0.14),
                labelStyle: TextStyle(
                  color: _chipColorByEstado(mov.estadoPago),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        if (_hasMoreMovimientos)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: _loadingMovimientos ? null : _cargarMasMovimientos,
              icon: _loadingMovimientos
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: const Text('Cargar más movimientos'),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(color: theme.neutral),
            ),
          ),
        ],
      ),
    );
  }
}

class _CajaSelectorBottomSheet extends StatefulWidget {
  const _CajaSelectorBottomSheet({
    required this.service,
    required this.selectedCajaId,
    required this.defaultCajaId,
    required this.initialRows,
    required this.initialTotal,
    required this.limit,
  });

  final CajasService service;
  final String? selectedCajaId;
  final String? defaultCajaId;
  final List<CajaDetalle> initialRows;
  final int initialTotal;
  final int limit;

  @override
  State<_CajaSelectorBottomSheet> createState() => _CajaSelectorBottomSheetState();
}

class _CajaSelectorBottomSheetState extends State<_CajaSelectorBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  List<CajaDetalle> _rows = const [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;

  bool get _hasMore => _rows.length < _total;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialRows;
    _total = widget.initialTotal;
    _page = (_rows.length / widget.limit).ceil() + 1;
    _scrollController.addListener(_onScroll);
    if (_rows.isEmpty) {
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) return;
    final pixels = _scrollController.position.pixels;
    final max = _scrollController.position.maxScrollExtent;
    if (pixels >= max - 120) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || _loadingMore) return;
    setState(() {
      if (reset) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
    });

    final nextPage = reset ? 1 : _page;
    final res = await widget.service.listarCajas(
      pagina: nextPage,
      limite: widget.limit,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      _total = res.total;
      _rows = reset ? res.rows : [..._rows, ...res.rows];
      _page = nextPage + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Seleccionar caja',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mostrando ${_rows.length}/$_total resultados',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _rows.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _rows.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final caja = _rows[index];
                        final isSelected = caja.id == widget.selectedCajaId;
                        final isDefault = caja.id == widget.defaultCajaId;
                        return ListTile(
                          onTap: () => Navigator.of(context).pop(caja.id),
                          leading: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          ),
                          title: Text(caja.id),
                          subtitle: Text(
                            isDefault ? '${caja.estado} · Predeterminada' : caja.estado,
                          ),
                          trailing: Text(
                            caja.pagosPendientes > 0
                                ? 'Pendientes: ${caja.pagosPendientes}'
                                : 'Sin pendientes',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MontoDialogResult {
  final bool confirmed;
  final double? monto;

  const _MontoDialogResult._({required this.confirmed, this.monto});

  const _MontoDialogResult.confirmed({double? monto})
      : this._(confirmed: true, monto: monto);
  const _MontoDialogResult.cancelled() : this._(confirmed: false);
}
