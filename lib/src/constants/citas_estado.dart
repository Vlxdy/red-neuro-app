import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

enum CitasEstado {
  borrador('BORRADOR'),
  solicitada('SOLICITADA'),
  confirmada('CONFIRMADA'),
  completada('COMPLETADA'),
  noAsistio('NO_ASISTIO'),
  cancelada('CANCELADA'),
  rechazada('RECHAZADA'),
  reprogramada('REPROGRAMADA');

  final String value;
  const CitasEstado(this.value);

  static CitasEstado fromValue(String? value) {
    return CitasEstado.values.firstWhere(
      (estado) => estado.value == value,
      orElse: () => CitasEstado.borrador,
    );
  }

  String get label {
    switch (this) {
      case CitasEstado.borrador:
        return 'Borrador';
      case CitasEstado.solicitada:
        return 'Solicitada';
      case CitasEstado.confirmada:
        return 'Confirmada';
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
      case CitasEstado.confirmada:
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
      case CitasEstado.confirmada:
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
