class EspecialidadResumen {
  final String id;
  final String nombre;
  final String colorHex;

  const EspecialidadResumen({
    required this.id,
    required this.nombre,
    required this.colorHex,
  });

  factory EspecialidadResumen.fromJson(Map<String, dynamic> json) {
    return EspecialidadResumen(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      colorHex: (json['colorHex'] ?? '#64748b').toString(),
    );
  }
}

class Estudio {
  final String id;
  final String nombre;
  final String descripcion;
  final int duracionMinutos;
  final String estado;
  final List<EspecialidadResumen> especialidades;

  const Estudio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.duracionMinutos,
    required this.estado,
    required this.especialidades,
  });

  factory Estudio.fromJson(Map<String, dynamic> json) {
    final rawDuracion = json['duracionMinutos'] ?? json['duracion'] ?? 0;
    final especialidadesRaw =
        json['especialidades'] ?? json['especialidad'] ?? [];
    return Estudio(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      duracionMinutos: rawDuracion is int
          ? rawDuracion
          : int.tryParse(rawDuracion.toString()) ?? 0,
      estado: (json['estado'] ?? '').toString(),
      especialidades: especialidadesRaw is List
          ? especialidadesRaw
              .whereType<Map<String, dynamic>>()
              .map(EspecialidadResumen.fromJson)
              .toList()
          : [],
    );
  }
}
