class EstacionServicio {
  String? id;
  String? nombre;
  String? estado;
  String? latitud;
  String? longitud;

  EstacionServicio({
    this.id,
    this.nombre,
    this.estado,
    this.latitud,
    this.longitud,
  });

  factory EstacionServicio.fromJson(Map<String, dynamic> json) {
    return EstacionServicio(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      estado: json['estado'] ?? '',
      latitud: json['latitud'] ?? '',
      longitud: json['longitud'] ?? '',
    );
  }
}
