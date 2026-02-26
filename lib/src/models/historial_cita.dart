class HistorialCita {
  final String id;
  final String citaId;
  final String estadoAnterior;
  final String rolEjecutor;
  final String idEjecutor;
  final String comentario;
  final List<HistorialCambio> detalleCambios;
  final String ejecutorNombre;
  final DateTime? fechaCreacion;

  const HistorialCita({
    required this.id,
    required this.citaId,
    required this.estadoAnterior,
    required this.rolEjecutor,
    required this.idEjecutor,
    required this.comentario,
    required this.detalleCambios,
    required this.ejecutorNombre,
    required this.fechaCreacion,
  });

  factory HistorialCita.fromJson(Map<String, dynamic> jsonRaw) {
    final ejecutorRaw = jsonRaw['ejecutor'];
    final ejecutorNombre = ejecutorRaw is Map<String, dynamic>
        ? [
            ejecutorRaw['nombres'],
            ejecutorRaw['primerApellido'],
            ejecutorRaw['segundoApellido'],
          ].whereType<String>().where((value) => value.trim().isNotEmpty).join(
              ' ',
            )
        : '';

    return HistorialCita(
      id: (jsonRaw['id'] ?? '').toString(),
      citaId: (jsonRaw['citaId'] ?? '').toString(),
      estadoAnterior: (jsonRaw['estadoAnterior'] ?? '').toString(),
      rolEjecutor: (jsonRaw['rolEjecutor'] ?? '').toString(),
      idEjecutor: (jsonRaw['idEjecutor'] ?? '').toString(),
      comentario: (jsonRaw['comentario'] ?? '').toString(),
      detalleCambios: (jsonRaw['detalleCambios'] is List)
          ? (jsonRaw['detalleCambios'] as List)
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return HistorialCambio.fromJson(item);
                }
                if (item is String) {
                  return HistorialCambio.fromLegacy(item);
                }
                return null;
              })
              .whereType<HistorialCambio>()
              .toList()
          : const [],
      ejecutorNombre: ejecutorNombre,
      fechaCreacion: _parseDate(jsonRaw['fechaCreacion']),
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

class HistorialCambio {
  final String field;
  final String? before;
  final String? after;
  final HistorialDetallePersona? beforeDetalle;
  final HistorialDetallePersona? afterDetalle;
  final HistorialDetalleEstudio? beforeDetalleEstudio;
  final HistorialDetalleEstudio? afterDetalleEstudio;
  final String? rawDetalle;

  const HistorialCambio({
    required this.field,
    this.before,
    this.after,
    this.beforeDetalle,
    this.afterDetalle,
    this.beforeDetalleEstudio,
    this.afterDetalleEstudio,
    this.rawDetalle,
  });

  factory HistorialCambio.fromJson(Map<String, dynamic> json) {
    final field = (json['field'] ?? '').toString();
    final beforeDetalleRaw = json['beforeDetalle'];
    final afterDetalleRaw = json['afterDetalle'];

    HistorialDetallePersona? beforeDetallePersona;
    HistorialDetallePersona? afterDetallePersona;
    HistorialDetalleEstudio? beforeDetalleEstudio;
    HistorialDetalleEstudio? afterDetalleEstudio;

    if (beforeDetalleRaw is Map<String, dynamic>) {
      if (field == 'idServicio' || field == 'idEstudio') {
        beforeDetalleEstudio = HistorialDetalleEstudio.fromJson(
          beforeDetalleRaw,
        );
      } else if (field == 'idMedico' || field == 'idPaciente') {
        beforeDetallePersona = HistorialDetallePersona.fromJson(
          beforeDetalleRaw,
        );
      }
    }

    if (afterDetalleRaw is Map<String, dynamic>) {
      if (field == 'idServicio' || field == 'idEstudio') {
        afterDetalleEstudio = HistorialDetalleEstudio.fromJson(
          afterDetalleRaw,
        );
      } else if (field == 'idMedico' || field == 'idPaciente') {
        afterDetallePersona = HistorialDetallePersona.fromJson(
          afterDetalleRaw,
        );
      }
    }

    return HistorialCambio(
      field: field,
      before: json['before']?.toString(),
      after: json['after']?.toString(),
      beforeDetalle: beforeDetallePersona,
      afterDetalle: afterDetallePersona,
      beforeDetalleEstudio: beforeDetalleEstudio,
      afterDetalleEstudio: afterDetalleEstudio,
    );
  }

  factory HistorialCambio.fromLegacy(String raw) {
    return HistorialCambio(field: '', rawDetalle: raw);
  }
}

class HistorialDetallePersona {
  final String id;
  final String nombres;
  final String? primerApellido;
  final String? segundoApellido;
  final String? nroDocumento;
  final List<String> especialidades;

  const HistorialDetallePersona({
    required this.id,
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
    required this.nroDocumento,
    required this.especialidades,
  });

  factory HistorialDetallePersona.fromJson(Map<String, dynamic> json) {
    final especialidadesRaw = json['especialidades'];
    final especialidades = (especialidadesRaw is List)
        ? especialidadesRaw
            .map((item) {
              if (item is Map<String, dynamic>) {
                return item['nombre']?.toString();
              }
              return item?.toString();
            })
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .toList()
        : <String>[];

    return HistorialDetallePersona(
      id: (json['id'] ?? '').toString(),
      nombres: (json['nombres'] ?? '').toString(),
      primerApellido: json['primerApellido']?.toString(),
      segundoApellido: json['segundoApellido']?.toString(),
      nroDocumento: json['nroDocumento']?.toString(),
      especialidades: especialidades,
    );
  }

  String get nombreCompleto {
    final parts = [
      nombres,
      if ((primerApellido ?? '').trim().isNotEmpty) primerApellido!.trim(),
      if ((segundoApellido ?? '').trim().isNotEmpty) segundoApellido!.trim(),
    ];
    return parts.join(' ').trim();
  }
}

class HistorialDetalleEstudio {
  final String id;
  final String nombre;
  final String? descripcion;
  final int? duracionMinutos;
  final String? estado;

  const HistorialDetalleEstudio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.duracionMinutos,
    required this.estado,
  });

  factory HistorialDetalleEstudio.fromJson(Map<String, dynamic> json) {
    return HistorialDetalleEstudio(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      duracionMinutos: json['duracionMinutos'] is int
          ? json['duracionMinutos'] as int
          : int.tryParse('${json['duracionMinutos']}'),
      estado: json['estado']?.toString(),
    );
  }
}
