class EstudioResumen {
  final String id;
  final String nombre;
  final int duracionMinutos;

  const EstudioResumen({
    required this.id,
    required this.nombre,
    required this.duracionMinutos,
  });

  factory EstudioResumen.fromJson(Map<String, dynamic> json) {
    final rawDuracion = json['duracionMinutos'] ?? json['duracion'] ?? 0;
    return EstudioResumen(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      duracionMinutos: rawDuracion is int
          ? rawDuracion
          : int.tryParse(rawDuracion.toString()) ?? 0,
    );
  }
}

class Especialidad {
  final String id;
  final String nombre;
  final String? descripcion;
  final String estado;
  final String colorHex;
  final List<EstudioResumen> estudios;

  const Especialidad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
    required this.colorHex,
    required this.estudios,
  });

  factory Especialidad.fromJson(Map<String, dynamic> json) {
    final estudiosRaw =
        json['servicios'] ?? json['estudios'] ?? json['study'] ?? [];
    return Especialidad(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      estado: (json['estado'] ?? '').toString(),
      colorHex: (json['colorHex'] ?? '#64748b').toString(),
      estudios: estudiosRaw is List
          ? estudiosRaw
              .whereType<Map<String, dynamic>>()
              .map(EstudioResumen.fromJson)
              .toList()
          : [],
    );
  }
}
