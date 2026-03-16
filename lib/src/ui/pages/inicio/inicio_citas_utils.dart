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

class InicioCitasUtils {
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
    var motivo = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Motivo de rechazo'),
        content: TextFormField(
          maxLines: 3,
          maxLength: 255,
          onChanged: (value) => motivo = value,
          decoration: const InputDecoration(labelText: 'Motivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = motivo.trim();
              if (value.isEmpty) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
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
      '$accion disponible en la bandeja de Citas.',
      state: StatusSnackBar.info,
      colorText: theme.white,
    );
  }
}
