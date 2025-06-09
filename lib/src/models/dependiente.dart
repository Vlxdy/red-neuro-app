import 'package:camino_seguro/src/models/area.dart';

class Dependiente {
  String id;
  String nombre;
  String codigo;
  String estado;
  List<DependienteArea> dependienteArea;
  List<Notificacion> notificaciones;

  Dependiente({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.dependienteArea,
    required this.notificaciones,
    required this.codigo,
  });

  static Dependiente get empty => Dependiente(
        id: '',
        nombre: '',
        codigo: '',
        estado: '',
        dependienteArea: [],
        notificaciones: [],
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
        notificaciones: json['notificaciones'] != null
            ? List<Notificacion>.from(
                json['areas'].map((not) => Notificacion.fromJson(not)),
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

class Notificacion {
  final String id;
  final String estado;
  final String transaccion;
  final String usuarioCreacion;
  final DateTime fechaCreacion;
  final String? usuarioModificacion;
  final DateTime fechaModificacion;
  final String titulo;
  final String cuerpo;
  final String idUsuario;
  final String idDependiente;

  Notificacion({
    required this.id,
    required this.estado,
    required this.transaccion,
    required this.usuarioCreacion,
    required this.fechaCreacion,
    this.usuarioModificacion,
    required this.fechaModificacion,
    required this.titulo,
    required this.cuerpo,
    required this.idUsuario,
    required this.idDependiente,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? s) =>
        s != null ? DateTime.parse(s) : DateTime.fromMillisecondsSinceEpoch(0);

    return Notificacion(
      id: json['id']?.toString() ?? '',
      estado: json['estado'] as String? ?? '',
      transaccion: json['transaccion'] as String? ?? '',
      usuarioCreacion: json['usuarioCreacion'] as String? ?? '',
      fechaCreacion: parseDate(json['fechaCreacion'] as String?),
      usuarioModificacion: json['usuarioModificacion'] as String?,
      fechaModificacion: parseDate(json['fechaModificacion'] as String?),
      titulo: json['titulo'] as String? ?? '',
      cuerpo: json['cuerpo'] as String? ?? '',
      idUsuario: json['idUsuario']?.toString() ?? '',
      idDependiente: json['idDependiente']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'estado': estado,
        'transaccion': transaccion,
        'usuarioCreacion': usuarioCreacion,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'usuarioModificacion': usuarioModificacion,
        'fechaModificacion': fechaModificacion.toIso8601String(),
        'titulo': titulo,
        'cuerpo': cuerpo,
        'idUsuario': idUsuario,
        'idDependiente': idDependiente,
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
  final String nombre;
  final RutaDeHoy rutadeHoy;

  DependienteRuta({
    required this.codigo,
    required this.nombre,
    required this.rutadeHoy,
  });

  factory DependienteRuta.fromJson(Map<String, dynamic> json) {
    // 1) Convertir código a String sea cual sea su tipo original
    final codigoRaw = json['codigo'];
    final nombre = json['nombre'] as String? ?? '';
    final codigo = codigoRaw is String
        ? codigoRaw
        : codigoRaw != null
            ? codigoRaw.toString()
            : '';

    // 2) RutadeHoy: si es Map parsea, si no (p.ej. []), creamos vacío
    final rawRuta = json['rutadeHoy'];
    final ruta = rawRuta is Map<String, dynamic>
        ? RutaDeHoy.fromJson(rawRuta)
        : RutaDeHoy(type: '', coordinates: []);

    return DependienteRuta(
      codigo: codigo,
      nombre: nombre,
      rutadeHoy: ruta,
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
    final rawCoords = json['coordinates'] as List<dynamic>? ?? [];
    final coords = rawCoords.map<List<double>>((row) {
      final listRow = row as List<dynamic>;
      return listRow.map((v) => (v as num).toDouble()).toList();
    }).toList();

    return RutaDeHoy(
      type: json['type'] as String? ?? '',
      coordinates: coords,
    );
  }
}
