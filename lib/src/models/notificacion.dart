class Notificacion {
  const Notificacion({
    required this.id,
    this.idPaciente,
    this.tipo,
    required this.mensaje,
    required this.visto,
    required this.fechaCreacion,
    this.idCita,
  });

  final String id;
  final String? idPaciente;
  final String? tipo;
  final String mensaje;
  final bool visto;
  final DateTime fechaCreacion;
  final String? idCita;

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    final dynamic vistoRaw = json['visto'];
    return Notificacion(
      id: json['id']?.toString() ?? '',
      idPaciente: json['idPaciente']?.toString(),
      tipo: json['tipo']?.toString(),
      mensaje: json['mensaje']?.toString() ?? '',
      visto: _parseBool(vistoRaw),
      fechaCreacion: _parseDate(json['fechaCreacion']),
      idCita: json['idCita']?.toString(),
    );
  }

  Notificacion copyWith({bool? visto}) {
    return Notificacion(
      id: id,
      idPaciente: idPaciente,
      tipo: tipo,
      mensaje: mensaje,
      visto: visto ?? this.visto,
      fechaCreacion: fechaCreacion,
      idCita: idCita,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idPaciente': idPaciente,
      'tipo': tipo,
      'mensaje': mensaje,
      'visto': visto,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'idCita': idCita,
    };
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'si';
    }
    return false;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    if (value is DateTime) return value.toUtc();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
