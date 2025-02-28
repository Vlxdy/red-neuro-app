// import 'dart:ffi';

import 'dart:convert';

import 'package:control_ventas_movil/src/plugins/utils/logger.dart';

class ResumenDia {
  List<VentasResumen> ventas;
  List<VolumenesResumen> volumenes;
  NovedadesResumen? novedades;

  ResumenDia({
    required this.ventas,
    required this.volumenes,
    this.novedades,
  });

  factory ResumenDia.fromJson(Map<String, dynamic> json) {
    Logger.info(jsonEncode(json));
    return ResumenDia(
        ventas: json['ventas'] != null
            ? (json['ventas'] as List)
                .map((item) => VentasResumen.fromJson(item))
                .toList()
            : [],
        volumenes: json['volumenes'] != null
            ? (json['volumenes'] as List)
                .map((item) => VolumenesResumen.fromJson(item))
                .toList()
            : [],
        novedades: json['novedades'] != null
            ? NovedadesResumen.fromJson(json['novedades'])
            : NovedadesResumen(
                observaciones: [],
                totalObservaciones: 0,
                incidentes: [],
                totalIncidentes: 0));
  }
  Map<String, dynamic> toJson() {
    return {
      'ventas': ventas,
      'volumenes': volumenes,
      'novedades': novedades,
    };
  }
}

class VentasResumen {
  String tipoVenta;
  String cantidad;
  List<DetalleVenta> detalle;

  VentasResumen({
    required this.tipoVenta,
    required this.cantidad,
    required this.detalle,
  });

  factory VentasResumen.fromJson(Map<String, dynamic> json) {
    return VentasResumen(
        tipoVenta: json['tipoVenta'] ?? '',
        cantidad: json['cantidad'] ?? '',
        detalle: json['detalle'] != null
            ? (json['detalle'] as List)
                .map((item) => DetalleVenta.fromJson(item))
                .toList()
            : []);
  }
  Map<String, dynamic> toJson() {
    return {
      'id': tipoVenta,
      'nombre': cantidad,
      'capacidad': detalle,
    };
  }
}

class DetalleVenta {
  String tipoCombustible;
  String cantidad;
  String? color;

  DetalleVenta({
    required this.tipoCombustible,
    required this.cantidad,
    this.color,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      tipoCombustible: json['tipoCombustible'] ?? '',
      cantidad: json['cantidad'] ?? '',
      color: json['color'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'tipoCombustible': tipoCombustible,
      'cantidad': cantidad,
      'color': color,
    };
  }
}

class VolumenesResumen {
  String id;
  String idCombustible;
  String nombre;
  int capacidad;
  List<TanqueRegistroVolumen> tanqueRegistroVolumen;

  VolumenesResumen({
    required this.id,
    required this.idCombustible,
    required this.nombre,
    required this.capacidad,
    required this.tanqueRegistroVolumen,
  });

  factory VolumenesResumen.fromJson(Map<String, dynamic> json) {
    Logger.info('primer objetp');
    Logger.info(jsonEncode(json));
    return VolumenesResumen(
      id: json['id'] ?? '',
      idCombustible: json['idCombusticle'] ?? '',
      nombre: json['nombre'] ?? '',
      capacidad: json['capacidad'] ?? 0,
      tanqueRegistroVolumen: json['tanqueRegistroVolumen'] != null
          ? (json['tanqueRegistroVolumen'] as List)
              .map((item) => TanqueRegistroVolumen.fromJson(item))
              .toList()
          : [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idCombustible': idCombustible,
      'capacidad': capacidad,
    };
  }
}

class TanqueRegistroVolumen {
  String id;
  String hora;
  String tipoMedicion;
  String tipoCombustible;
  String volumen;

  TanqueRegistroVolumen({
    required this.id,
    required this.hora,
    required this.tipoMedicion,
    required this.tipoCombustible,
    required this.volumen,
  });

  factory TanqueRegistroVolumen.fromJson(Map<String, dynamic> json) {
    print(json);
    print('==================');
    return TanqueRegistroVolumen(
      id: json['id'] ?? '',
      hora: json['hora'] ?? '',
      tipoMedicion: json['tipoMedicion'] ?? '',
      tipoCombustible: json['tipoCombustible'] ?? '',
      volumen: json['volumen'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hora': hora,
      'tipoMedicion': tipoMedicion,
      'tipoCombustible': tipoCombustible,
      'volumen': volumen,
    };
  }
}

class NovedadesResumen {
  List<ObservacionesNovedades> observaciones;
  int totalObservaciones;
  List<IncidentesNovedades> incidentes;
  int totalIncidentes;

  NovedadesResumen({
    required this.observaciones,
    required this.totalObservaciones,
    required this.incidentes,
    required this.totalIncidentes,
  });

  factory NovedadesResumen.fromJson(Map<String, dynamic> json) {
    return NovedadesResumen(
      observaciones: json['observaciones'] != null &&
              json['observaciones'] is List &&
              json['observaciones'].isNotEmpty
          ? (json['observaciones'][0] as List)
              .map((item) => ObservacionesNovedades.fromJson(item))
              .toList()
          : [],
      totalObservaciones:
          json['observaciones'] != null && json['observaciones'].length > 1
              ? json['observaciones'][1] as int
              : 0,
      incidentes: json['incidentes'] != null &&
              json['incidentes'] is List &&
              json['incidentes'].isNotEmpty
          ? (json['incidentes'][0] as List)
              .map((item) => IncidentesNovedades.fromJson(item))
              .toList()
          : [],
      totalIncidentes:
          json['incidentes'] != null && json['incidentes'].length > 1
              ? json['incidentes'][1] as int
              : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'observaciones': [
        observaciones.map((e) => e.toJson()).toList(),
        totalObservaciones
      ],
      'incidentes': [
        incidentes.map((e) => e.toJson()).toList(),
        totalIncidentes
      ],
    };
  }
}

class ObservacionesNovedades {
  String id;
  String observacion;

  ObservacionesNovedades({
    required this.id,
    required this.observacion,
  });

  factory ObservacionesNovedades.fromJson(Map<String, dynamic> json) {
    return ObservacionesNovedades(
      id: json['id'] ?? '',
      observacion: json['observacion'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'observacion': observacion,
    };
  }
}

class IncidentesNovedades {
  String id;
  String observacion;
  String respaldo;

  IncidentesNovedades({
    required this.id,
    required this.observacion,
    required this.respaldo,
  });

  factory IncidentesNovedades.fromJson(Map<String, dynamic> json) {
    return IncidentesNovedades(
      id: json['id'] ?? '',
      observacion: json['observacion'] ?? '',
      respaldo: json['respaldo'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'observacion': observacion,
      'respaldo': respaldo,
    };
  }
}
