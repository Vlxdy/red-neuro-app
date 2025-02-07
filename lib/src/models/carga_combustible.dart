class CargaCombustible {
  String departamento;
  String estacion;
  String placa;
  String fechaVenta;
  String producto;
  String volumen;

  CargaCombustible({
    required this.departamento,
    required this.estacion,
    required this.placa,
    required this.fechaVenta,
    required this.producto,
    required this.volumen,
  });

  factory CargaCombustible.fromJson(Map<String, dynamic> json) => CargaCombustible(
        departamento: json["departamento"] ?? '',
        estacion: json["estacionServicio"] ?? '',
        placa: json["placa"] ?? '',
        fechaVenta: json["fechaVenta"] ?? '',
        producto: json["producto"] ?? '',
        volumen: json["volumen"] ?? '0.0',
      );

  Map<String, dynamic> toJson() => {
        "departamento": departamento,
        "estacion": estacion,
        "placa": placa,
        "fechaVenta": fechaVenta,
        "producto": producto,
        "volumen": volumen,
      };
}
