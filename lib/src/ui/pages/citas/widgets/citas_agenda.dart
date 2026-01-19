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
  final bool agendaCalendarCollapsed;
  final Map<DateTime, List<CitaMedica>> citasAgendaPorDia;
  final void Function(DateTime selectedDay, DateTime focusedDay)
      onAgendaDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final VoidCallback onExpandCalendar;
  final bool isLoading;
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

  const CitasAgendaSection({
    super.key,
    required this.citas,
    required this.isCompact,
    required this.theme,
    required this.dateFormat,
    required this.agendaDay,
    required this.agendaFocusedDay,
    required this.agendaCalendarCollapsed,
    required this.citasAgendaPorDia,
    required this.onAgendaDaySelected,
    required this.onPageChanged,
    required this.onExpandCalendar,
    required this.isLoading,
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
  });

  @override
  Widget build(BuildContext context) {
    final ordenadas = [...citas]
      ..sort(
        (a, b) =>
            (a.fechaInicio ?? DateTime(1970))
                .compareTo(b.fechaInicio ?? DateTime(1970)),
      );
    final citasPorHora = <int, List<CitaMedica>>{};
    for (final cita in ordenadas) {
      final inicio = cita.fechaInicio;
      if (inicio == null) continue;
      if (inicio.hour < 8 || inicio.hour > 20) continue;
      citasPorHora.putIfAbsent(inicio.hour, () => []).add(cita);
    }

    final header = GestureDetector(
      onTap: agendaCalendarCollapsed ? onExpandCalendar : null,
      child: Wrap(
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
              isCollapsed: agendaCalendarCollapsed,
              citasAgendaPorDia: citasAgendaPorDia,
              onAgendaDaySelected: onAgendaDaySelected,
              onPageChanged: onPageChanged,
            ),
          ),
          InfoPill(
            icon: PhosphorIconsRegular.calendarBlank,
            label: 'Agenda ${dateFormat.format(agendaDay)}',
            color: theme.primary,
          ),
          InfoPill(
            icon: PhosphorIconsRegular.clock,
            label: '08:00 - 20:00',
            color: theme.grey,
          ),
          InfoPill(
            icon: PhosphorIconsRegular.stethoscope,
            label: '${ordenadas.length} citas',
            color: theme.secondary,
          ),
        ],
      ),
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
              : _AgendaTimeline(
                  citasPorHora: citasPorHora,
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
  final bool isCollapsed;
  final Map<DateTime, List<CitaMedica>> citasAgendaPorDia;
  final void Function(DateTime selectedDay, DateTime focusedDay)
      onAgendaDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  const _AgendaWeekCalendar({
    required this.theme,
    required this.agendaFocusedDay,
    required this.agendaDay,
    required this.isCollapsed,
    required this.citasAgendaPorDia,
    required this.onAgendaDaySelected,
    required this.onPageChanged,
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
          child: TableCalendar<CitaMedica>(
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: agendaFocusedDay,
            calendarFormat: CalendarFormat.week,
            availableCalendarFormats: const {
              CalendarFormat.week: 'Semana',
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(agendaDay, day),
            headerVisible: !isCollapsed,
            rowHeight: 30,
            daysOfWeekHeight: 20,
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return citasAgendaPorDia[key] ?? [];
            },
            headerStyle: HeaderStyle(
              titleTextStyle: Theme.of(context).textTheme.labelLarge ??
                  const TextStyle(fontWeight: FontWeight.w600),
              titleCentered: false,
              formatButtonVisible: false,
              leftChevronIcon:
                  Icon(Icons.chevron_left, size: 18, color: theme.primary),
              rightChevronIcon:
                  Icon(Icons.chevron_right, size: 18, color: theme.primary),
              headerPadding: EdgeInsets.zero,
              leftChevronMargin: EdgeInsets.zero,
              rightChevronMargin: EdgeInsets.zero,
            ),
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
                color: theme.black.withValues(alpha: 0.54),
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: EdgeInsets.zero,
              cellPadding: EdgeInsets.zero,
              markerSize: 5,
              markersAlignment: Alignment.bottomCenter,
              markerMargin: EdgeInsets.zero,
              markerDecoration: BoxDecoration(
                color: theme.secondary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaTimeline extends StatelessWidget {
  final Map<int, List<CitaMedica>> citasPorHora;
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

  const _AgendaTimeline({
    required this.citasPorHora,
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
  });

  @override
  Widget build(BuildContext context) {
    final horas = List.generate(13, (index) => index + 8);
    if (horas.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: horas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final hour = horas[index];
        final hourLabel = '${hour.toString().padLeft(2, '0')}:00';
        final citas = citasPorHora[hour] ?? [];
        if (citas.isEmpty) {
          return _AgendaRow(
            label: hourLabel,
            theme: theme,
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
                    ? hourLabel
                    : formatoHoraAgenda(citas[i].fechaInicio, hour),
                theme: theme,
                child: Padding(
                  padding: EdgeInsets.only(bottom: i == citas.length - 1 ? 0 : 4),
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

  const _AgendaRow({
    required this.label,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  color: theme.grey.withValues(alpha: 0.2),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: especialidadColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  iconoTipoCita(cita),
                  size: 18,
                  color: theme.primary,
                ),
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
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(PhosphorIconsRegular.clock, size: 16, color: theme.grey),
                const SizedBox(width: 6),
                Text(
                  horario,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.grey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                if ((cita.especialidadNombre ?? '').trim().isNotEmpty)
                  InfoPill(
                    icon: PhosphorIconsRegular.tag,
                    label: cita.especialidadNombre!.trim(),
                    color: especialidadColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
