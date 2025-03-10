// import 'dart:ffi';

class EstacionServicio {
  String id;
  String nombre;
  String estado;
  String latitud;
  String longitud;
  String? idHorario;
  String? nombreHorario;
  String? horaInicio;
  String? horaFin;
  String? tolerancia;
  String? tipo;
  List<TanquesEstacion>? tanques;
  List<DispensadorEstacion>? dispensadores;

  EstacionServicio(
      {required this.id,
      required this.nombre,
      required this.estado,
      required this.latitud,
      required this.longitud,
      this.idHorario,
      this.nombreHorario,
      this.horaInicio,
      this.horaFin,
      this.tolerancia,
      this.tipo,
      this.tanques,
      this.dispensadores});

  factory EstacionServicio.fromJson(Map<String, dynamic> json) {
    return EstacionServicio(
        id: json['id'] ?? json['idEstacionServicio'] ?? '',
        nombre: json['nombreEstacionServicio'] ?? json['nombre'] ?? '',
        estado: json['estado'] ?? '',
        latitud: json['latitud'] ?? '',
        longitud: json['longitud'] ?? '',
        idHorario: json['idHorario'] ?? '',
        nombreHorario: json['nombreHorario'] ?? '',
        horaInicio: json['horaInicio'] ?? '',
        horaFin: json['horaFin'] ?? '',
        tolerancia: json['tolerancia'] ?? '',
        tipo: json['tipo'] ?? '',
        tanques: json['tanques'] != null
            ? (json['tanques'] as List)
                .map((item) => TanquesEstacion.fromJson(item))
                .toList()
            : null,
        dispensadores: json['dispensadores'] != null
            ? (json['tanques'] as List)
                .map((item) => DispensadorEstacion.fromJson(item))
                .toList()
            : null);
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'estado': estado,
      "latitud": latitud,
      "longitud": longitud,
      "idHorario": idHorario,
      "nombreHorario": nombreHorario,
      "horaInicio": horaInicio,
      "horaFin": horaFin,
      "tolerancia": tolerancia,
      "tipo": tipo,
      "dispensadores": dispensadores,
      "tanques": tanques,
    };
  }
}

class TanquesEstacion {
  String id;
  String nombre;
  int capacidad;

  TanquesEstacion({
    required this.id,
    required this.nombre,
    required this.capacidad,
  });

  factory TanquesEstacion.fromJson(Map<String, dynamic> json) {
    return TanquesEstacion(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      capacidad: json['capacidad'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'capacidad': capacidad,
    };
  }
}

class DispensadorEstacion {
  String id;
  String nombre;
  String codigo;
  int cantidadMangueras;
  List<MangueraDispensadorEstacion>? mangueras;

  DispensadorEstacion({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.cantidadMangueras,
    this.mangueras,
  });

  factory DispensadorEstacion.fromJson(Map<String, dynamic> json) {
    return DispensadorEstacion(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        codigo: json['codigo'] ?? '',
        cantidadMangueras: json['cantidadMangueras'] ?? 0,
        mangueras: json['mangueras'] != null
            ? (json['mangueras'] as List)
                .map((item) => MangueraDispensadorEstacion.fromJson(item))
                .toList()
            : null);
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'cantidadMangueras': cantidadMangueras,
      'mangueras': mangueras,
    };
  }
}

class MangueraDispensadorEstacion {
  String id;
  String codigo;

  MangueraDispensadorEstacion({
    required this.id,
    required this.codigo,
  });

  factory MangueraDispensadorEstacion.fromJson(Map<String, dynamic> json) {
    return MangueraDispensadorEstacion(
      id: json['id'] ?? '',
      codigo: json['codigo'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
    };
  }
}
