import 'package:alimenta_app/src/ui/pages/carrito_compras/models/producto_carrito.dart';

class CarritoLocal {
  const CarritoLocal({
    required this.fechaInicio,
    required this.fechaFin,
    required this.productos,
  });

  final DateTime fechaInicio;
  final DateTime fechaFin;
  final List<ProductoCarrito> productos;

  CarritoLocal copyWith({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    List<ProductoCarrito>? productos,
  }) {
    return CarritoLocal(
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      productos: productos ?? this.productos,
    );
  }

  factory CarritoLocal.fromJson(Map<String, dynamic> json) {
    final productosJson = (json['productos'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProductoCarrito.fromJson)
        .toList();
    return CarritoLocal(
      fechaInicio: DateTime.tryParse(json['fechaInicio']?.toString() ?? '') ??
          DateTime.now(),
      fechaFin:
          DateTime.tryParse(json['fechaFin']?.toString() ?? '') ?? DateTime.now(),
      productos: productosJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'productos': productos.map((producto) => producto.toJson()).toList(),
    };
  }
}
