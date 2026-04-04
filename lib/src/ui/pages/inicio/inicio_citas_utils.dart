import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_service.dart';
import 'package:red_neuro_app/src/ui/pages/citas/citas_utils.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_historial_modal_widget.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_motivo_rechazo_dialog.dart';

class CompletarAtencionPayload {
  final double monto;
  final bool registrarPago;
  final String? metodoPago;
  final String? observacion;

  const CompletarAtencionPayload({
    required this.monto,
    required this.registrarPago,
    this.metodoPago,
    this.observacion,
  });

  Map<String, dynamic> toJson() => {
    'monto': monto,
    'registrarPago': registrarPago,
    if (metodoPago != null && metodoPago!.trim().isNotEmpty)
      'metodoPago': metodoPago!.trim(),
    if (observacion != null && observacion!.trim().isNotEmpty)
      'observacion': observacion!.trim(),
  };
}

class InicioCitasUtils {
  static const List<String> metodosPago = [
    'EFECTIVO',
    'QR',
    'TRANSFERENCIA',
    'TARJETA',
    'OTRO',
  ];

  static bool citaYaIniciada(CitaMedica cita) {
    final inicio = cita.fechaInicio;
    if (inicio == null) return false;
    return DateTime.now().isAfter(inicio.toLocal());
  }

  static String nombrePaciente(CitaMedica cita) =>
      (cita.pacienteNombre ?? '').trim().isNotEmpty
      ? cita.pacienteNombre!.trim()
      : 'Paciente no definido';

  static String nombreMedico(CitaMedica cita) =>
      (cita.personalNombre ?? '').trim().isNotEmpty
      ? cita.personalNombre!.trim()
      : 'Sin personal asignado';

  static String etiquetaPrestacion(String? tipo) =>
      (tipo ?? '').trim().toUpperCase() == 'ESTUDIO' ? 'Estudio' : 'Servicio';

  static String formatearGenero(String? genero) {
    final value = (genero ?? '').trim().toUpperCase();
    switch (value) {
      case 'M':
      case 'MASCULINO':
        return 'Masculino';
      case 'F':
      case 'FEMENINO':
        return 'Femenino';
      default:
        return value.isEmpty ? '' : value;
    }
  }

  static String formatearFechaPaciente(String? fechaRaw) {
    final fecha = DateTime.tryParse((fechaRaw ?? '').trim());
    if (fecha == null) return '';
    return DateFormat('dd/MM/yyyy').format(fecha.toLocal());
  }

  static String calcularEdadPaciente(String? fechaRaw) {
    final fecha = DateTime.tryParse((fechaRaw ?? '').trim());
    if (fecha == null) return '';
    final now = DateTime.now();
    var edad = now.year - fecha.year;
    if (now.month < fecha.month ||
        (now.month == fecha.month && now.day < fecha.day)) {
      edad--;
    }
    return edad >= 0 ? '$edad años' : '';
  }

  static String inicialesPersonal(CitaMedica cita) {
    final nombre = nombreMedico(cita);
    final partes =
        nombre.split(' ').where((part) => part.trim().isNotEmpty).toList();
    if (partes.isEmpty) return 'NA';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  static String formatoFechaCita(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    return DateFormat('EEEE d MMM yyyy', 'es').format(fecha.toLocal());
  }

  static String formatoHorarioCita(DateTime? inicio, DateTime? fin) {
    final inicioText =
        inicio == null ? '--:--' : DateFormat('HH:mm').format(inicio.toLocal());
    final finText =
        fin == null ? '--:--' : DateFormat('HH:mm').format(fin.toLocal());
    return '$inicioText - $finText';
  }

  static double montoSugeridoCita(CitaMedica cita) {
    final monto = cita.montoServicio ?? 0;
    return monto < 0 ? 0 : monto;
  }

  static Future<bool> confirmarYEnviar({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    required Future<ResponseApi> Function() request,
    required String fallback,
    required bool mounted,
    required void Function(String message) onError,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return false;
    return handleResponse(
      response: await request(),
      fallback: fallback,
      mounted: mounted,
      onError: onError,
    );
  }

  static Future<CompletarAtencionPayload?> solicitarCompletarAtencion(
    BuildContext context, {
    double montoInicial = 0,
  }) async {
    final montoController = TextEditingController(
      text: montoInicial.toStringAsFixed(2),
    );
    final observacionController = TextEditingController();
    var registrarPago = true;
    String? metodoPago = metodosPago.first;
    String? errorMonto;

    return showModalBottomSheet<CompletarAtencionPayload>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final insets = MediaQuery.of(sheetContext).viewInsets;
          return Padding(
            padding: EdgeInsets.only(bottom: insets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Completar atención',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montoController,
                    readOnly: !registrarPago,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monto *',
                      hintText: '0.00',
                      prefixText: 'Bs ',
                      errorText: errorMonto,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Registrar pago'),
                    value: registrarPago,
                    onChanged: (value) {
                      setStateDialog(() {
                        registrarPago = value;
                        if (!registrarPago) metodoPago = null;
                        if (registrarPago && metodoPago == null) {
                          metodoPago = metodosPago.first;
                        }
                      });
                    },
                  ),
                  if (registrarPago) ...[
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: metodoPago ?? metodosPago.first,
                      items: metodosPago
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setStateDialog(
                        () => metodoPago = value ?? metodosPago.first,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Método de pago',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: observacionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observación (opcional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final montoValue = montoController.text
                                .trim()
                                .replaceAll(',', '.');
                            final monto = double.tryParse(montoValue);
                            if (monto == null || monto < 0) {
                              setStateDialog(
                                () =>
                                    errorMonto = 'Ingresa un monto válido (>= 0)',
                              );
                              return;
                            }
                            Navigator.of(sheetContext).pop(
                              CompletarAtencionPayload(
                                monto: monto,
                                registrarPago: registrarPago,
                                metodoPago: registrarPago ? metodoPago : null,
                                observacion: observacionController.text,
                              ),
                            );
                          },
                          child: const Text('Completar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<bool> confirmarProgramarControl(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atención completada'),
        content: const Text('¿Deseas programar una cita de control ahora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sí, programar'),
          ),
        ],
      ),
    );
    return result == true;
  }

  static bool handleResponse({
    required ResponseApi response,
    required String fallback,
    required bool mounted,
    required void Function(String message) onError,
  }) {
    if (!mounted) return false;
    if (response.status == StatusNetwork.connected) return true;
    final message = response.message.isNotEmpty ? response.message : fallback;
    onError(message);
    return false;
  }

  static Future<String?> solicitarMotivoRechazo(BuildContext context) async {
    return showCitasMotivoRechazoDialog(context: context);
  }

  static Future<void> mostrarHistorialCita({
    required BuildContext context,
    required CitaMedica cita,
    required CitasService service,
    required ThemeController theme,
    required DateFormat dateFormat,
    required DateFormat dateTimeFormat,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CitasHistorialModalDialog(
          cita: cita,
          service: service,
          theme: theme,
          dateFormat: dateFormat,
          inicioDia: CitasUtils.inicioDia,
          finDia: CitasUtils.finDia,
          formatoFechaHoraHistorial: (fecha) =>
              CitasUtils.formatoFechaHoraHistorial(fecha, dateTimeFormat),
          tituloHistorial: CitasUtils.tituloHistorial,
          formatearDetalleCambio: (cambio) =>
              CitasUtils.formatearDetalleCambio(cambio, dateTimeFormat),
        );
      },
    );
  }

  static void mostrarNoDisponible({
    required GlobalKey<ScaffoldMessengerState> messenger,
    required ThemeController theme,
    required String accion,
  }) {
    showSnackBar(
      messenger,
      '$accion disponible en la bandeja de Agenda.',
      state: StatusSnackBar.info,
      colorText: theme.white,
    );
  }
}
