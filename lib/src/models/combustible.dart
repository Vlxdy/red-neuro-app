class Combustible {
  String id;
  String codigo;
  String descripcion;
  String? nombre;
  String? color;

  Combustible({
    required this.id,
    required this.codigo,
    required this.descripcion,
    this.nombre,
    this.color,
  });

  static Combustible get empty =>
      Combustible(id: '', codigo: '', descripcion: '', nombre: '', color: '');

  factory Combustible.fromJson(Map<String, dynamic> json) => Combustible(
        id: json["id"] ?? '',
        codigo: json["codigo"] ?? '',
        descripcion: json["descripcion"] ?? '',
        nombre: json['nombre'] ?? '',
        color: json['color'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "codigo": codigo,
        "descripcion": descripcion,
        "nombre": nombre,
        "color": color,
      };
}
