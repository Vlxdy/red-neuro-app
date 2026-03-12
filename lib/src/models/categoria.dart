class Categoria {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? colorHex;
  final String estado;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorHex,
    required this.estado,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      colorHex: json['colorHex']?.toString(),
      estado: (json['estado'] ?? '').toString(),
    );
  }
}
