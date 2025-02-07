class IdVehiculo {
  String identidad;
  String placa;

  IdVehiculo({
    required this.identidad,
    required this.placa,
  });

  factory IdVehiculo.fromJson(Map<String, dynamic> json) => IdVehiculo(
        identidad: json["identidad"] ?? '',
        placa: json["placa"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "identidad": identidad,
        "placa": placa,
      };
}
