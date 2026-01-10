class EtiquetaCita {
  final String id;
  final String nombre;
  final String colorHex;
  final String estado;

  const EtiquetaCita({
    required this.id,
    required this.nombre,
    required this.colorHex,
    required this.estado,
  });

  factory EtiquetaCita.fromJson(Map<String, dynamic> json) => EtiquetaCita(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        colorHex: (json['colorHex'] ?? '#9ca3af').toString(),
        estado: (json['estado'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'colorHex': colorHex,
        'estado': estado,
      };
}

class AgrupadorCita {
  final String id;
  final String nombre;
  final String? descripcion;
  final String colorHex;
  final String estado;

  const AgrupadorCita({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.colorHex,
    required this.estado,
  });

  factory AgrupadorCita.fromJson(Map<String, dynamic> json) => AgrupadorCita(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        descripcion: json['descripcion']?.toString(),
        colorHex: (json['colorHex'] ?? '#94a3b8').toString(),
        estado: (json['estado'] ?? '').toString(),
      );
}

class CitaMedica {
  final String id;
  final String detalle;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final String medicoId;
  final String? agrupadorId;
  final List<EtiquetaCita> etiquetas;
  final String? comentario;

  const CitaMedica({
    required this.id,
    required this.detalle,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.medicoId,
    required this.agrupadorId,
    required this.etiquetas,
    required this.comentario,
  });

  factory CitaMedica.fromJson(Map<String, dynamic> jsonRaw) {
    final json = (jsonRaw['datos'] is Map<String, dynamic>)
        ? (jsonRaw['datos'] as Map<String, dynamic>)
        : jsonRaw;

    final etiquetasRaw = json['etiquetas'];
    final etiquetas = etiquetasRaw is List
        ? etiquetasRaw
            .whereType<Map<String, dynamic>>()
            .map(EtiquetaCita.fromJson)
            .toList()
        : <EtiquetaCita>[];

    return CitaMedica(
      id: (json['id'] ?? json['citaId'] ?? '').toString(),
      detalle: (json['detalle'] ?? '').toString(),
      fechaInicio: _parseDate(json['fechaInicio']),
      fechaFin: _parseDate(json['fechaFin']),
      estado: (json['estado'] ?? '').toString(),
      medicoId: (json['medicoId'] ?? '').toString(),
      agrupadorId: json['agrupadorId']?.toString(),
      etiquetas: etiquetas,
      comentario: json['comentario']?.toString(),
    );
  }

  CitaMedica copyWith({
    String? id,
    String? detalle,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    String? medicoId,
    String? agrupadorId,
    List<EtiquetaCita>? etiquetas,
    String? comentario,
  }) {
    return CitaMedica(
      id: id ?? this.id,
      detalle: detalle ?? this.detalle,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      medicoId: medicoId ?? this.medicoId,
      agrupadorId: agrupadorId ?? this.agrupadorId,
      etiquetas: etiquetas ?? this.etiquetas,
      comentario: comentario ?? this.comentario,
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
