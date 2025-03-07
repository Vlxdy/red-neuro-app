class Venta {
  final String codigo;
  final int cantidadVentas;

  Venta({
    required this.codigo,
    required this.cantidadVentas,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      codigo: json['codigo'] ?? 'Desconocido',
      cantidadVentas: int.tryParse(json['cantidadVentas']?.toString() ?? '0') ?? 0,
    );
  }
}
