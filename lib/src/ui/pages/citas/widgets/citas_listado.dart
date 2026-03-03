import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_badges.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/info_pill.dart';

class CitasListadoTab extends StatelessWidget {
  final List<CitaMedica> citas;
  final ThemeController theme;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;
  final bool isLoadingMore;
  final Color Function(String estado) colorEstado;
  final Color Function(CitaMedica cita) colorEspecialidad;
  final String Function(DateTime? fecha) formatoFecha;
  final String Function(DateTime? inicio, DateTime? fin) formatoHorario;
  final String Function(CitaMedica cita) tituloCita;
  final IconData Function(CitaMedica cita) iconoTipoCita;
  final String Function(CitaMedica cita) nombreMedico;
  final String Function(CitaMedica cita) nombrePaciente;
  final VoidCallback Function(CitaMedica cita) onVerDetalle;
  final VoidCallback Function(CitaMedica cita) onEditar;
  final bool Function(CitaMedica cita) puedeEditar;

  const CitasListadoTab({
    super.key,
    required this.citas,
    required this.theme,
    required this.controller,
    required this.onRefresh,
    required this.isLoadingMore,
    required this.colorEstado,
    required this.colorEspecialidad,
    required this.formatoFecha,
    required this.formatoHorario,
    required this.tituloCita,
    required this.iconoTipoCita,
    required this.nombreMedico,
    required this.nombrePaciente,
    required this.onVerDetalle,
    required this.onEditar,
    required this.puedeEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CitasListado(
            citas: citas,
            theme: theme,
            controller: controller,
            onRefresh: onRefresh,
            colorEstado: colorEstado,
            colorEspecialidad: colorEspecialidad,
            formatoFecha: formatoFecha,
            formatoHorario: formatoHorario,
            tituloCita: tituloCita,
            iconoTipoCita: iconoTipoCita,
            nombreMedico: nombreMedico,
            nombrePaciente: nombrePaciente,
            onVerDetalle: onVerDetalle,
            onEditar: onEditar,
            puedeEditar: puedeEditar,
          ),
        ),
        if (isLoadingMore) const SizedBox(height: 12),
        if (isLoadingMore)
          Center(
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(color: theme.primary),
            ),
          ),
      ],
    );
  }
}

class CitasListado extends StatelessWidget {
  final List<CitaMedica> citas;
  final ThemeController theme;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;
  final bool embedInScroll;
  final Color Function(String estado) colorEstado;
  final Color Function(CitaMedica cita) colorEspecialidad;
  final String Function(DateTime? fecha) formatoFecha;
  final String Function(DateTime? inicio, DateTime? fin) formatoHorario;
  final String Function(CitaMedica cita) tituloCita;
  final IconData Function(CitaMedica cita) iconoTipoCita;
  final String Function(CitaMedica cita) nombreMedico;
  final String Function(CitaMedica cita) nombrePaciente;
  final VoidCallback Function(CitaMedica cita) onVerDetalle;
  final VoidCallback Function(CitaMedica cita) onEditar;
  final bool Function(CitaMedica cita) puedeEditar;

  const CitasListado({
    super.key,
    required this.citas,
    required this.theme,
    required this.controller,
    required this.onRefresh,
    this.embedInScroll = false,
    required this.colorEstado,
    required this.colorEspecialidad,
    required this.formatoFecha,
    required this.formatoHorario,
    required this.tituloCita,
    required this.iconoTipoCita,
    required this.nombreMedico,
    required this.nombrePaciente,
    required this.onVerDetalle,
    required this.onEditar,
    required this.puedeEditar,
  });

  @override
  Widget build(BuildContext context) {
    if (citas.isEmpty) {
      final emptyState = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.calendarBlank,
            size: 48,
            color: theme.grey.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay citas registradas',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.grey),
          ),
        ],
      );

      if (embedInScroll) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(child: emptyState),
        );
      }

      final emptyList = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(child: emptyState),
        ],
      );

      return onRefresh != null
          ? RefreshIndicator(onRefresh: onRefresh!, child: emptyList)
          : Center(child: emptyState);
    }

    final listView = ListView.separated(
      controller: controller,
      physics: embedInScroll
          ? const NeverScrollableScrollPhysics()
          : onRefresh != null
          ? const AlwaysScrollableScrollPhysics()
          : null,
      padding: const EdgeInsets.only(top: 8),
      shrinkWrap: embedInScroll,
      itemCount: citas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cita = citas[index];
        final estadoColor = colorEstado(cita.estado);
        final especialidadColor = colorEspecialidad(cita);
        final resumenFecha = formatoFecha(cita.fechaInicio);
        final resumenHorario = formatoHorario(cita.fechaInicio, cita.fechaFin);
        final medicoNombre = nombreMedico(cita);
        final pacienteNombre = nombrePaciente(cita);
        final titulo = tituloCita(cita);
        final tipoIcono = iconoTipoCita(cita);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: especialidadColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.black.withValues(
                  alpha: theme.isLight ? 0.04 : 0.2,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: especialidadColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(tipoIcono, size: 20, color: theme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    titulo,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CitasEstadoBadge(
                            estado: cita.estado,
                            color: estadoColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          InfoPill(
                            icon: PhosphorIconsRegular.calendar,
                            label: resumenFecha,
                          ),
                          InfoPill(
                            icon: PhosphorIconsRegular.clock,
                            label: resumenHorario,
                          ),
                          if (pacienteNombre.isNotEmpty)
                            InfoPill(
                              icon: PhosphorIconsRegular.userCircle,
                              label: pacienteNombre,
                              color: theme.primary,
                            ),
                          if (medicoNombre.isNotEmpty)
                            InfoPill(
                              icon: PhosphorIconsRegular.stethoscope,
                              label: medicoNombre,
                              color: theme.secondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if ((cita.especialidadNombre ?? cita.especialidadId)
                                  ?.isNotEmpty ??
                              false)
                            CitasEspecialidadTag(
                              label:
                                  cita.especialidadNombre ??
                                  cita.especialidadId!,
                              color: especialidadColor,
                            ),
                          const Spacer(),
                          IconButton(
                            onPressed: onVerDetalle(cita),
                            icon: const Icon(Icons.info_outline),
                            tooltip: 'Ver detalles',
                          ),
                          if (puedeEditar(cita))
                            IconButton(
                              onPressed: onEditar(cita),
                              icon: const Icon(Icons.edit),
                              tooltip: 'Editar',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (onRefresh == null) {
      return listView;
    }

    return RefreshIndicator(onRefresh: onRefresh!, child: listView);
  }
}
