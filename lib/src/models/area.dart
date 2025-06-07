import 'package:hive/hive.dart';

class Area {
  String id;
  String nombre;
  String estado;
  RutaArea ruta;
  GeometriaArea geometria;

  Area({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.ruta,
    required this.geometria,
  });

  static get empty => Area(
      id: '',
      nombre: '',
      estado: '',
      ruta: RutaArea.empty,
      geometria: GeometriaArea.empty);

  factory Area.fromJson(Map<String, dynamic> json) => Area(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        estado: json['estado'] ?? '',
        ruta: json['ruta'] != null
            ? RutaArea.fromJson(json['ruta'])
            : RutaArea.empty,
        geometria: json['geometria'] != null
            ? GeometriaArea.fromJson(json['geometria'])
            : GeometriaArea.empty,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'estado': estado,
        'ruta': ruta.toJson(),
        'geometria': geometria.toJson(),
      };
}

class RutaArea {
  String type;

  List<List<double>> coordinates;

  RutaArea({
    required this.type,
    required this.coordinates,
  });

  static get empty => RutaArea(type: '', coordinates: []);

  factory RutaArea.fromJson(Map<String, dynamic> json) => RutaArea(
        type: json['type'] ?? '',
        coordinates: (json['coordinates'] as List)
            .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}

@HiveType(typeId: 26)
class GeometriaArea {
  String type;
  List<List<List<double>>> coordinates;

  GeometriaArea({
    required this.type,
    required this.coordinates,
  });

  static get empty => GeometriaArea(type: '', coordinates: []);

  factory GeometriaArea.fromJson(Map<String, dynamic> json) => GeometriaArea(
        type: json['type'] ?? '',
        coordinates: (json['coordinates'] as List)
            .map((poly) => (poly as List)
                .map((coord) =>
                    (coord as List).map((n) => (n as num).toDouble()).toList())
                .toList())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}

class FormularioRegistroAreas {
  final List<ItemAreas> datos;

  FormularioRegistroAreas({
    required this.datos,
  });
  static get empty => FormularioRegistroAreas(datos: []);

  Map<String, dynamic> toMap() {
    return {
      'datos': datos.map((item) => item.toMap()).toList(),
    };
  }
}

class ItemAreas {
  final String idTanque;
  final String hora;
  final String tipoMedicion;
  final int volumen;
  final String idCombustible;
  final String fechaRegistroApp;

  ItemAreas({
    required this.idTanque,
    required this.hora,
    required this.tipoMedicion,
    required this.volumen,
    required this.idCombustible,
    required this.fechaRegistroApp,
  });
  static get empty => ItemAreas(
      fechaRegistroApp: '',
      hora: '',
      idCombustible: '',
      idTanque: '',
      tipoMedicion: '',
      volumen: 0);

  Map<String, dynamic> toMap() {
    return {
      'idTanque': idTanque,
      'hora': hora,
      'idCombustible': idCombustible,
      'tipoMedicion': tipoMedicion,
      'volumen': volumen,
      'fechaRegistroApp': fechaRegistroApp,
    };
  }
}
