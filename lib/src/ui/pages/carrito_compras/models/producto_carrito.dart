/// Representa un producto recomendado para el carrito de compras.
class ProductoCarrito {
  const ProductoCarrito({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidadMedida,
    required this.cantidad,
    required this.calorias,
    required this.descripcion,
    required this.carbohidratos,
    required this.grasa,
    required this.proteinas,
    required this.cantidadReferencial,
    required this.urlImage,
    required this.tipo,
    this.comprado = false,
    this.idAlimento,
  });

  final String id;
  final String nombre;
  final String categoria;
  final String unidadMedida;
  final double cantidad;
  final double calorias;
  final String descripcion;
  final double carbohidratos;
  final double grasa;
  final double proteinas;
  final double cantidadReferencial;
  final String urlImage;
  final String tipo;
  final bool comprado;
  final String? idAlimento;

  ProductoCarrito copyWith({
    bool? comprado,
  }) {
    return ProductoCarrito(
      id: id,
      nombre: nombre,
      categoria: categoria,
      unidadMedida: unidadMedida,
      cantidad: cantidad,
      calorias: calorias,
      descripcion: descripcion,
      carbohidratos: carbohidratos,
      grasa: grasa,
      proteinas: proteinas,
      cantidadReferencial: cantidadReferencial,
      urlImage: urlImage,
      tipo: tipo,
      comprado: comprado ?? this.comprado,
      idAlimento: idAlimento,
    );
  }

  factory ProductoCarrito.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return ProductoCarrito(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      unidadMedida: json['unidadMedida']?.toString() ?? '',
      cantidad: _parseDouble(json['cantidad']),
      calorias: _parseDouble(json['calorias']),
      descripcion: json['descripcion']?.toString() ?? '',
      carbohidratos: _parseDouble(json['carbohidratos']),
      grasa: _parseDouble(json['grasa']),
      proteinas: _parseDouble(json['proteinas']),
      cantidadReferencial: _parseDouble(json['cantidadReferencial']),
      urlImage: json['urlImage']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      idAlimento: json['idAlimento']?.toString(),
      comprado: json['comprado'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'unidadMedida': unidadMedida,
      'cantidad': cantidad,
      'calorias': calorias,
      'descripcion': descripcion,
      'carbohidratos': carbohidratos,
      'grasa': grasa,
      'proteinas': proteinas,
      'cantidadReferencial': cantidadReferencial,
      'urlImage': urlImage,
      'tipo': tipo,
      'comprado': comprado,
      'idAlimento': idAlimento,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductoCarrito && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
