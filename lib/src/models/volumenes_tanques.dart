// import 'dart:ffi';
class VolumenTanque {
  String id;
  String hora;
  String tipoMedicion;
  String volumen;
  CombustibleVolumenTanque? combustible;
  TanqueVolumenTanque? tanques;

  VolumenTanque({
    required this.id,
    required this.hora,
    required this.tipoMedicion,
    required this.volumen,
    this.combustible,
    this.tanques,
  });

  factory VolumenTanque.fromJson(Map<String, dynamic> json) {
    return VolumenTanque(
      id: json['id'] ?? '',
      hora: json['hora'] ?? '',
      tipoMedicion: json['tipoMedicion'] ?? '',
      volumen: json['volumen'] ?? '',
      combustible: json['combustible'] != null
          ? CombustibleVolumenTanque.fromJson(json['combustible'])
          : null,
      tanques: json['tanques'] != null
          ? TanqueVolumenTanque.fromJson(json['tanques'])
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hora': hora,
      'tipoMedicion': tipoMedicion,
      'volumen': volumen,
      'combustible': combustible,
      'tanques': tanques,
    };
  }
}

class CombustibleVolumenTanque {
  String id;
  String codigo;
  String nombre;
  String color;

  CombustibleVolumenTanque({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.color,
  });

  factory CombustibleVolumenTanque.fromJson(Map<String, dynamic> json) {
    return CombustibleVolumenTanque(
      id: json['id'] ?? '',
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      color: json['color'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'color': color,
    };
  }
}

class TanqueVolumenTanque {
  String id;
  String nombre;

  TanqueVolumenTanque({
    required this.id,
    required this.nombre,
  });

  factory TanqueVolumenTanque.fromJson(Map<String, dynamic> json) {
    return TanqueVolumenTanque(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class FormularioRegistroVolumenes {
  final List<ItemVolumenTanque> datos;

  FormularioRegistroVolumenes({
    required this.datos,
  });

  Map<String, dynamic> toMap() {
    return {
      'datos': datos.map((item) => item.toMap()).toList(),
    };
  }
}

class ItemVolumenTanque {
  final String idTanque;
  final String hora;
  final String tipoMedicion;
  final int volumen;
  final String idCombustible;
  final DateTime fechaRegistroApp;
  final String nombre;

  ItemVolumenTanque({
    required this.idTanque,
    required this.hora,
    required this.tipoMedicion,
    required this.volumen,
    required this.idCombustible,
    required this.fechaRegistroApp,
    required this.nombre,
  });

  Map<String, dynamic> toMap() {
    return {
      'idTanque': idTanque,
      'hora': hora,
      'idCombustible': idCombustible,
      'tipoMedicion': tipoMedicion,
      'volumen': volumen,
      'fechaRegistroApp': fechaRegistroApp.toIso8601String(),
      'nombre': nombre,
    };
  }
}
