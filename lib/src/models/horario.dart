class Horario {
  String? id;
  String? nombre;
  String? estado;
  String? horaInicio;
  String? horaFin;

  Horario({this.id, this.nombre, this.estado, this.horaInicio, this.horaFin});

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      estado: json['estado'] ?? '',
      horaInicio: json['horaInicio'] ?? '',
      horaFin: json['horaFin'] ?? '',
    );
  }
}
