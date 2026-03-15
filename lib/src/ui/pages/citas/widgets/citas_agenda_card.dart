import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_badges.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/info_pill.dart';

class AgendaCitaCard extends StatelessWidget {
  final CitaMedica cita;
  final ThemeController theme;
  final String Function(DateTime? inicio, DateTime? fin) formatoHorarioCita;
  final String Function(CitaMedica cita) tituloCita;
  final String Function(CitaMedica cita) nombreMedico;
  final String Function(CitaMedica cita) nombrePaciente;
  final IconData Function(CitaMedica cita) iconoTipoCita;
  final Color Function(String estado) colorEstado;
  final VoidCallback onTap;

  const AgendaCitaCard({
    super.key,
    required this.cita,
    required this.theme,
    required this.formatoHorarioCita,
    required this.tituloCita,
    required this.nombreMedico,
    required this.nombrePaciente,
    required this.iconoTipoCita,
    required this.colorEstado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final estadoColor = colorEstado(cita.estado);
    final horario = formatoHorarioCita(cita.fechaInicio, cita.fechaFin);
    final titulo = tituloCita(cita);
    final medico = nombreMedico(cita);
    final paciente = nombrePaciente(cita);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: estadoColor.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: estadoColor.withValues(alpha: theme.isLight ? 0.12 : 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconoTipoCita(cita), size: 18, color: theme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CitasEstadoBadge(estado: cita.estado, color: estadoColor),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.clock,
                        size: 16,
                        color: theme.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        horario,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: theme.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (paciente.isNotEmpty)
                  InfoPill(
                    icon: PhosphorIconsRegular.userCircle,
                    label: paciente,
                    color: theme.grey,
                  ),
                if (medico.isNotEmpty)
                  InfoPill(
                    icon: PhosphorIconsRegular.stethoscope,
                    label: medico,
                    color: theme.grey,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
