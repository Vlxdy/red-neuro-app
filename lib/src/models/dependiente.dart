import 'package:camino_seguro/src/models/area.dart';

class Dependiente {
  String id;
  String nombre;
  String estado;
  List<Area> areas;

  Dependiente({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.areas,
  });

  static Dependiente get empty => Dependiente(
        id: '',
        nombre: '',
        estado: '',
        areas: [],
      );

  factory Dependiente.fromJson(Map<String, dynamic> json) => Dependiente(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        estado: json['estado'] ?? '',
        areas: json['areas'] != null
            ? List<Area>.from(
                json['areas'].map((area) => Area.fromJson(area)),
              )
            : [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'estado': estado,
        'areas': areas.map((area) => area.toJson()).toList(),
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
