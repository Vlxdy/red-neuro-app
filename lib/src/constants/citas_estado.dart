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
        return theme.grey.withValues(alpha: 0.6);
      case CitasEstado.solicitada:
        return theme.accent200;
      case CitasEstado.confirmada:
        return theme.success;
      case CitasEstado.completada:
        return theme.primary200;
      case CitasEstado.noAsistio:
        return theme.warning;
      case CitasEstado.cancelada:
        return theme.error;
      case CitasEstado.rechazada:
        return theme.otherAccent;
      case CitasEstado.reprogramada:
        return theme.primary;
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
