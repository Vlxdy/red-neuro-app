class Combustible {
  String id;
  String codigo;
  String descripcion;

  Combustible({
    required this.id,
    required this.codigo,
    required this.descripcion,
  });

  static Combustible get empty => Combustible(
    id: '',
    codigo: '',
    descripcion: '',
  );

  factory Combustible.fromJson(Map<String, dynamic> json) => Combustible(
        id: json["id"] ?? '',
        codigo: json["codigo"] ?? '',
        descripcion: json["descripcion"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "codigo": codigo,
        "descripcion": descripcion,
      };
}
