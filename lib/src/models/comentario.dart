class Comentario {
  final String id;
  final String autor;
  final String texto;
  final DateTime fecha;

  Comentario({
    required this.id,
    required this.autor,
    required this.texto,
    required this.fecha,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'].toString(),
      autor: json['autor'] ?? 'Anónimo',
      texto: json['texto'] ?? '',
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autor': autor,
      'texto': texto,
      'fecha': fecha.toIso8601String(),
    };
  }
}
