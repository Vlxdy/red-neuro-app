class OcupacionResumen {
  final String id;
  final String nombre;
  final String? grado;

  const OcupacionResumen({
    required this.id,
    required this.nombre,
    required this.grado,
  });

  factory OcupacionResumen.fromJson(Map<String, dynamic> json) {
    return OcupacionResumen(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      grado: json['grado']?.toString(),
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
  final List<OcupacionResumen> ocupaciones;

  const Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.tipo = 'ESTUDIO',
    required this.duracionMinutos,
    this.costo = 0,
    required this.estado,
    required this.ocupaciones,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    final rawDuracion = json['duracionMinutos'] ?? json['duracion'] ?? 0;
    final rawCosto = json['costo'] ?? 0;
    final ocupacionesRaw =
        json['ocupaciones'] ?? json['ocupacion'] ?? [];
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
      ocupaciones: ocupacionesRaw is List
          ? ocupacionesRaw
              .whereType<Map<String, dynamic>>()
              .map(OcupacionResumen.fromJson)
              .toList()
          : [],
    );
  }
}

typedef Estudio = Servicio;
