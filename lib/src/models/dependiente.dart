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

class DependientesRutaResponse {
  final List<DependienteRuta> list;

  DependientesRutaResponse({required this.list});

  factory DependientesRutaResponse.fromJson(Map<String, dynamic> json) {
    return DependientesRutaResponse(
      list: (json['list'] as List<dynamic>)
          .map((e) => DependienteRuta.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DependienteRuta {
  final String codigo;
  final RutaDeHoy rutadeHoy;

  DependienteRuta({
    required this.codigo,
    required this.rutadeHoy,
  });

  factory DependienteRuta.fromJson(Map<String, dynamic> json) {
    return DependienteRuta(
      codigo: json['codigo'],
      rutadeHoy: RutaDeHoy.fromJson(json['rutadeHoy'] as Map<String, dynamic>),
    );
  }
}

class RutaDeHoy {
  final String type;
  final List<List<double>> coordinates;

  RutaDeHoy({
    required this.type,
    required this.coordinates,
  });

  factory RutaDeHoy.fromJson(Map<String, dynamic> json) {
    // json['coordinates'] es List<List<num>>, lo convertimos a double
    final rawCoords = json['coordinates'] as List<dynamic>;
    final coords = rawCoords.map<List<double>>((row) {
      final listRow = row as List<dynamic>;
      return listRow.map((v) => (v as num).toDouble()).toList();
    }).toList();

    return RutaDeHoy(
      type: json['type'] as String,
      coordinates: coords,
    );
  }
}
