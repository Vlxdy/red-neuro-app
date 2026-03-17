class NotificacionItem {
  final String id;
  final String tipo;
  final String mensaje;
  final bool visto;
  final String? idCita;
  final String? idPersonal;
  final DateTime fechaCreacion;

  const NotificacionItem({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.visto,
    required this.fechaCreacion,
    this.idCita,
    this.idPersonal,
  });

  factory NotificacionItem.fromJson(Map<String, dynamic> json) {
    return NotificacionItem(
      id: '${json['id'] ?? ''}',
      tipo: '${json['tipo'] ?? 'RESUMEN_DIARIO'}',
      mensaje: '${json['mensaje'] ?? ''}',
      visto: json['visto'] == true,
      idCita: json['idCita']?.toString(),
      idPersonal: json['idPersonal']?.toString(),
      fechaCreacion:
          DateTime.tryParse('${json['fechaCreacion'] ?? ''}')?.toLocal() ??
          DateTime.now(),
    );
  }

  NotificacionItem copyWith({bool? visto}) {
    return NotificacionItem(
      id: id,
      tipo: tipo,
      mensaje: mensaje,
      visto: visto ?? this.visto,
      idCita: idCita,
      idPersonal: idPersonal,
      fechaCreacion: fechaCreacion,
    );
  }

}
