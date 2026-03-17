import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

enum CitasEstado {
  borrador('BORRADOR'),
  solicitada('SOLICITADA'),
  programada('PROGRAMADA'),
  completada('COMPLETADA'),
  noAsistio('NO_ASISTIO'),
  cancelada('CANCELADA'),
  rechazada('RECHAZADA'),
  reprogramada('REPROGRAMADA');

  final String value;
  const CitasEstado(this.value);

  static List<String> get valuesAsString =>
      CitasEstado.values.map((estado) => estado.value).toList(growable: false);

  static CitasEstado fromValue(String? value) {
    return tryFromValue(value) ?? CitasEstado.borrador;
  }

  static CitasEstado? tryFromValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final estado in CitasEstado.values) {
      if (estado.value == normalized) return estado;
    }
    return null;
  }

  static String labelFromValue(String? value, {String emptyLabel = 'Todos'}) {
    final estado = tryFromValue(value);
    if (estado != null) return estado.label;
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? emptyLabel : normalized;
  }

  String get label {
    switch (this) {
      case CitasEstado.borrador:
        return 'Borrador';
      case CitasEstado.solicitada:
        return 'Solicitada';
      case CitasEstado.programada:
        return 'Programada';
      case CitasEstado.completada:
        return 'Completada';
      case CitasEstado.noAsistio:
        return 'No asistió';
      case CitasEstado.cancelada:
        return 'Cancelada';
      case CitasEstado.rechazada:
        return 'Rechazada';
      case CitasEstado.reprogramada:
        return 'Reprogramada';
    }
  }

  Color color(ThemeController theme) {
    switch (this) {
      case CitasEstado.borrador:
        return theme.grey.withValues(alpha: 0.75);
      case CitasEstado.solicitada:
        return theme.warning;
      case CitasEstado.programada:
        return theme.primary;
      case CitasEstado.completada:
        return theme.success;
      case CitasEstado.noAsistio:
        return const Color(0xFFB45309);
      case CitasEstado.cancelada:
        return theme.error;
      case CitasEstado.rechazada:
        return const Color(0xFF7E22CE);
      case CitasEstado.reprogramada:
        return const Color(0xFF0F766E);
    }
  }

  Color textColor(ThemeController theme) {
    switch (this) {
      case CitasEstado.borrador:
      case CitasEstado.solicitada:
      case CitasEstado.programada:
      case CitasEstado.completada:
        return theme.black;
      case CitasEstado.noAsistio:
      case CitasEstado.cancelada:
      case CitasEstado.rechazada:
      case CitasEstado.reprogramada:
        return theme.white;
    }
  }
}
