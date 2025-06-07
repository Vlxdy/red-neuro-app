import 'package:camino_seguro/src/models/area.dart';

class Dependiente {
  String id;
  String nombre;
  String codigo;
  String estado;
  List<DependienteArea> dependienteArea;

  Dependiente({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.dependienteArea,
    required this.codigo,
  });

  static Dependiente get empty => Dependiente(
        id: '',
        nombre: '',
        codigo: '',
        estado: '',
        dependienteArea: [],
      );

  factory Dependiente.fromJson(Map<String, dynamic> json) => Dependiente(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        estado: json['estado'] ?? '',
        codigo: json['codigo'] ?? '',
        dependienteArea: json['dependienteArea'] != null
            ? List<DependienteArea>.from(
                json['areas'].map((area) => DependienteArea.fromJson(area)),
              )
            : [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'codigo': codigo,
        'estado': estado,
        'dependienteArea':
            dependienteArea.map((depArea) => depArea.toJson()).toList(),
      };
}

class DependienteArea {
  String id;
  Area area;

  DependienteArea({
    required this.id,
    required this.area,
  });

  static DependienteArea get empty => DependienteArea(
        id: '',
        area: Area.empty,
      );

  factory DependienteArea.fromJson(Map<String, dynamic> json) =>
      DependienteArea(
        id: json['id'] ?? '',
        area: json['area'] != null ? Area.fromJson(json['area']) : Area.empty,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'area': area.toJson(),
      };
}

class ObjetoId {
  String id;
  ObjetoId({required this.id});
  factory ObjetoId.fromJson(Map<String, dynamic> json) => ObjetoId(
        id: json['id'] ?? '',
      );
  Map<String, dynamic> toJson() => {
        'id': id,
      };
}
