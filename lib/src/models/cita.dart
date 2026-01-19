class CitaMedica {
  final String id;
  final String detalle;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final String medicoId;
  final String? medicoNombre;
  final String? pacienteNombre;
  final String? especialidadId;
  final String? especialidadNombre;
  final String? especialidadColorHex;
  final String? tipoCita;
  final String? estudioId;
  final String? estudioNombre;

  const CitaMedica({
    required this.id,
    required this.detalle,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.medicoId,
    required this.medicoNombre,
    required this.pacienteNombre,
    required this.especialidadId,
    required this.especialidadNombre,
    required this.especialidadColorHex,
    required this.tipoCita,
    required this.estudioId,
    required this.estudioNombre,
  });

  factory CitaMedica.fromJson(Map<String, dynamic> jsonRaw) {
    final json = (jsonRaw['datos'] is Map<String, dynamic>)
        ? (jsonRaw['datos'] as Map<String, dynamic>)
        : jsonRaw;
    final especialidadRaw = json['especialidad'];
    final estudioRaw = json['estudio'];
    final medicoRaw = json['medico'];
    final pacienteRaw = json['paciente'];
    final especialidadColor = especialidadRaw is Map<String, dynamic>
        ? especialidadRaw['colorHex']?.toString()
        : null;
    final medicoNombre = medicoRaw is Map<String, dynamic>
        ? [
            medicoRaw['nombres'],
            medicoRaw['primerApellido'],
            medicoRaw['segundoApellido'],
          ].whereType<String>().where((value) => value.trim().isNotEmpty).join(
              ' ',
            )
        : null;
    final pacienteNombre = pacienteRaw is Map<String, dynamic>
        ? [
            pacienteRaw['nombres'],
            pacienteRaw['primerApellido'],
            pacienteRaw['segundoApellido'],
          ].whereType<String>().where((value) => value.trim().isNotEmpty).join(
              ' ',
            )
        : null;

    return CitaMedica(
      id: (json['id'] ?? json['citaId'] ?? '').toString(),
      detalle: (json['detalle'] ?? '').toString(),
      fechaInicio: _parseDate(json['fechaInicio']),
      fechaFin: _parseDate(json['fechaFin']),
      estado: (json['estado'] ?? '').toString(),
      medicoId: (json['medicoId'] ?? json['idMedico'] ?? '').toString(),
      medicoNombre:
          (json['medicoNombre'] ?? json['nombreMedico'] ?? medicoNombre)
              ?.toString(),
      pacienteNombre:
          (json['pacienteNombre'] ?? json['nombrePaciente'] ?? pacienteNombre)
              ?.toString(),
      especialidadId: (json['especialidadId'] ?? json['idEspecialidad'] ?? '')
          .toString()
          .isNotEmpty
          ? (json['especialidadId'] ?? json['idEspecialidad']).toString()
          : (especialidadRaw is Map<String, dynamic>
              ? especialidadRaw['id']?.toString()
              : null),
      especialidadNombre: especialidadRaw is Map<String, dynamic>
          ? especialidadRaw['nombre']?.toString()
          : json['especialidadNombre']?.toString(),
      especialidadColorHex: (json['especialidadColorHex'] ??
              json['colorHex'] ??
              especialidadColor)
          ?.toString(),
      tipoCita: (json['tipoCita'] ?? json['tipo'] ?? '').toString(),
      estudioId:
          (json['estudioId'] ?? json['idEstudio'] ?? '').toString().isNotEmpty
              ? (json['estudioId'] ?? json['idEstudio']).toString()
              : (estudioRaw is Map<String, dynamic>
                  ? estudioRaw['id']?.toString()
                  : null),
      estudioNombre: estudioRaw is Map<String, dynamic>
          ? estudioRaw['nombre']?.toString()
          : json['estudioNombre']?.toString(),
    );
  }

  CitaMedica copyWith({
    String? id,
    String? detalle,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    String? medicoId,
    String? medicoNombre,
    String? pacienteNombre,
    String? especialidadId,
    String? especialidadNombre,
    String? especialidadColorHex,
    String? tipoCita,
    String? estudioId,
    String? estudioNombre,
  }) {
    return CitaMedica(
      id: id ?? this.id,
      detalle: detalle ?? this.detalle,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      medicoId: medicoId ?? this.medicoId,
      medicoNombre: medicoNombre ?? this.medicoNombre,
      pacienteNombre: pacienteNombre ?? this.pacienteNombre,
      especialidadId: especialidadId ?? this.especialidadId,
      especialidadNombre: especialidadNombre ?? this.especialidadNombre,
      especialidadColorHex:
          especialidadColorHex ?? this.especialidadColorHex,
      tipoCita: tipoCita ?? this.tipoCita,
      estudioId: estudioId ?? this.estudioId,
      estudioNombre: estudioNombre ?? this.estudioNombre,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }
}

class CitaEstado {
  static const List<String> values = [
    'INACTIVO',
    'BORRADOR',
    'SOLICITADA',
    'CONFIRMADA',
    'EN_CURSO',
    'COMPLETADA',
    'NO_ASISTIO',
    'CANCELADA',
    'RECHAZADA',
  ];
}
