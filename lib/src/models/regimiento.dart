class Regimiento {
  String? nombre;
  String? tipoFuerza;
  String? id;

  Regimiento({this.nombre, this.tipoFuerza, this.id});

  Regimiento.fromJson(Map<String, dynamic> json) {
    nombre = json['nombre'] ?? '';
    tipoFuerza = json['tipoFuerza'] ?? '';
    id = json['id'] ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipoFuerza': tipoFuerza,
      'id': id,
    };
  }
}
