import 'package:alimenta_app/src/constants/citas_estado.dart';

class Cita {
  final String id;
  final String detalle;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final CitasEstado estado;
  final CitaPersona paciente;
  final CitaPersona medico;

  Cita({
    required this.id,
    required this.detalle,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.paciente,
    required this.medico,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id']?.toString() ?? '',
      detalle: json['detalle'] ?? '',
      fechaInicio: _parseDate(json['fechaInicio']),
      fechaFin: _parseDate(json['fechaFin']),
      estado: CitasEstado.fromValue(json['estado'] as String?),
      paciente: CitaPersona.fromJson(json['paciente'] as Map<String, dynamic>?),
      medico: CitaPersona.fromJson(json['medico'] as Map<String, dynamic>?),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}

class CitaPersona {
  final String id;
  final String nombres;
  final String primerApellido;
  final String segundoApellido;
  final String? correoElectronico;
  final String? urlFoto;
  final String? telefono;

  CitaPersona({
    required this.id,
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
    this.correoElectronico,
    this.urlFoto,
    this.telefono,
  });

  factory CitaPersona.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CitaPersona(
        id: '',
        nombres: '',
        primerApellido: '',
        segundoApellido: '',
      );
    }

    return CitaPersona(
      id: json['id']?.toString() ?? '',
      nombres: json['nombres'] ?? '',
      primerApellido: json['primerApellido'] ?? '',
      segundoApellido: json['segundoApellido'] ?? '',
      correoElectronico: json['correoElectronico'],
      urlFoto: json['urlFoto'],
      telefono: json['telefono']?.toString(),
    );
  }

  String get nombreCompleto {
    return [nombres, primerApellido, segundoApellido]
        .where((parte) => parte.isNotEmpty)
        .join(' ');
  }
}

class CitaHistorial {
  final String id;
  final String? estadoAnterior;
  final CitasEstado estado;
  final String? comentario;
  final String rolEjecutor;
  final CitaUsuarioEjecutor? usuarioEjecutor;
  final DateTime fechaCreacion;

  CitaHistorial({
    required this.id,
    required this.estadoAnterior,
    required this.estado,
    required this.comentario,
    required this.rolEjecutor,
    required this.usuarioEjecutor,
    required this.fechaCreacion,
  });

  factory CitaHistorial.fromJson(Map<String, dynamic> json) {
    return CitaHistorial(
      id: json['id']?.toString() ?? '',
      estadoAnterior: json['estadoAnterior']?.toString(),
      estado: CitasEstado.fromValue(json['estado'] as String?),
      comentario: json['comentario']?.toString(),
      rolEjecutor: json['rolEjecutor']?.toString() ?? '',
      usuarioEjecutor:
          CitaUsuarioEjecutor.fromJson(json['usuarioEjecutor'] as Map<String, dynamic>?),
      fechaCreacion: Cita._parseDate(json['fechaCreacion']),
    );
  }
}

class CitaUsuarioEjecutor {
  final String id;
  final String nombres;
  final String primerApellido;
  final String segundoApellido;
  final String? correoElectronico;
  final String? urlFoto;

  CitaUsuarioEjecutor({
    required this.id,
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
    this.correoElectronico,
    this.urlFoto,
  });

  factory CitaUsuarioEjecutor.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CitaUsuarioEjecutor(
        id: '',
        nombres: '',
        primerApellido: '',
        segundoApellido: '',
      );
    }

    return CitaUsuarioEjecutor(
      id: json['id']?.toString() ?? '',
      nombres: json['nombres'] ?? '',
      primerApellido: json['primerApellido'] ?? '',
      segundoApellido: json['segundoApellido'] ?? '',
      correoElectronico: json['correoElectronico']?.toString(),
      urlFoto: json['urlFoto']?.toString(),
    );
  }

  String get nombreCompleto {
    return [nombres, primerApellido, segundoApellido]
        .where((parte) => parte.isNotEmpty)
        .join(' ');
  }
}

class CitaHistorialPage {
  final int total;
  final List<CitaHistorial> registros;

  CitaHistorialPage({required this.total, required this.registros});
}
