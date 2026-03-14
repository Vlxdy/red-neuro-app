class CitaMedica {
  final String id;
  final String detalle;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final String idPersonal;
  final String? personalNombre;
  final String? personalNroDocumento;
  final String? personalTelefono;
  final String? personalCorreoElectronico;
  final String? personalGenero;
  final String? personalFechaNacimiento;
  final String? personalUrlFoto;
  final String? personalOcupacion;
  final String? pacienteId;
  final String? pacienteNombre;
  final String? pacienteNroDocumento;
  final String? pacienteTelefono;
  final String? pacienteCorreoElectronico;
  final String? pacienteGenero;
  final String? pacienteFechaNacimiento;
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
  final String? idUsuarioProgramo;

  String get medicoId => idPersonal;
  String? get medicoNombre => personalNombre;

  @Deprecated('Las citas ya no están vinculadas a ocupación/ocupacion')
  String? get ocupacionId => null;

  @Deprecated('Las citas ya no están vinculadas a ocupación/ocupacion')
  String? get ocupacionNombre => null;

  @Deprecated('Las citas ya no están vinculadas a ocupación/ocupacion')
  String? get ocupacionColorHex => null;

  @Deprecated('Las citas ya no están vinculadas a ocupación/ocupacion')
  String? get ocupacionDescripcion => null;

  const CitaMedica({
    required this.id,
    required this.detalle,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.idPersonal,
    required this.personalNombre,
    required this.personalNroDocumento,
    required this.personalTelefono,
    required this.personalCorreoElectronico,
    required this.personalGenero,
    required this.personalFechaNacimiento,
    required this.personalUrlFoto,
    required this.personalOcupacion,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.pacienteNroDocumento,
    required this.pacienteTelefono,
    required this.pacienteCorreoElectronico,
    required this.pacienteGenero,
    required this.pacienteFechaNacimiento,
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
    required this.idUsuarioProgramo,
  });

  factory CitaMedica.fromJson(Map<String, dynamic> jsonRaw) {
    final json = (jsonRaw['datos'] is Map<String, dynamic>)
        ? (jsonRaw['datos'] as Map<String, dynamic>)
        : jsonRaw;
    final lugarRaw = json['lugar'];
    final servicioRaw = json['servicio'] ?? json['estudio'];
    final personalRaw = json['personal'] ?? json['medico'];
    final personalPersonaRaw = personalRaw is Map<String, dynamic>
        ? personalRaw['persona']
        : null;
    final pacienteRaw = json['paciente'];
    final personalNombre = personalRaw is Map<String, dynamic>
        ? [
            personalRaw['nombres'],
            personalRaw['primerApellido'],
            personalRaw['segundoApellido'],
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

    String? _personalField(String key) {
      if (personalRaw is Map<String, dynamic>) {
        final value = personalRaw[key] ??
            (personalPersonaRaw is Map<String, dynamic>
                ? personalPersonaRaw[key]
                : null);
        if (value == null) return null;
        final text = value.toString().trim();
        return text.isEmpty ? null : text;
      }
      return null;
    }

    return CitaMedica(
      id: (json['id'] ?? json['citaId'] ?? '').toString(),
      detalle: (json['detalle'] ?? '').toString(),
      fechaInicio: _parseDate(json['fechaInicio']),
      fechaFin: _parseDate(json['fechaFin']),
      estado: (json['estado'] ?? '').toString(),
      idPersonal: (json['idPersonal'] ?? json['medicoId'] ?? json['idMedico'] ?? '').toString(),
      personalNombre:
          (json['personalNombre'] ?? json['medicoNombre'] ?? json['nombreMedico'] ?? personalNombre)
              ?.toString(),
      personalNroDocumento:
          (json['personalNroDocumento'] ?? _personalField('nroDocumento'))
              ?.toString(),
      personalTelefono:
          (json['personalTelefono'] ?? _personalField('telefono'))?.toString(),
      personalCorreoElectronico:
          (json['personalCorreoElectronico'] ??
                  json['personalCorreo'] ??
                  _personalField('correoElectronico'))
              ?.toString(),
      personalGenero:
          (json['personalGenero'] ?? _personalField('genero'))?.toString(),
      personalFechaNacimiento:
          (json['personalFechaNacimiento'] ?? _personalField('fechaNacimiento'))
              ?.toString(),
      personalUrlFoto:
          (json['personalUrlFoto'] ?? _personalField('urlFoto'))?.toString(),
      personalOcupacion:
          (json['personalOcupacion'] ?? _personalField('ocupacion'))
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
      pacienteCorreoElectronico: pacienteRaw is Map<String, dynamic>
          ? (pacienteRaw['correoElectronico'] ?? pacienteRaw['correo'])?.toString()
          : (json['pacienteCorreoElectronico'] ?? json['pacienteCorreo'])?.toString(),
      pacienteGenero: pacienteRaw is Map<String, dynamic>
          ? pacienteRaw['genero']?.toString()
          : json['pacienteGenero']?.toString(),
      pacienteFechaNacimiento: pacienteRaw is Map<String, dynamic>
          ? pacienteRaw['fechaNacimiento']?.toString()
          : json['pacienteFechaNacimiento']?.toString(),
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
      idUsuarioProgramo:
          (json['idUsuarioProgramo'] ?? json['usuarioProgramoId'] ?? json['creadoPor'] ?? json['createdBy'])?.toString(),
    );
  }

  CitaMedica copyWith({
    String? id,
    String? detalle,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    String? idPersonal,
    String? personalNombre,
    String? personalNroDocumento,
    String? personalTelefono,
    String? personalCorreoElectronico,
    String? personalGenero,
    String? personalFechaNacimiento,
    String? personalUrlFoto,
    String? personalOcupacion,
    String? pacienteId,
    String? pacienteNombre,
    String? pacienteNroDocumento,
    String? pacienteTelefono,
    String? pacienteCorreoElectronico,
    String? pacienteGenero,
    String? pacienteFechaNacimiento,
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
    String? idUsuarioProgramo,
  }) {
    return CitaMedica(
      id: id ?? this.id,
      detalle: detalle ?? this.detalle,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      idPersonal: idPersonal ?? this.idPersonal,
      personalNombre: personalNombre ?? this.personalNombre,
      personalNroDocumento: personalNroDocumento ?? this.personalNroDocumento,
      personalTelefono: personalTelefono ?? this.personalTelefono,
      personalCorreoElectronico:
          personalCorreoElectronico ?? this.personalCorreoElectronico,
      personalGenero: personalGenero ?? this.personalGenero,
      personalFechaNacimiento:
          personalFechaNacimiento ?? this.personalFechaNacimiento,
      personalUrlFoto: personalUrlFoto ?? this.personalUrlFoto,
      personalOcupacion: personalOcupacion ?? this.personalOcupacion,
      pacienteId: pacienteId ?? this.pacienteId,
      pacienteNombre: pacienteNombre ?? this.pacienteNombre,
      pacienteNroDocumento: pacienteNroDocumento ?? this.pacienteNroDocumento,
      pacienteTelefono: pacienteTelefono ?? this.pacienteTelefono,
      pacienteCorreoElectronico:
          pacienteCorreoElectronico ?? this.pacienteCorreoElectronico,
      pacienteGenero: pacienteGenero ?? this.pacienteGenero,
      pacienteFechaNacimiento:
          pacienteFechaNacimiento ?? this.pacienteFechaNacimiento,
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
      idUsuarioProgramo: idUsuarioProgramo ?? this.idUsuarioProgramo,
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
