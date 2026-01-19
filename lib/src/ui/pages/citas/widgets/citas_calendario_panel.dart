import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:table_calendar/table_calendar.dart';

class CitasCalendarioPanel extends StatelessWidget {
  final ThemeController theme;
  final CalendarFormat calendarFormat;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<CitaMedica>> citasPorDia;
  final ValueChanged<CalendarFormat> onFormatChanged;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final bool isCompact;
  final bool dayLoading;
  final Widget listado;
  final Future<void> Function() onRefresh;

  const CitasCalendarioPanel({
    super.key,
    required this.theme,
    required this.calendarFormat,
    required this.focusedDay,
    required this.selectedDay,
    required this.citasPorDia,
    required this.onFormatChanged,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.isCompact,
    required this.dayLoading,
    required this.listado,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final listadoWidget = dayLoading
        ? Center(
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(color: theme.primary),
            ),
          )
        : listado;

    final calendario = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar<CitaMedica>(
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: focusedDay,
            calendarFormat: calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            sixWeekMonthsEnforced: true,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mes',
              CalendarFormat.week: 'Semana',
            },
            headerStyle: HeaderStyle(
              titleTextStyle: Theme.of(context).textTheme.titleSmall ??
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
            ),
            onFormatChanged: onFormatChanged,
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return citasPorDia[key] ?? [];
            },
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            availableGestures: AvailableGestures.all,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) =>
                  DateFormat.E(locale).format(date)[0].toUpperCase(),
              weekdayStyle:
                  TextStyle(color: theme.primary, fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(
                color: theme.black.withValues(alpha: 0.54),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = DateFormat.E('es_ES')
                    .format(day)
                    .substring(0, 1)
                    .toUpperCase();
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              calendario,
              const SizedBox(height: 16),
              listadoWidget,
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: calendario),
        const SizedBox(width: 16),
        Expanded(child: listadoWidget),
      ],
    );
  }
}
