import 'package:red_neuro_app/src/models/propiedades_modulo.dart';

class SubModulo {
  String id;
  String label;
  String nombre;
  String url;
  String estado;
  PropiedadesModulo? propiedades;

  SubModulo({
    required this.id,
    required this.label,
    required this.nombre,
    required this.url,
    required this.estado,
    this.propiedades,
  });

  factory SubModulo.fromJson(Map<String, dynamic> json) => SubModulo(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        nombre: json['nombre'] ?? '',
        url: json['url'] ?? '',
        estado: json['estado'] ?? '',
        propiedades: json['propiedades'] != null
            ? PropiedadesModulo.fromJson(json['propiedades'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'nombre': nombre,
        'url': url,
        'estado': estado,
        'propiedades': propiedades?.toJson(),
      };
}
