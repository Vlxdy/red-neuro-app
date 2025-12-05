class PropiedadesModulo {
  int? orden;
  String? descripcion;
  String? icono;

  PropiedadesModulo({this.orden, this.descripcion, this.icono});

  factory PropiedadesModulo.fromJson(Map<String, dynamic> json) =>
      PropiedadesModulo(
        orden: json['orden'],
        descripcion: json['descripcion'],
        icono: json['icono'],
      );

  Map<String, dynamic> toJson() => {
    'orden': orden,
    'descripcion': descripcion,
    'icono': icono,
  };
}
