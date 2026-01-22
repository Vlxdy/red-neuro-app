class HistorialCita {
  final String id;
  final String citaId;
  final String estadoAnterior;
  final String rolEjecutor;
  final String idEjecutor;
  final String comentario;
  final List<String> detalleCambios;
  final String ejecutorNombre;
  final DateTime? fechaCreacion;

  const HistorialCita({
    required this.id,
    required this.citaId,
    required this.estadoAnterior,
    required this.rolEjecutor,
    required this.idEjecutor,
    required this.comentario,
    required this.detalleCambios,
    required this.ejecutorNombre,
    required this.fechaCreacion,
  });

  factory HistorialCita.fromJson(Map<String, dynamic> jsonRaw) {
    final ejecutorRaw = jsonRaw['ejecutor'];
    final ejecutorNombre = ejecutorRaw is Map<String, dynamic>
        ? [
            ejecutorRaw['nombres'],
            ejecutorRaw['primerApellido'],
            ejecutorRaw['segundoApellido'],
          ].whereType<String>().where((value) => value.trim().isNotEmpty).join(
              ' ',
            )
        : '';

    return HistorialCita(
      id: (jsonRaw['id'] ?? '').toString(),
      citaId: (jsonRaw['citaId'] ?? '').toString(),
      estadoAnterior: (jsonRaw['estadoAnterior'] ?? '').toString(),
      rolEjecutor: (jsonRaw['rolEjecutor'] ?? '').toString(),
      idEjecutor: (jsonRaw['idEjecutor'] ?? '').toString(),
      comentario: (jsonRaw['comentario'] ?? '').toString(),
      detalleCambios: (jsonRaw['detalleCambios'] is List)
          ? (jsonRaw['detalleCambios'] as List)
              .map((item) => item.toString())
              .toList()
          : const [],
      ejecutorNombre: ejecutorNombre,
      fechaCreacion: _parseDate(jsonRaw['fechaCreacion']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }
}
