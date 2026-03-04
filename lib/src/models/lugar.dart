class Lugar {
  final String id;
  final String nombre;
  final String sigla;
  final String direccion;
  final String tipo;
  final String estado;

  const Lugar({
    required this.id,
    required this.nombre,
    required this.sigla,
    required this.direccion,
    required this.tipo,
    required this.estado,
  });

  factory Lugar.fromJson(Map<String, dynamic> json) {
    return Lugar(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      sigla: (json['sigla'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
    );
  }
}
