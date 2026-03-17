class CategoriaResumen {
  final String id;
  final String nombre;
  final String? colorHex;

  const CategoriaResumen({
    required this.id,
    required this.nombre,
    required this.colorHex,
  });

  factory CategoriaResumen.fromJson(Map<String, dynamic> json) {
    return CategoriaResumen(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      colorHex: json['colorHex']?.toString(),
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
  final List<CategoriaResumen> categorias;

  const Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.tipo = 'ESTUDIO',
    required this.duracionMinutos,
    this.costo = 0,
    required this.estado,
    required this.categorias,
  });

  @Deprecated('Usar categorias')
  List<CategoriaResumen> get ocupaciones => categorias;

  factory Servicio.fromJson(Map<String, dynamic> json) {
    final rawDuracion = json['duracionMinutos'] ?? json['duracion'] ?? 0;
    final rawCosto = json['costo'] ?? 0;
    final categoriasRaw = json['categorias'] ?? json['ocupaciones'] ?? [];
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
      categorias: categoriasRaw is List
          ? categoriasRaw
              .whereType<Map<String, dynamic>>()
              .map(CategoriaResumen.fromJson)
              .toList()
          : [],
    );
  }
}

typedef Estudio = Servicio;
