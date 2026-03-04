class CitaMedica {
  final String id;
  final String detalle;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final String medicoId;
  final String? medicoNombre;
  final String? pacienteId;
  final String? pacienteNombre;
  final String? pacienteNroDocumento;
  final String? pacienteTelefono;
  final String? pacienteGenero;
  final String? pacienteFechaNacimiento;
  final String? especialidadId;
  final String? especialidadNombre;
  final String? especialidadColorHex;
  final String? especialidadDescripcion;
  final String? lugarId;
  final String? lugarNombre;
  final String? lugarDireccion;
  final String? lugarSigla;
  final String? lugarTipo;
  final String? tipoCita;
  final String? servicioId;
  final String? servicioNombre;
  final String? servicioDescripcion;
  final String? servicioTipo;
  final int? servicioDuracionMinutos;

  const CitaMedica({
    required this.id,
    required this.detalle,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.medicoId,
    required this.medicoNombre,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.pacienteNroDocumento,
    required this.pacienteTelefono,
    required this.pacienteGenero,
    required this.pacienteFechaNacimiento,
    required this.especialidadId,
    required this.especialidadNombre,
    required this.especialidadColorHex,
    required this.especialidadDescripcion,
    required this.lugarId,
    required this.lugarNombre,
    required this.lugarDireccion,
    required this.lugarSigla,
    required this.lugarTipo,
    required this.tipoCita,
    required this.servicioId,
    required this.servicioNombre,
    required this.servicioDescripcion,
    required this.servicioTipo,
    required this.servicioDuracionMinutos,
  });

  factory CitaMedica.fromJson(Map<String, dynamic> jsonRaw) {
    final json = (jsonRaw['datos'] is Map<String, dynamic>)
        ? (jsonRaw['datos'] as Map<String, dynamic>)
        : jsonRaw;
    final especialidadRaw = json['especialidad'];
    final lugarRaw = json['lugar'];
    final servicioRaw = json['servicio'] ?? json['estudio'];
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
    final pacienteId = (json['pacienteId'] ?? json['idPaciente'])?.toString();
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
      pacienteId: (pacienteId?.isNotEmpty ?? false)
          ? pacienteId
          : (pacienteRaw is Map<String, dynamic>
              ? pacienteRaw['id']?.toString()
              : null),
      pacienteNombre:
          (json['pacienteNombre'] ?? json['nombrePaciente'] ?? pacienteNombre)
              ?.toString(),
      pacienteNroDocumento: pacienteRaw is Map<String, dynamic>
          ? pacienteRaw['nroDocumento']?.toString()
          : json['pacienteNroDocumento']?.toString(),
      pacienteTelefono: pacienteRaw is Map<String, dynamic>
          ? pacienteRaw['telefono']?.toString()
          : json['pacienteTelefono']?.toString(),
      pacienteGenero: pacienteRaw is Map<String, dynamic>
          ? pacienteRaw['genero']?.toString()
          : json['pacienteGenero']?.toString(),
      pacienteFechaNacimiento: pacienteRaw is Map<String, dynamic>
          ? pacienteRaw['fechaNacimiento']?.toString()
          : json['pacienteFechaNacimiento']?.toString(),
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
      especialidadDescripcion: especialidadRaw is Map<String, dynamic>
          ? especialidadRaw['descripcion']?.toString()
          : json['especialidadDescripcion']?.toString(),
      especialidadColorHex: (json['especialidadColorHex'] ??
              json['colorHex'] ??
              especialidadColor)
          ?.toString(),
      lugarId: (json['lugarId'] ?? json['idLugar'] ?? '').toString().isNotEmpty
          ? (json['lugarId'] ?? json['idLugar']).toString()
          : (lugarRaw is Map<String, dynamic>
              ? lugarRaw['id']?.toString()
              : null),
      lugarNombre: lugarRaw is Map<String, dynamic>
          ? lugarRaw['nombre']?.toString()
          : json['lugarNombre']?.toString(),
      lugarDireccion: lugarRaw is Map<String, dynamic>
          ? lugarRaw['direccion']?.toString()
          : json['lugarDireccion']?.toString(),
      lugarSigla: lugarRaw is Map<String, dynamic>
          ? lugarRaw['sigla']?.toString()
          : json['lugarSigla']?.toString(),
      lugarTipo: lugarRaw is Map<String, dynamic>
          ? lugarRaw['tipo']?.toString()
          : json['lugarTipo']?.toString(),
      tipoCita: (json['tipoCita'] ?? json['tipo'] ?? '').toString(),
      servicioId:
          (json['servicioId'] ?? json['idServicio'] ?? json['estudioId'] ?? json['idEstudio'] ?? '').toString().isNotEmpty
              ? (json['servicioId'] ?? json['idServicio'] ?? json['estudioId'] ?? json['idEstudio']).toString()
              : (servicioRaw is Map<String, dynamic>
                  ? servicioRaw['id']?.toString()
                  : null),
      servicioNombre: servicioRaw is Map<String, dynamic>
          ? servicioRaw['nombre']?.toString()
          : (json['servicioNombre'] ?? json['estudioNombre'])?.toString(),
      servicioDescripcion: servicioRaw is Map<String, dynamic>
          ? servicioRaw['descripcion']?.toString()
          : json['servicioDescripcion']?.toString(),
      servicioTipo: servicioRaw is Map<String, dynamic>
          ? servicioRaw['tipo']?.toString()
          : json['servicioTipo']?.toString(),
      servicioDuracionMinutos: servicioRaw is Map<String, dynamic>
          ? _parseInt(servicioRaw['duracionMinutos'] ?? servicioRaw['duracion'])
          : _parseInt(json['servicioDuracionMinutos'] ?? json['duracionMinutos']),
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
    String? pacienteId,
    String? pacienteNombre,
    String? pacienteNroDocumento,
    String? pacienteTelefono,
    String? pacienteGenero,
    String? pacienteFechaNacimiento,
    String? especialidadId,
    String? especialidadNombre,
    String? especialidadColorHex,
    String? especialidadDescripcion,
    String? lugarId,
    String? lugarNombre,
    String? lugarDireccion,
    String? lugarSigla,
    String? lugarTipo,
    String? tipoCita,
    String? servicioId,
    String? servicioNombre,
    String? servicioDescripcion,
    String? servicioTipo,
    int? servicioDuracionMinutos,
  }) {
    return CitaMedica(
      id: id ?? this.id,
      detalle: detalle ?? this.detalle,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      medicoId: medicoId ?? this.medicoId,
      medicoNombre: medicoNombre ?? this.medicoNombre,
      pacienteId: pacienteId ?? this.pacienteId,
      pacienteNombre: pacienteNombre ?? this.pacienteNombre,
      pacienteNroDocumento: pacienteNroDocumento ?? this.pacienteNroDocumento,
      pacienteTelefono: pacienteTelefono ?? this.pacienteTelefono,
      pacienteGenero: pacienteGenero ?? this.pacienteGenero,
      pacienteFechaNacimiento:
          pacienteFechaNacimiento ?? this.pacienteFechaNacimiento,
      especialidadId: especialidadId ?? this.especialidadId,
      especialidadNombre: especialidadNombre ?? this.especialidadNombre,
      especialidadColorHex:
          especialidadColorHex ?? this.especialidadColorHex,
      especialidadDescripcion:
          especialidadDescripcion ?? this.especialidadDescripcion,
      lugarId: lugarId ?? this.lugarId,
      lugarNombre: lugarNombre ?? this.lugarNombre,
      lugarDireccion: lugarDireccion ?? this.lugarDireccion,
      lugarSigla: lugarSigla ?? this.lugarSigla,
      lugarTipo: lugarTipo ?? this.lugarTipo,
      tipoCita: tipoCita ?? this.tipoCita,
      servicioId: servicioId ?? this.servicioId,
      servicioNombre: servicioNombre ?? this.servicioNombre,
      servicioDescripcion: servicioDescripcion ?? this.servicioDescripcion,
      servicioTipo: servicioTipo ?? this.servicioTipo,
      servicioDuracionMinutos:
          servicioDuracionMinutos ?? this.servicioDuracionMinutos,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
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
    'BORRADOR',
    'SOLICITADA',
    'CONFIRMADA',
    'COMPLETADA',
    'NO_ASISTIO',
    'CANCELADA',
    'RECHAZADA',
    'REPROGRAMADA',
  ];
}
