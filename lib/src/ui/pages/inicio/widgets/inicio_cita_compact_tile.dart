import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_badges.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/info_pill.dart';

class InicioCitaCompactTile extends StatelessWidget {
  const InicioCitaCompactTile({
    super.key,
    required this.cita,
    required this.onTap,
  });

  final CitaMedica cita;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final estado = CitasEstado.fromValue(cita.estado.toUpperCase());
    final estadoColor = estado.color(theme);

    final fechaInicio = cita.fechaInicio?.toLocal();
    final fechaFin = cita.fechaFin?.toLocal();
    final diaSemana = fechaInicio == null
        ? '---'
        : DateFormat('EEE', 'es').format(fechaInicio).toUpperCase();
    final fecha = fechaInicio == null
        ? '--/--/----'
        : DateFormat('dd/MM/yyyy', 'es').format(fechaInicio);
    final horaInicio = fechaInicio == null
        ? '--:--'
        : DateFormat('HH:mm').format(fechaInicio);
    final horaFin = fechaFin == null ? '--:--' : DateFormat('HH:mm').format(fechaFin);

    final servicio = (cita.servicioNombre ?? '').trim().isNotEmpty
        ? cita.servicioNombre!.trim()
        : 'Sin servicio';
    final personal = (cita.personalNombre ?? '').trim().isNotEmpty
        ? cita.personalNombre!.trim()
        : 'Sin personal asignado';
    final paciente = (cita.pacienteNombre ?? '').trim().isNotEmpty
        ? cita.pacienteNombre!.trim()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: estadoColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.clock,
                                  size: 13,
                                  color: theme.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$diaSemana $fecha · $horaInicio-$horaFin',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: theme.grey,
                                      fontSize: 10,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          CitasEstadoBadge(
                            estado: estado.label,
                            color: estadoColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        servicio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        children: [
                          InfoPill(
                            icon: PhosphorIconsRegular.stethoscope,
                            label: personal,
                            color: theme.grey,
                          ),
                          if (paciente != null)
                            InfoPill(
                              icon: PhosphorIconsRegular.userCircle,
                              label: paciente,
                              color: theme.grey,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
