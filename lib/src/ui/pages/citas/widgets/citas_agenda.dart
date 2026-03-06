import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_badges.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/info_pill.dart';
import 'package:table_calendar/table_calendar.dart';

class CitasAgendaSection extends StatelessWidget {
  final List<CitaMedica> citas;
  final bool isCompact;
  final ThemeController theme;
  final DateFormat dateFormat;
  final DateTime agendaDay;
  final DateTime agendaFocusedDay;
  final CalendarFormat agendaCalendarFormat;
  final bool agendaCalendarCollapsed;
  final Map<DateTime, int> citasAgendaPorDia;
  final void Function(DateTime selectedDay, DateTime focusedDay)
  onAgendaDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final ValueChanged<CalendarFormat> onAgendaFormatChanged;
  final VoidCallback onToggleDailyInfoRibbon;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ScrollController? scrollController;
  final String Function(DateTime? inicio, int hour) formatoHoraAgenda;
  final String Function(DateTime? inicio, DateTime? fin) formatoHorarioCita;
  final String Function(CitaMedica cita) tituloCita;
  final String Function(CitaMedica cita) nombreMedico;
  final String Function(CitaMedica cita) nombrePaciente;
  final IconData Function(CitaMedica cita) iconoTipoCita;
  final Color Function(CitaMedica cita) colorEspecialidad;
  final Color Function(String estado) colorEstado;
  final VoidCallback Function(CitaMedica cita) onTapCita;
  final ValueChanged<int> onTapHora;

  const CitasAgendaSection({
    super.key,
    required this.citas,
    required this.isCompact,
    required this.theme,
    required this.dateFormat,
    required this.agendaDay,
    required this.agendaFocusedDay,
    required this.agendaCalendarFormat,
    required this.agendaCalendarCollapsed,
    required this.citasAgendaPorDia,
    required this.onAgendaDaySelected,
    required this.onPageChanged,
    required this.onAgendaFormatChanged,
    required this.onToggleDailyInfoRibbon,
    required this.isLoading,
    required this.onRefresh,
    required this.scrollController,
    required this.formatoHoraAgenda,
    required this.formatoHorarioCita,
    required this.tituloCita,
    required this.nombreMedico,
    required this.nombrePaciente,
    required this.iconoTipoCita,
    required this.colorEspecialidad,
    required this.colorEstado,
    required this.onTapCita,
    required this.onTapHora,
  });

  @override
  Widget build(BuildContext context) {
    final ordenadas = [...citas]
      ..sort(
        (a, b) => (a.fechaInicio ?? DateTime(1970)).compareTo(
          b.fechaInicio ?? DateTime(1970),
        ),
      );
    final citasPorHora = <int, List<CitaMedica>>{};
    final citasAntesDeLasOcho = <CitaMedica>[];
    final citasDespuesDeLasVeinte = <CitaMedica>[];

    for (final cita in ordenadas) {
      final inicio = cita.fechaInicio;
      if (inicio == null) continue;

      if (inicio.hour < 8) {
        citasAntesDeLasOcho.add(cita);
        continue;
      }

      if (inicio.hour > 20) {
        citasDespuesDeLasVeinte.add(cita);
        continue;
      }

      citasPorHora.putIfAbsent(inicio.hour, () => []).add(cita);
    }

    final header = Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isCompact ? double.infinity : 320,
          child: _AgendaWeekCalendar(
            theme: theme,
            agendaFocusedDay: agendaFocusedDay,
            agendaDay: agendaDay,
            agendaCalendarFormat: agendaCalendarFormat,
            isCollapsed: agendaCalendarCollapsed,
            citasAgendaPorDia: citasAgendaPorDia,
            onAgendaDaySelected: onAgendaDaySelected,
            onPageChanged: onPageChanged,
            onAgendaFormatChanged: onAgendaFormatChanged,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: onToggleDailyInfoRibbon,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: theme.isLight ? 0.1 : 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.24),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: InfoPill(
                        icon: PhosphorIconsRegular.calendarBlank,
                        label: dateFormat.format(agendaDay),
                        color: theme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: InfoPill(
                        icon: PhosphorIconsRegular.clock,
                        label: '08:00 - 20:00',
                        color: theme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: InfoPill(
                        icon: PhosphorIconsRegular.stethoscope,
                        label: '${ordenadas.length} citas',
                        color: theme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(color: theme.primary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: _AgendaTimeline(
                    citasPorHora: citasPorHora,
                    citasAntesDeLasOcho: citasAntesDeLasOcho,
                    citasDespuesDeLasVeinte: citasDespuesDeLasVeinte,
                    theme: theme,
                    scrollController: scrollController,
                    formatoHoraAgenda: formatoHoraAgenda,
                    formatoHorarioCita: formatoHorarioCita,
                    tituloCita: tituloCita,
                    nombreMedico: nombreMedico,
                    nombrePaciente: nombrePaciente,
                    iconoTipoCita: iconoTipoCita,
                    colorEspecialidad: colorEspecialidad,
                    colorEstado: colorEstado,
                    onTapCita: onTapCita,
                    onTapHora: onTapHora,
                  ),
                ),
        ),
      ],
    );
  }
}

class _AgendaWeekCalendar extends StatelessWidget {
  final ThemeController theme;
  final DateTime agendaFocusedDay;
  final DateTime agendaDay;
  final CalendarFormat agendaCalendarFormat;
  final bool isCollapsed;
  final Map<DateTime, int> citasAgendaPorDia;
  final void Function(DateTime selectedDay, DateTime focusedDay)
  onAgendaDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final ValueChanged<CalendarFormat> onAgendaFormatChanged;

  const _AgendaWeekCalendar({
    required this.theme,
    required this.agendaFocusedDay,
    required this.agendaDay,
    required this.agendaCalendarFormat,
    required this.isCollapsed,
    required this.citasAgendaPorDia,
    required this.onAgendaDaySelected,
    required this.onPageChanged,
    required this.onAgendaFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: isCollapsed ? 0 : 1,
          child: TableCalendar<int>(
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: agendaFocusedDay,
            calendarFormat: agendaCalendarFormat,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mes',
              CalendarFormat.week: 'Semana',
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(agendaDay, day),
            headerVisible: !isCollapsed,
            rowHeight: 30,
            daysOfWeekHeight: 20,
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              final cantidad = citasAgendaPorDia[key] ?? 0;
              return List<int>.filled(cantidad, 1);
            },
            headerStyle: HeaderStyle(
              titleTextStyle:
                  Theme.of(context).textTheme.labelLarge ??
                  const TextStyle(fontWeight: FontWeight.w600),
              titleCentered: false,
              formatButtonVisible: true,
              formatButtonDecoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              formatButtonTextStyle: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                size: 18,
                color: theme.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.primary,
              ),
              headerPadding: EdgeInsets.zero,
              leftChevronMargin: EdgeInsets.zero,
              rightChevronMargin: EdgeInsets.zero,
            ),
            onFormatChanged: onAgendaFormatChanged,
            onDaySelected: onAgendaDaySelected,
            onPageChanged: onPageChanged,
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) =>
                  DateFormat.E(locale).format(date)[0].toUpperCase(),
              weekdayStyle: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: theme.fontColor.withValues(alpha: 0.6),
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: EdgeInsets.zero,
              cellPadding: EdgeInsets.zero,
              markerSize: 6,
              markersAlignment: Alignment.bottomCenter,
              markerMargin: EdgeInsets.zero,
              todayDecoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) {
                  return null;
                }

                final markerColor = events.length > 4
                    ? theme.error
                    : theme.warning;
                final markerCount = events.length > 4 ? 4 : events.length;

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      markerCount,
                      (index) => Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaTimeline extends StatelessWidget {
  final Map<int, List<CitaMedica>> citasPorHora;
  final List<CitaMedica> citasAntesDeLasOcho;
  final List<CitaMedica> citasDespuesDeLasVeinte;
  final ThemeController theme;
  final ScrollController? scrollController;
  final String Function(DateTime? inicio, int hour) formatoHoraAgenda;
  final String Function(DateTime? inicio, DateTime? fin) formatoHorarioCita;
  final String Function(CitaMedica cita) tituloCita;
  final String Function(CitaMedica cita) nombreMedico;
  final String Function(CitaMedica cita) nombrePaciente;
  final IconData Function(CitaMedica cita) iconoTipoCita;
  final Color Function(CitaMedica cita) colorEspecialidad;
  final Color Function(String estado) colorEstado;
  final VoidCallback Function(CitaMedica cita) onTapCita;
  final ValueChanged<int> onTapHora;

  const _AgendaTimeline({
    required this.citasPorHora,
    required this.citasAntesDeLasOcho,
    required this.citasDespuesDeLasVeinte,
    required this.theme,
    required this.scrollController,
    required this.formatoHoraAgenda,
    required this.formatoHorarioCita,
    required this.tituloCita,
    required this.nombreMedico,
    required this.nombrePaciente,
    required this.iconoTipoCita,
    required this.colorEspecialidad,
    required this.colorEstado,
    required this.onTapCita,
    required this.onTapHora,
  });

  @override
  Widget build(BuildContext context) {
    final horas = List.generate(13, (index) => index + 8);
    final filas = <({String label, List<CitaMedica> citas, int? hour})>[];

    if (citasAntesDeLasOcho.isNotEmpty) {
      filas.add((
        label: '< 08:00',
        citas: citasAntesDeLasOcho,
        hour: null,
      ));
    }

    for (final hour in horas) {
      filas.add((
        label: '${hour.toString().padLeft(2, '0')}:00',
        citas: citasPorHora[hour] ?? [],
        hour: hour,
      ));
    }

    if (citasDespuesDeLasVeinte.isNotEmpty) {
      filas.add((
        label: '> 20:00',
        citas: citasDespuesDeLasVeinte,
        hour: null,
      ));
    }

    if (filas.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        children: [
          Center(
            child: Text(
              'No hay citas para este día',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.grey.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filas.length,
      separatorBuilder: (_, _) =>
          _DashedSeparator(color: theme.grey.withValues(alpha: 0.24)),
      itemBuilder: (context, index) {
        final fila = filas[index];
        final citas = fila.citas;
        if (citas.isEmpty) {
          return _AgendaRow(
            label: fila.label,
            theme: theme,
            onTapLabel: fila.hour == null ? null : () => onTapHora(fila.hour!),
            child: Text(
              'Sin citas',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.grey.withValues(alpha: 0.7),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < citas.length; i++)
              _AgendaRow(
                label: i == 0
                    ? fila.label
                    : (fila.hour == null
                          ? formatoHorarioCita(citas[i].fechaInicio, citas[i].fechaFin)
                          : formatoHoraAgenda(citas[i].fechaInicio, fila.hour!)),
                theme: theme,
                onTapLabel: (i == 0 && fila.hour != null)
                    ? () => onTapHora(fila.hour!)
                    : null,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i == citas.length - 1 ? 0 : 2,
                  ),
                  child: _AgendaCitaCard(
                    cita: citas[i],
                    theme: theme,
                    formatoHorarioCita: formatoHorarioCita,
                    tituloCita: tituloCita,
                    nombreMedico: nombreMedico,
                    nombrePaciente: nombrePaciente,
                    iconoTipoCita: iconoTipoCita,
                    colorEspecialidad: colorEspecialidad,
                    colorEstado: colorEstado,
                    onTap: onTapCita(citas[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AgendaRow extends StatelessWidget {
  final String label;
  final ThemeController theme;
  final Widget child;
  final VoidCallback? onTapLabel;

  const _AgendaRow({
    required this.label,
    required this.theme,
    required this.child,
    this.onTapLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onTapLabel,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1, bottom: 5),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DashedSeparator extends StatelessWidget {
  final Color color;

  const _DashedSeparator({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
            .floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              child: Divider(
                color: color,
                height: 10,
                thickness: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AgendaCitaCard extends StatelessWidget {
  final CitaMedica cita;
  final ThemeController theme;
  final String Function(DateTime? inicio, DateTime? fin) formatoHorarioCita;
  final String Function(CitaMedica cita) tituloCita;
  final String Function(CitaMedica cita) nombreMedico;
  final String Function(CitaMedica cita) nombrePaciente;
  final IconData Function(CitaMedica cita) iconoTipoCita;
  final Color Function(CitaMedica cita) colorEspecialidad;
  final Color Function(String estado) colorEstado;
  final VoidCallback onTap;

  const _AgendaCitaCard({
    required this.cita,
    required this.theme,
    required this.formatoHorarioCita,
    required this.tituloCita,
    required this.nombreMedico,
    required this.nombrePaciente,
    required this.iconoTipoCita,
    required this.colorEspecialidad,
    required this.colorEstado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final especialidadColor = colorEspecialidad(cita);
    final horario = formatoHorarioCita(cita.fechaInicio, cita.fechaFin);
    final titulo = tituloCita(cita);
    final medico = nombreMedico(cita);
    final paciente = nombrePaciente(cita);
    final especialidad = (cita.especialidadNombre ?? '').trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: especialidadColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.black.withValues(alpha: theme.isLight ? 0.04 : 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                CitasEstadoBadge(
                  estado: cita.estado,
                  color: colorEstado(cita.estado),
                ),
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
                if (especialidad.isNotEmpty)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: especialidadColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          especialidad,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: especialidadColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
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
