class Regimiento {
  late String nombre;
  late String tipoFuerza;
  late String id;

  Regimiento(
      {required this.nombre, required this.tipoFuerza, required this.id});

  Regimiento.fromJson(Map<String, dynamic> json) {
    nombre = json['nombre'];
    tipoFuerza = json['tipoFuerza'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipoFuerza': tipoFuerza,
      'id': id,
    };
  }
}
