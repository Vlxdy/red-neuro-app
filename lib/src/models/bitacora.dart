class Bitacora {
  String id = '';
  DateTime? fecha;

  Bitacora({
    required this.id,
    this.fecha,
  });

  factory Bitacora.fromJson(Map<String, dynamic> json) {
    return Bitacora(
      id: json['id'] ?? '',
      fecha: DateTime.parse(json['fecha']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha?.toIso8601String(),
    };
  }
}
