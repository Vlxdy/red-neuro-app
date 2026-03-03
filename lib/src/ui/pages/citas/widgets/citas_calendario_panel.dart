import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:table_calendar/table_calendar.dart';

class CitasCalendarioPanel extends StatelessWidget {
  final ThemeController theme;
  final CalendarFormat calendarFormat;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, int> citasPorDia;
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
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.black.withValues(alpha: theme.isLight ? 0.05 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar<int>(
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
              final cantidad = citasPorDia[key] ?? 0;
              return List<int>.filled(cantidad, 1);
            },
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            availableGestures: AvailableGestures.all,
            calendarStyle: CalendarStyle(
              markerSize: 6,
              markersAlignment: Alignment.bottomCenter,
              todayDecoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) =>
                  DateFormat.E(locale).format(date)[0].toUpperCase(),
              weekdayStyle:
                  TextStyle(color: theme.primary, fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(
                color: theme.fontColor.withValues(alpha: 0.6),
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
              markerBuilder: (context, day, events) {
                if (events.isEmpty) {
                  return null;
                }

                final markerColor =
                    events.length > 4 ? theme.error : theme.warning;
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
