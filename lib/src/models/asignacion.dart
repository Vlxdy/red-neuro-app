class Asignacion {
  String id;
  String idVehiculo;
  String idUsuario;
  String crpva;
  String tipo;

  Asignacion({
    required this.id,
    required this.idVehiculo,
    required this.idUsuario,
    required this.crpva,
    required this.tipo,
  });

  static Asignacion get empty => Asignacion(
        id: '',
        idVehiculo: '',
        idUsuario: '',
        crpva: '',
        tipo: '',
      );

  factory Asignacion.fromJson(Map<String, dynamic> json) => Asignacion(
        id: json['id'] ?? '',
        idVehiculo: json['idVehiculo'] ?? '',
        idUsuario: json['idUsuario'] ?? '',
        crpva: json['crpva'] ?? '',
        tipo: json['tipo'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idVehiculo': idVehiculo,
        'idUsuario': idUsuario,
        'crpva': crpva,
        'tipo': tipo,
      };
}
