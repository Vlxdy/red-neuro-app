import 'package:red_neuro_app/src/models/cita.dart';

class PagoConCitaResumen {
  final String id;
  final double monto;
  final String estadoPago;
  final String metodoPago;
  final String tipoMovimiento;
  final DateTime? fechaPago;
  final String observacion;
  final String usuarioRegistroId;
  final String usuarioRegistroNombre;
  final String? usuarioRegistroAvatarUrl;
  final String pacienteNombre;
  final String? pacienteAvatarUrl;
  final String personalNombre;
  final String? personalAvatarUrl;
  final CitaMedica cita;

  const PagoConCitaResumen({
    required this.id,
    required this.monto,
    required this.estadoPago,
    required this.metodoPago,
    required this.tipoMovimiento,
    required this.fechaPago,
    required this.observacion,
    required this.usuarioRegistroId,
    required this.usuarioRegistroNombre,
    required this.usuarioRegistroAvatarUrl,
    required this.pacienteNombre,
    required this.pacienteAvatarUrl,
    required this.personalNombre,
    required this.personalAvatarUrl,
    required this.cita,
  });

  factory PagoConCitaResumen.fromJson(Map<String, dynamic> jsonRaw) {
    final json = (jsonRaw['datos'] is Map<String, dynamic>)
        ? (jsonRaw['datos'] as Map<String, dynamic>)
        : jsonRaw;

    final citaRaw = (json['cita'] is Map<String, dynamic>)
        ? (json['cita'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final usuarioRegistroRaw = (json['usuarioRegistro'] is Map<String, dynamic>)
        ? (json['usuarioRegistro'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final pacienteRaw = (citaRaw['paciente'] is Map<String, dynamic>)
        ? (citaRaw['paciente'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final personalRaw = (citaRaw['personal'] is Map<String, dynamic>)
        ? (citaRaw['personal'] as Map<String, dynamic>)
        : <String, dynamic>{};

    return PagoConCitaResumen(
      id: '${json['id'] ?? ''}',
      monto: _parseDouble(json['monto']),
      estadoPago: '${json['estadoPago'] ?? '-'}',
      metodoPago: '${json['metodoPago'] ?? '-'}',
      tipoMovimiento: '${json['tipoMovimiento'] ?? '-'}',
      fechaPago: _parseDate(json['fechaPago']),
      observacion: '${json['observacion'] ?? ''}',
      usuarioRegistroId: '${usuarioRegistroRaw['id'] ?? ''}',
      usuarioRegistroNombre: _nombreCompleto(usuarioRegistroRaw),
      usuarioRegistroAvatarUrl: _stringOrNull(usuarioRegistroRaw['urlFoto']),
      pacienteNombre: _nombreCompleto(pacienteRaw),
      pacienteAvatarUrl: _stringOrNull(pacienteRaw['urlFoto']),
      personalNombre: _nombreCompleto(personalRaw),
      personalAvatarUrl: _stringOrNull(personalRaw['urlFoto']),
      cita: CitaMedica.fromJson(_normalizarCita(citaRaw)),
    );
  }

  factory PagoConCitaResumen.fromAnyJson(Map<String, dynamic> jsonRaw) {
    final json = (jsonRaw['datos'] is Map<String, dynamic>)
        ? (jsonRaw['datos'] as Map<String, dynamic>)
        : jsonRaw;
    final hasPagoShape = json.containsKey('estadoPago') ||
        json.containsKey('monto') ||
        json.containsKey('metodoPago') ||
        json.containsKey('cita');
    if (hasPagoShape) return PagoConCitaResumen.fromJson(jsonRaw);
    return PagoConCitaResumen.fromLegacyCita(jsonRaw);
  }

  factory PagoConCitaResumen.fromLegacyCita(Map<String, dynamic> jsonRaw) {
    final cita = CitaMedica.fromJson(jsonRaw);
    final usuarioRaw = (jsonRaw['usuarioProgramo'] is Map<String, dynamic>)
        ? (jsonRaw['usuarioProgramo'] as Map<String, dynamic>)
        : (jsonRaw['usuarioEnvio'] is Map<String, dynamic>)
            ? (jsonRaw['usuarioEnvio'] as Map<String, dynamic>)
            : (jsonRaw['personal'] is Map<String, dynamic>)
                ? (jsonRaw['personal'] as Map<String, dynamic>)
                : <String, dynamic>{};
    final pacienteRaw = (jsonRaw['paciente'] is Map<String, dynamic>)
        ? (jsonRaw['paciente'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final personalRaw = (jsonRaw['personal'] is Map<String, dynamic>)
        ? (jsonRaw['personal'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final servicioRaw = (jsonRaw['servicio'] is Map<String, dynamic>)
        ? (jsonRaw['servicio'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final monto = _parseDouble(
      jsonRaw['monto'] ??
          jsonRaw['montoServicio'] ??
          servicioRaw['costo'] ??
          servicioRaw['precio'] ??
          servicioRaw['monto'],
    );

    return PagoConCitaResumen(
      id: '${jsonRaw['idPago'] ?? jsonRaw['pagoId'] ?? jsonRaw['id'] ?? ''}',
      monto: monto,
      estadoPago: '${jsonRaw['estadoPago'] ?? 'PENDIENTE'}',
      metodoPago: '${jsonRaw['metodoPago'] ?? '-'}',
      tipoMovimiento: '${jsonRaw['tipoMovimiento'] ?? 'PAGO'}',
      fechaPago: _parseDate(jsonRaw['fechaPago']) ?? cita.fechaFin ?? cita.fechaInicio,
      observacion: '${jsonRaw['observacion'] ?? ''}',
      usuarioRegistroId: '${usuarioRaw['id'] ?? ''}',
      usuarioRegistroNombre: _nombreCompleto(usuarioRaw),
      usuarioRegistroAvatarUrl: _stringOrNull(usuarioRaw['urlFoto']),
      pacienteNombre: _nombreCompleto(pacienteRaw),
      pacienteAvatarUrl: _stringOrNull(pacienteRaw['urlFoto']),
      personalNombre: _nombreCompleto(personalRaw),
      personalAvatarUrl: _stringOrNull(personalRaw['urlFoto']),
      cita: cita,
    );
  }

  static Map<String, dynamic> _normalizarCita(Map<String, dynamic> citaRaw) {
    return {
      ...citaRaw,
      'id': citaRaw['id'],
      'detalle': citaRaw['detalle'],
      'fechaInicio': citaRaw['fechaInicio'],
      'fechaFin': citaRaw['fechaFin'],
      'estado': citaRaw['estado'],
      'tipoCita': citaRaw['tipoCita'],
      'pacienteId': (citaRaw['paciente'] is Map<String, dynamic>)
          ? (citaRaw['paciente'] as Map<String, dynamic>)['id']
          : null,
      'pacienteNombre': (citaRaw['paciente'] is Map<String, dynamic>)
          ? _nombreCompleto(citaRaw['paciente'] as Map<String, dynamic>)
          : null,
      'idPersonal': (citaRaw['personal'] is Map<String, dynamic>)
          ? (citaRaw['personal'] as Map<String, dynamic>)['id']
          : null,
      'personalNombre': (citaRaw['personal'] is Map<String, dynamic>)
          ? _nombreCompleto(citaRaw['personal'] as Map<String, dynamic>)
          : null,
      'personalUrlFoto': (citaRaw['personal'] is Map<String, dynamic>)
          ? (citaRaw['personal'] as Map<String, dynamic>)['urlFoto']
          : null,
      'servicioId': (citaRaw['servicio'] is Map<String, dynamic>)
          ? (citaRaw['servicio'] as Map<String, dynamic>)['id']
          : null,
      'servicioNombre': (citaRaw['servicio'] is Map<String, dynamic>)
          ? (citaRaw['servicio'] as Map<String, dynamic>)['nombre']
          : null,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _nombreCompleto(Map<String, dynamic> data) {
    final nombreCompleto = _stringOrNull(data['nombreCompleto']);
    if (nombreCompleto != null && nombreCompleto.trim().isNotEmpty) return nombreCompleto.trim();

    final parts = [
      _stringOrNull(data['nombres']),
      _stringOrNull(data['primerApellido']),
      _stringOrNull(data['segundoApellido']),
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(' ');
    return '-';
  }

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}
