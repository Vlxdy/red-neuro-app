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

class Servicio {
  final String id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final int duracionMinutos;
  final double costo;
  final String estado;
  final List<EspecialidadResumen> especialidades;

  const Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.tipo = 'ESTUDIO',
    required this.duracionMinutos,
    this.costo = 0,
    required this.estado,
    required this.especialidades,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    final rawDuracion = json['duracionMinutos'] ?? json['duracion'] ?? 0;
    final rawCosto = json['costo'] ?? 0;
    final especialidadesRaw =
        json['especialidades'] ?? json['especialidad'] ?? [];
    return Servicio(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'ESTUDIO').toString(),
      duracionMinutos: rawDuracion is int
          ? rawDuracion
          : int.tryParse(rawDuracion.toString()) ?? 0,
      costo: rawCosto is num
          ? rawCosto.toDouble()
          : double.tryParse(rawCosto.toString()) ?? 0,
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

typedef Estudio = Servicio;
