import 'package:red_neuro_app/src/models/submodulo.dart';
import 'package:red_neuro_app/src/models/propiedades_modulo.dart';

class Modulo {
  String id;
  String label;
  String nombre;
  String url;
  String estado;
  PropiedadesModulo? propiedades;
  List<SubModulo> subModulos;

  Modulo({
    required this.id,
    required this.label,
    required this.nombre,
    required this.url,
    required this.estado,
    this.propiedades,
    required this.subModulos,
  });

  factory Modulo.fromJson(Map<String, dynamic> json) => Modulo(
    id: json['id'] ?? '',
    label: json['label'] ?? '',
    nombre: json['nombre'] ?? '',
    url: json['url'] ?? '',
    estado: json['estado'] ?? '',
    propiedades: json['propiedades'] != null
        ? PropiedadesModulo.fromJson(json['propiedades'])
        : null,
    subModulos:
        (json['subModulo'] as List<dynamic>?)
            ?.map((s) => SubModulo.fromJson(s))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'nombre': nombre,
    'url': url,
    'estado': estado,
    'propiedades': propiedades?.toJson(),
    'subModulo': subModulos.map((s) => s.toJson()).toList(),
  };
}
