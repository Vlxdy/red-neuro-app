import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/models/historial_cita.dart';



enum CitasModalDestino { detalle, formulario }

class CitasUtils {
  static const Map<String, String> _historialLabels = {
    'fechaInicio': 'Fecha inicio',
    'fechaFin': 'Fecha fin',
    'detalle': 'Detalle',
    'estado': 'Estado',
    'tipoCita': 'Tipo de cita',
    'esEstudio': 'Tipo de cita',
    'idPersonal': 'Personal asignado',
    'idPaciente': 'Paciente',
    'idConsultorio': 'Consultorio',
    'idLugar': 'Lugar',
    'idServicio': 'Servicio',
    'idEstudio': 'Servicio',
  };

  static Color colorEstado(String estado, ThemeController theme) {
    switch (estado) {
      case 'BORRADOR':
        return theme.grey.withValues(alpha: 0.75);
      case 'SOLICITADA':
        return theme.accent500;
      case 'CONFIRMADA':
        return theme.primary;
      case 'COMPLETADA':
        return theme.success;
      case 'NO_ASISTIO':
        return theme.warning;
      case 'CANCELADA':
        return theme.error;
      case 'RECHAZADA':
        return theme.accent500;
      case 'REPROGRAMADA':
        return const Color(0xFF8E7CC3);
      default:
        return theme.grey.withValues(alpha: 0.6);
    }
  }

  static String normalizarRol(String rol) {
    final normalized = rol.toUpperCase();
    switch (normalized) {
      case 'ADMIN':
        return 'ADMINISTRADOR';
      case 'MEDICO':
      case 'PERSONAL_MEDICO':
      case 'SUPERVISOR':
        return 'PERSONAL_SALUD';
      default:
        return normalized;
    }
  }

  static bool tieneRol(String rol, dynamic perfil) {
    final normalized = normalizarRol(rol);
    final roles = <String>{};
    if ((perfil.rol ?? '').trim().isNotEmpty) {
      roles.add(normalizarRol(perfil.rol!));
    }
    roles.addAll(
      perfil.roles
          .map((rolItem) => normalizarRol(rolItem.rol))
          .where((rolItem) => rolItem.trim().isNotEmpty),
    );
    return roles.contains(normalized);
  }

  static bool esAdministrador(dynamic perfil) => tieneRol('ADMINISTRADOR', perfil);

  static bool esMedicoAsignado(CitaMedica cita, String idUsuarioRol) {
    final medicoId = cita.medicoId.trim();
    final usuarioRol = idUsuarioRol.trim();
    if (medicoId.isEmpty || usuarioRol.isEmpty) return false;
    return medicoId == usuarioRol;
  }

  static bool puedeGestionarSolicitada(CitaMedica cita, dynamic perfil) {
    return esMedicoAsignado(cita, perfil.idUsuarioRol ?? '') ||
        esAdministrador(perfil);
  }

  static bool puedeEditarCita(CitaMedica cita) {
    final estado = cita.estado.trim().toUpperCase();
    return estado == 'BORRADOR' || estado == 'RECHAZADA';
  }

  static CitasModalDestino resolverDestinoModalCita({
    required CitaMedica cita,
    required dynamic perfil,
  }) {
    final estado = cita.estado.trim().toUpperCase();

    if (puedeEditarCita(cita)) {
      return CitasModalDestino.formulario;
    }

    if (estado == 'SOLICITADA') {
      // La solicitada siempre puede abrir detalle informativo.
      // Los permisos impactan acciones internas, no la apertura del modal.
      return CitasModalDestino.detalle;
    }

    return CitasModalDestino.detalle;
  }

  static String formatoFechaHoraHistorial(DateTime? fecha, DateFormat formatter) {
    if (fecha == null) return '--';
    return formatter.format(fecha);
  }

  static String tituloHistorial(HistorialCita item) {
    final rol = item.rolEjecutor.trim();
    final tieneCambios = item.detalleCambios.isNotEmpty;
    if (tieneCambios) return 'Actualización de cita';
    if (item.estadoAnterior.trim().isNotEmpty) return 'Cambio de estado';
    if (rol.isEmpty || RegExp(r'^\d+$').hasMatch(rol)) return 'Registro de cita';
    return 'Acción de $rol';
  }

  static String normalizarValorHistorial(String raw, DateFormat dateTimeFormat) {
    var value = raw.trim();
    if (value.startsWith('{') && value.endsWith('}')) {
      value = value.substring(1, value.length - 1);
    }
    value = value.replaceAll('undefined', '').replaceAll('null', '').trim();
    if (value.isEmpty) return '--';
    if (value == 'true') return 'Sí';
    if (value == 'false') return 'No';
    final isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}');
    if (isoPattern.hasMatch(value)) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return dateTimeFormat.format(parsed.toLocal());
    }
    return value;
  }

  static String formatearCambioId({
    required String label,
    required String before,
    required String after,
  }) {
    final antes = before == '--' ? '' : before;
    final despues = after == '--' ? '' : after;
    if (antes.isEmpty && despues.isNotEmpty) return '$label asignado';
    if (antes.isNotEmpty && despues.isEmpty) return '$label removido';
    return '$label actualizado';
  }

  static String formatearTipoCita(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'ESTUDIO') return 'Estudio';
    if (normalized == 'CONSULTA') return 'Consulta';
    return value;
  }

  static String formatearDetallePersona(HistorialDetallePersona detalle) {
    final parts = <String>[
      if (detalle.nombreCompleto.trim().isNotEmpty) detalle.nombreCompleto,
      if ((detalle.nroDocumento ?? '').trim().isNotEmpty)
        detalle.nroDocumento!.trim(),
      if (detalle.ocupaciones.isNotEmpty) detalle.ocupaciones.join(', '),
    ];
    return parts.isEmpty ? '--' : parts.join(' · ');
  }

  static String formatearCambioPersona({
    required String label,
    required String beforeValue,
    required String afterValue,
    HistorialDetallePersona? beforeDetalle,
    HistorialDetallePersona? afterDetalle,
  }) {
    final antes =
        beforeDetalle != null ? formatearDetallePersona(beforeDetalle) : beforeValue;
    final despues =
        afterDetalle != null ? formatearDetallePersona(afterDetalle) : afterValue;
    final antesNormalizado = antes == '--' ? '' : antes;
    final despuesNormalizado = despues == '--' ? '' : despues;

    if (antesNormalizado.isEmpty && despuesNormalizado.isNotEmpty) {
      return '$label asignado: $despuesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isEmpty) {
      return '$label removido: $antesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isNotEmpty) {
      return '$label: $antesNormalizado → $despuesNormalizado';
    }
    return 'Actualización de $label';
  }

  static String formatearDetalleServicio(HistorialDetalleEstudio detalle) {
    final nombre = detalle.nombre.trim();
    return nombre.isNotEmpty ? nombre : '--';
  }

  static String formatearCambioServicio({
    required String label,
    required String beforeValue,
    required String afterValue,
    HistorialDetalleEstudio? beforeDetalle,
    HistorialDetalleEstudio? afterDetalle,
  }) {
    final antes =
        beforeDetalle != null ? formatearDetalleServicio(beforeDetalle) : beforeValue;
    final despues =
        afterDetalle != null ? formatearDetalleServicio(afterDetalle) : afterValue;
    final antesNormalizado = antes == '--' ? '' : antes;
    final despuesNormalizado = despues == '--' ? '' : despues;

    if (antesNormalizado.isEmpty && despuesNormalizado.isNotEmpty) {
      return '$label asignado: $despuesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isEmpty) {
      return '$label removido: $antesNormalizado';
    }
    if (antesNormalizado.isNotEmpty && despuesNormalizado.isNotEmpty) {
      return '$label: $antesNormalizado → $despuesNormalizado';
    }
    return 'Actualización de $label';
  }

  static String? formatearDetalleCambioLegacy(String raw, DateFormat dateTimeFormat) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.contains('field:')) return trimmed.contains('{') ? null : trimmed;

    final fieldMatch = RegExp(r'field:\s*([a-zA-Z0-9_]+)').firstMatch(trimmed);
    final field = fieldMatch?.group(1) ?? '';
    if (field.isEmpty) return null;
    final esIdRelacionado = field.toLowerCase().endsWith('id');

    final label = _historialLabels[field] ?? field;
    final beforeMatch = RegExp(r'before:\s*([^,}]+)').firstMatch(trimmed);
    final afterMatch = RegExp(r'after:\s*([^,}]+)').firstMatch(trimmed);
    final beforeValue = beforeMatch != null
        ? normalizarValorHistorial(beforeMatch.group(1)!, dateTimeFormat)
        : '';
    final afterValue = afterMatch != null
        ? normalizarValorHistorial(afterMatch.group(1)!, dateTimeFormat)
        : '';

    if (esIdRelacionado) {
      return formatearCambioId(label: label, before: beforeValue, after: afterValue);
    }
    if (field == 'tipoCita') {
      return '$label: ${formatearTipoCita(beforeValue)} → ${formatearTipoCita(afterValue)}';
    }
    if (beforeValue.isNotEmpty && afterValue.isNotEmpty) {
      return '$label: $beforeValue → $afterValue';
    }
    return 'Actualización de $label';
  }

  static String? formatearDetalleCambio(HistorialCambio cambio, DateFormat dateTimeFormat) {
    if (cambio.rawDetalle != null) {
      return formatearDetalleCambioLegacy(cambio.rawDetalle!, dateTimeFormat);
    }
    final field = cambio.field.trim();
    if (field.isEmpty) return null;
    final esIdRelacionado = field.toLowerCase().endsWith('id');

    final label = _historialLabels[field] ?? field;
    final beforeValue = normalizarValorHistorial(cambio.before ?? '', dateTimeFormat);
    final afterValue = normalizarValorHistorial(cambio.after ?? '', dateTimeFormat);

    if (field == 'idPersonal' || field == 'idPaciente') {
      return formatearCambioPersona(
        label: label,
        beforeValue: beforeValue,
        afterValue: afterValue,
        beforeDetalle: cambio.beforeDetalle,
        afterDetalle: cambio.afterDetalle,
      );
    }
    if (field == 'idServicio' || field == 'idEstudio') {
      return formatearCambioServicio(
        label: label,
        beforeValue: beforeValue,
        afterValue: afterValue,
        beforeDetalle: cambio.beforeDetalleEstudio,
        afterDetalle: cambio.afterDetalleEstudio,
      );
    }
    if (esIdRelacionado) {
      return formatearCambioId(label: label, before: beforeValue, after: afterValue);
    }
    if (field == 'tipoCita') {
      return '$label: ${formatearTipoCita(beforeValue)} → ${formatearTipoCita(afterValue)}';
    }
    if (beforeValue.isNotEmpty && afterValue.isNotEmpty) {
      return '$label: $beforeValue → $afterValue';
    }
    return 'Actualización de $label';
  }

  static DateTime inicioDia(DateTime date) => DateTime(date.year, date.month, date.day);

  static DateTime finDia(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);
}
