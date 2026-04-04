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

  late final CajasService _service;
  CajaSesion? _cajaActual;
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = CajasService(context);
  }

  Future<void> _cargarCaja() async {
    setState(() => _loading = true);
    final response = await _service.obtenerCajaActual();
    if (!mounted) return;
    setState(() {
      _cajaActual = response.caja;
      _loading = false;
    });
    if (response.status != StatusNetwork.connected &&
        response.message.trim().isNotEmpty) {
      showSnackBar(
        cajasMessenger,
        response.message,
        state: StatusSnackBar.error,
        colorText: theme.white,
      );
    }
  }

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
    final request = await _solicitarMonto(
      titulo: 'Cerrar caja',
      hintText: 'Monto declarado de cierre (opcional)',
      confirmLabel: 'Cerrar caja',
    );
    if (!mounted || request == null || !request.confirmed) return;
    await _ejecutarOperacion(
      () => _service.cerrarCaja(montoCierreDeclarado: request.monto),
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
    setState(() {
      _submitting = false;
      _cajaActual = response.caja ?? _cajaActual;
    });

    final isSuccess = response.status == StatusNetwork.connected;
    showSnackBar(
      cajasMessenger,
      response.message.trim().isEmpty
          ? successFallbackMessage
          : response.message,
      state: isSuccess ? StatusSnackBar.success : StatusSnackBar.error,
      colorText: theme.white,
    );

    await _cargarCaja();
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
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(titulo),
              content: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                    final normalized = raw.replaceAll(',', '.');
                    final parsed = double.tryParse(normalized);
                    if (parsed == null || parsed < 0) {
                      setLocalState(
                        () => error = 'Ingrese un monto válido mayor o igual a 0',
                      );
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

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return _dateTime.format(value.toLocal());
  }

  String _formatMonto(double value) => _money.format(value);

  @override
  Widget build(BuildContext context) {
    final caja = _cajaActual;
    final abierta = caja?.estaAbierta ?? false;

    return TemplatePage(
      cargando: _submitting,
      page: ScaffoldMessenger(
        key: cajasMessenger,
        child: Scaffold(
          backgroundColor: theme.transparent,
          appBar: const TrayModuleHeader(
            titulo: 'Cajas',
            subtitulo:
                'Administra apertura y cierre de caja para habilitar cobros de citas.',
          ),
          body: RefreshIndicator(
            onRefresh: _cargarCaja,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 1,
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
                                    abierta
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_outline_rounded,
                                    color: abierta ? theme.success : theme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    abierta ? 'Caja abierta' : 'Caja cerrada',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: theme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                label: 'ID sesión',
                                value: caja?.id.isNotEmpty == true
                                    ? caja!.id
                                    : '-',
                              ),
                              _InfoRow(
                                label: 'Fecha apertura',
                                value: _formatDateTime(caja?.fechaApertura),
                              ),
                              _InfoRow(
                                label: 'Fecha cierre',
                                value: _formatDateTime(caja?.fechaCierre),
                              ),
                              _InfoRow(
                                label: 'Monto apertura',
                                value: _formatMonto(caja?.montoApertura ?? 0),
                              ),
                              _InfoRow(
                                label: 'Monto recaudado',
                                value: _formatMonto(caja?.montoRecaudado ?? 0),
                              ),
                              _InfoRow(
                                label: 'Monto cierre declarado',
                                value: caja?.montoCierreDeclarado == null
                                    ? '-'
                                    : _formatMonto(caja!.montoCierreDeclarado!),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _loading ? null : _cargarCaja,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Actualizar estado'),
                      ),
                    ),
                  ],
                ),
                Row(
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
                ),
                if (!_loading && caja == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Aún no se consultó el estado de caja. Pulsa "Actualizar estado" para cargar la sesión actual.',
                    style: TextStyle(color: theme.secondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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

class _MontoDialogResult {
  final bool confirmed;
  final double? monto;

  const _MontoDialogResult._({required this.confirmed, this.monto});

  const _MontoDialogResult.confirmed({double? monto})
    : this._(confirmed: true, monto: monto);
  const _MontoDialogResult.cancelled() : this._(confirmed: false);
}
