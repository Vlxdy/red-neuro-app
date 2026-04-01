import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/citas_estado.dart';
import 'package:red_neuro_app/src/models/cita.dart';
import 'package:red_neuro_app/src/models/historial_cita.dart';
import 'package:red_neuro_app/src/models/rol.dart';
import 'package:red_neuro_app/src/utils/role_utils.dart';
import 'package:red_neuro_app/src/ui/pages/citas/widgets/citas_detalle_modal.dart';

class CitasDetalleModalData {
  final String pacienteNombre;
  final String? pacienteDocumento;
  final String? pacienteTelefono;
  final String? pacienteCorreo;
  final String? pacienteGenero;
  final String? pacienteFechaNacimiento;
  final String? pacienteEdad;
  final String etiquetaPrestacion;
  final String? servicioNombre;
  final int? servicioDuracion;
  final String? lugarDisplay;
  final String? lugarTipo;
  final String? lugarDireccion;
  final String personalAsignado;
  final String? personalDocumento;
  final String? personalTelefono;
  final String? personalCorreo;
  final String? personalOcupacion;
  final String personalAvatarUrl;

  const CitasDetalleModalData({
    required this.pacienteNombre,
    required this.pacienteDocumento,
    required this.pacienteTelefono,
    required this.pacienteCorreo,
    required this.pacienteGenero,
    required this.pacienteFechaNacimiento,
    required this.pacienteEdad,
    required this.etiquetaPrestacion,
    required this.servicioNombre,
    required this.servicioDuracion,
    required this.lugarDisplay,
    required this.lugarTipo,
    required this.lugarDireccion,
    required this.personalAsignado,
    required this.personalDocumento,
    required this.personalTelefono,
    required this.personalCorreo,
    required this.personalOcupacion,
    required this.personalAvatarUrl,
  });
}

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
    final estadoNormalizado = estado.trim().toUpperCase();
    final estadoCita = CitasEstado.tryFromValue(estadoNormalizado);
    if (estadoCita != null) return estadoCita.color(theme);
    return theme.grey.withValues(alpha: 0.6);
  }

  static String normalizarRol(String rol) => RoleUtils.normalizeRole(rol);

  static bool tieneRol(String rol, dynamic perfil) =>
      RoleUtils.hasRole(perfil, rol);

  static bool esAdministrador(dynamic perfil) =>
      RoleUtils.hasRole(perfil, RoleUtils.administrador);

  static bool esMedicoAsignado(CitaMedica cita, String idUsuario) {
    final medicoId = cita.medicoId.trim();
    final usuarioActual = idUsuario.trim();
    if (medicoId.isEmpty || usuarioActual.isEmpty) return false;
    return medicoId == usuarioActual;
  }

  static bool puedeGestionarSolicitada(CitaMedica cita, dynamic perfil) {
    return esMedicoAsignado(cita, perfil.idPersonalActivo ?? '') ||
        esAdministrador(perfil);
  }

  static bool puedeEditarCita(CitaMedica cita, {dynamic perfil}) {
    final estado = cita.estado.trim().toUpperCase();
    if (estado == CitasEstado.borrador.value ||
        estado == CitasEstado.rechazada.value) {
      return true;
    }
    if (estado == CitasEstado.programada.value) {
      return RoleUtils.hasRole(perfil, RoleUtils.jefe) ||
          RoleUtils.hasRole(perfil, RoleUtils.coordinador);
    }
    return false;
  }

  static String? valorDetalle(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }


  static CitasDetalleModalPayload construirDetalleModalPayload({
    required CitaMedica cita,
    required ThemeController theme,
    required String titulo,
    required String Function(CitaMedica cita) nombrePaciente,
    required String Function(String? genero) formatearGenero,
    required String Function(String? fechaRaw) formatearFechaPaciente,
    required String Function(String? fechaRaw) calcularEdadPaciente,
    required String Function(String? tipo) etiquetaPrestacion,
    required String Function(CitaMedica cita) nombreMedico,
    required String Function(String? urlFoto) resolveAvatarUrl,
    required String Function(CitaMedica cita) inicialesPersonal,
    required String Function(DateTime? fecha) formatoFechaCita,
    required String Function(DateTime? inicio, DateTime? fin) formatoHorarioCita,
  }) {
    final detalleData = construirDetalleModalData(
      cita: cita,
      nombrePaciente: nombrePaciente,
      formatearGenero: formatearGenero,
      formatearFechaPaciente: formatearFechaPaciente,
      calcularEdadPaciente: calcularEdadPaciente,
      etiquetaPrestacion: etiquetaPrestacion,
      nombreMedico: nombreMedico,
      resolveAvatarUrl: resolveAvatarUrl,
    );

    return CitasDetalleModalPayload(
      titulo: titulo,
      pacienteNombre: detalleData.pacienteNombre,
      pacienteDocumento: detalleData.pacienteDocumento,
      pacienteTelefono: detalleData.pacienteTelefono,
      pacienteCorreo: detalleData.pacienteCorreo,
      pacienteGenero: detalleData.pacienteGenero,
      pacienteFechaNacimiento: detalleData.pacienteFechaNacimiento,
      pacienteEdad: detalleData.pacienteEdad,
      etiquetaPrestacion: detalleData.etiquetaPrestacion,
      servicioNombre: detalleData.servicioNombre,
      servicioDuracion: detalleData.servicioDuracion,
      servicioDescripcion: cita.servicioDescripcion,
      lugarDisplay: detalleData.lugarDisplay,
      lugarTipo: detalleData.lugarTipo,
      lugarDireccion: detalleData.lugarDireccion,
      personalAsignado: detalleData.personalAsignado,
      personalDocumento: detalleData.personalDocumento,
      personalTelefono: detalleData.personalTelefono,
      personalCorreo: detalleData.personalCorreo,
      personalOcupacion: detalleData.personalOcupacion,
      personalAvatarUrl: detalleData.personalAvatarUrl,
      inicialesPersonal: inicialesPersonal(cita),
      fechaCita: formatoFechaCita(cita.fechaInicio),
      horaCita: formatoHorarioCita(cita.fechaInicio, cita.fechaFin),
      detalleCita: cita.detalle,
      estadoColor: colorEstado(cita.estado, theme),
    );
  }

  static CitasDetalleModalData construirDetalleModalData({
    required CitaMedica cita,
    required String Function(CitaMedica cita) nombrePaciente,
    required String Function(String? genero) formatearGenero,
    required String Function(String? fechaRaw) formatearFechaPaciente,
    required String Function(String? fechaRaw) calcularEdadPaciente,
    required String Function(String? tipo) etiquetaPrestacion,
    required String Function(CitaMedica cita) nombreMedico,
    required String Function(String? urlFoto) resolveAvatarUrl,
  }) {
    final pacienteDocumento = valorDetalle(cita.pacienteNroDocumento);
    final pacienteTelefono = valorDetalle(cita.pacienteTelefono);
    final pacienteCorreo = valorDetalle(cita.pacienteCorreoElectronico);
    final pacienteGenero = valorDetalle(formatearGenero(cita.pacienteGenero));
    final pacienteFechaNacimiento =
        valorDetalle(formatearFechaPaciente(cita.pacienteFechaNacimiento));
    final pacienteEdad = valorDetalle(calcularEdadPaciente(cita.pacienteFechaNacimiento));
    final servicioNombre = valorDetalle(cita.servicioNombre ?? cita.servicioId);

    final lugarNombre = valorDetalle(cita.lugarNombre ?? cita.lugarId);
    final lugarSigla = valorDetalle(cita.lugarSigla);
    final lugarDisplay = (lugarSigla != null && lugarNombre != null)
        ? '${lugarSigla.toUpperCase()} • $lugarNombre'
        : lugarNombre;

    return CitasDetalleModalData(
      pacienteNombre: nombrePaciente(cita),
      pacienteDocumento: pacienteDocumento,
      pacienteTelefono: pacienteTelefono,
      pacienteCorreo: pacienteCorreo,
      pacienteGenero: pacienteGenero,
      pacienteFechaNacimiento: pacienteFechaNacimiento,
      pacienteEdad: pacienteEdad,
      etiquetaPrestacion: etiquetaPrestacion(cita.servicioTipo ?? cita.tipoCita),
      servicioNombre: servicioNombre,
      servicioDuracion: cita.servicioDuracionMinutos,
      lugarDisplay: lugarDisplay,
      lugarTipo: valorDetalle(cita.lugarTipo),
      lugarDireccion: valorDetalle(cita.lugarDireccion),
      personalAsignado: nombreMedico(cita),
      personalDocumento: valorDetalle(cita.personalNroDocumento),
      personalTelefono: valorDetalle(cita.personalTelefono),
      personalCorreo: valorDetalle(cita.personalCorreoElectronico),
      personalOcupacion: valorDetalle(cita.personalOcupacion),
      personalAvatarUrl: resolveAvatarUrl(cita.personalUrlFoto),
    );
  }


  static List<CitaDetalleAccion> construirAccionesDetalleCita({
    required CitaMedica cita,
    required bool Function(CitaMedica cita) puedeGestionarSolicitada,
    required bool Function(CitaMedica cita) puedeEditarCita,
    required bool Function(CitaMedica cita) citaYaIniciada,
    required Future<bool> Function(CitaMedica cita) confirmarCitaSolicitada,
    required Future<bool> Function(CitaMedica cita) rechazarCitaSolicitada,
    required Future<void> Function(CitaMedica cita) completarCita,
    required Future<void> Function(CitaMedica cita) programarControl,
    required Future<void> Function(CitaMedica cita) marcarNoAsistioCita,
    required Future<void> Function(CitaMedica cita) reprogramarCita,
    required Future<void> Function(CitaMedica cita) cancelarCita,
    required Future<void> Function(CitaMedica cita) eliminarBorrador,
    required Future<void> Function(CitaMedica cita) abrirFormulario,
  }) {
    return <CitaDetalleAccion>[
      if (cita.estado == CitasEstado.solicitada.value && puedeGestionarSolicitada(cita))
        CitaDetalleAccion(
          label: 'Confirmar',
          icon: Icons.check_circle_outline,
          isPrimary: true,
          onTap: () => confirmarCitaSolicitada(cita),
        ),
      if (puedeEditarCita(cita))
        CitaDetalleAccion(
          label: cita.estado == CitasEstado.programada.value
              ? 'Modificar cita'
              : 'Editar',
          icon: Icons.edit_outlined,
          onTap: () async {
            await abrirFormulario(cita);
            return true;
          },
        ),
      if (cita.estado == CitasEstado.solicitada.value && puedeGestionarSolicitada(cita))
        CitaDetalleAccion(
          label: 'Rechazar',
          icon: Icons.block_outlined,
          isDestructive: true,
          onTap: () => rechazarCitaSolicitada(cita),
        ),
      if (cita.estado == CitasEstado.programada.value && citaYaIniciada(cita))
        CitaDetalleAccion(
          label: 'Dar alta',
          icon: Icons.task_alt_outlined,
          isPrimary: true,
          onTap: () async {
            await completarCita(cita);
            return true;
          },
        ),
      if (cita.estado == CitasEstado.programada.value && citaYaIniciada(cita))
        CitaDetalleAccion(
          label: 'Programar control',
          icon: Icons.event_repeat_outlined,
          onTap: () async {
            await programarControl(cita);
            return true;
          },
        ),
      if (cita.estado == CitasEstado.programada.value && citaYaIniciada(cita))
        CitaDetalleAccion(
          label: 'No asistió',
          icon: Icons.person_off_outlined,
          onTap: () async {
            await marcarNoAsistioCita(cita);
            return true;
          },
        ),
      if (cita.estado == CitasEstado.cancelada.value ||
          cita.estado == CitasEstado.noAsistio.value)
        CitaDetalleAccion(
          label: 'Reprogramar',
          icon: Icons.schedule_outlined,
          onTap: () async {
            await reprogramarCita(cita);
            return true;
          },
        ),
      if (cita.estado == CitasEstado.programada.value)
        CitaDetalleAccion(
          label: 'Cancelar',
          icon: Icons.cancel_outlined,
          isDestructive: true,
          onTap: () async {
            await cancelarCita(cita);
            return true;
          },
        ),
      if (cita.estado == CitasEstado.borrador.value)
        CitaDetalleAccion(
          label: 'Eliminar borrador',
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: () async {
            await eliminarBorrador(cita);
            return true;
          },
        ),
    ];
  }

  static CitasModalDestino resolverDestinoModalCita({
    required CitaMedica cita,
    required dynamic perfil,
  }) {
    final estado = cita.estado.trim().toUpperCase();

    if (estado == CitasEstado.solicitada.value) {
      // En SOLICITADA siempre debe abrirse el detalle.
      // Las acciones se controlan dentro del modal por permisos.
      return CitasModalDestino.detalle;
    }

    if (estado == CitasEstado.programada.value) {
      // En PROGRAMADA siempre abrir detalle para mostrar acción explícita
      // "Modificar cita" y el resto de acciones de gestión.
      return CitasModalDestino.detalle;
    }

    if (puedeEditarCita(cita, perfil: perfil)) {
      return CitasModalDestino.formulario;
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
