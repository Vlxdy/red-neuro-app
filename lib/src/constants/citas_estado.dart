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
        return const Color(0xFF64748B);
      case CitasEstado.solicitada:
        return const Color(0xFFF59E0B);
      case CitasEstado.programada:
        return const Color(0xFF2563EB);
      case CitasEstado.completada:
        return const Color(0xFF16A34A);
      case CitasEstado.noAsistio:
        return const Color(0xFFEA580C);
      case CitasEstado.cancelada:
        return const Color(0xFFDC2626);
      case CitasEstado.rechazada:
        return const Color(0xFF9333EA);
      case CitasEstado.reprogramada:
        return const Color(0xFF0D9488);
    }
  }

  Color textColor(ThemeController theme) {
    switch (this) {
      case CitasEstado.solicitada:
        return theme.black;
      case CitasEstado.borrador:
      case CitasEstado.programada:
      case CitasEstado.completada:
      case CitasEstado.noAsistio:
      case CitasEstado.cancelada:
      case CitasEstado.rechazada:
      case CitasEstado.reprogramada:
        return theme.white;
    }
  }
}
