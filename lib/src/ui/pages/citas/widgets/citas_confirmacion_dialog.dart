import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class CitaAccionConfirmacionData {
  final bool esNueva;
  final String tipoCita;
  final String servicioNombre;
  final DateTime fechaInicio;
  final int? duracionMinutos;
  final String? pacienteNombre;
  final String? especialidadNombre;
  final String? medicoNombre;
  final String? pacienteDocumento;
  final String? pacienteTelefono;
  final String? pacienteGenero;
  final String? lugarNombre;
  final String? lugarDireccion;
  final String? detalle;

  const CitaAccionConfirmacionData({
    required this.esNueva,
    required this.tipoCita,
    required this.servicioNombre,
    required this.fechaInicio,
    this.duracionMinutos,
    this.pacienteNombre,
    this.especialidadNombre,
    this.medicoNombre,
    this.pacienteDocumento,
    this.pacienteTelefono,
    this.pacienteGenero,
    this.lugarNombre,
    this.lugarDireccion,
    this.detalle,
  });
}

Future<String?> showCitaConfirmacionDialog({
  required BuildContext context,
  required CitaAccionConfirmacionData data,
  required DateFormat dateTimeFormat,
  required String? Function(String?) formatearGenero,
}) async {
  final theme = ThemeController.instance;

  Widget resumenFila({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.grey.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.grey.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final lugarDetalle = [
    if ((data.lugarNombre ?? '').trim().isNotEmpty) data.lugarNombre!.trim(),
    if ((data.lugarDireccion ?? '').trim().isNotEmpty)
      data.lugarDireccion!.trim(),
  ].join(' • ');

  final tipoNormalizado = data.tipoCita.trim().toUpperCase();
  final esConsulta = tipoNormalizado == 'CONSULTA';
  final etiquetaPrestacion = esConsulta ? 'Consulta' : 'Estudio';

  final mostrarPaciente =
      (data.pacienteNombre ?? '').trim().isNotEmpty ||
      (data.pacienteDocumento ?? '').trim().isNotEmpty ||
      (data.pacienteTelefono ?? '').trim().isNotEmpty ||
      (data.pacienteGenero ?? '').trim().isNotEmpty;

  final pacienteItems = <Widget>[
    if ((data.pacienteNombre ?? '').trim().isNotEmpty)
      Text('Nombre: ${data.pacienteNombre!.trim()}'),
    if ((data.pacienteDocumento ?? '').trim().isNotEmpty)
      Text('Documento: ${data.pacienteDocumento!.trim()}'),
    if ((data.pacienteTelefono ?? '').trim().isNotEmpty)
      Text('Teléfono: ${data.pacienteTelefono!.trim()}'),
    if ((data.pacienteGenero ?? '').trim().isNotEmpty)
      Text('Género: ${formatearGenero(data.pacienteGenero)}'),
  ];

  int segundosConfirmar = 2;
  Timer? countdownTimer;
  bool countdownIniciado = false;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          void cerrar([String? resultado]) {
            countdownTimer?.cancel();
            Navigator.pop(dialogContext, resultado);
          }

          if (!countdownIniciado) {
            countdownIniciado = true;
            countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (!dialogContext.mounted) {
                timer.cancel();
                return;
              }
              setStateDialog(() {
                if (segundosConfirmar > 0) {
                  segundosConfirmar -= 1;
                }
                if (segundosConfirmar == 0) {
                  timer.cancel();
                }
              });
            });
          }

          final Size screenSize = MediaQuery.sizeOf(dialogContext);
          final double dialogContentWidth = (screenSize.width - 32).clamp(
            280.0,
            440.0,
          );
          final double responsiveTextScale = (screenSize.width / 390).clamp(
            0.90,
            1.08,
          );

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    data.esNueva ? 'Confirmar cita' : 'Confirmar cambios',
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => cerrar(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: MediaQuery(
              data: MediaQuery.of(dialogContext).copyWith(
                textScaler: TextScaler.linear(responsiveTextScale),
              ),
              child: SizedBox(
                width: dialogContentWidth,
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.grey.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.grey.withValues(alpha: .2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 18,
                                color: theme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                etiquetaPrestacion,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: theme.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(data.servicioNombre),
                          if ((data.duracionMinutos ?? 0) > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Duración ${etiquetaPrestacion.toLowerCase()}: ${data.duracionMinutos} min',
                              ),
                            ),
                          if ((data.especialidadNombre ?? '').trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Especialidad: ${data.especialidadNombre!.trim()}',
                              ),
                            ),
                        ],
                      ),
                    ),
                    resumenFila(
                      icon: Icons.event_outlined,
                      label: 'Fecha y hora',
                      value: dateTimeFormat.format(data.fechaInicio),
                    ),
                    if (mostrarPaciente)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: .2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: theme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Paciente',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: theme.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...pacienteItems,
                          ],
                        ),
                      ),
                    if ((data.medicoNombre ?? '').trim().isNotEmpty)
                      resumenFila(
                        icon: Icons.badge_outlined,
                        label: 'Personal asignado',
                        value: data.medicoNombre!.trim(),
                      ),
                    if (lugarDetalle.isNotEmpty)
                      resumenFila(
                        icon: Icons.place_outlined,
                        label: 'Lugar',
                        value: lugarDetalle,
                      ),
                    if ((data.detalle ?? '').trim().isNotEmpty)
                      resumenFila(
                        icon: Icons.notes_outlined,
                        label: 'Detalle',
                        value: data.detalle!.trim(),
                      ),
                  ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => cerrar('GUARDAR'),
                child: const Text('Guardar'),
              ),
              FilledButton(
                onPressed: segundosConfirmar == 0 ? () => cerrar('ENVIAR') : null,
                child: Text(
                  segundosConfirmar == 0
                      ? 'Confirmar'
                      : 'Confirmar (${segundosConfirmar}s)',
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
