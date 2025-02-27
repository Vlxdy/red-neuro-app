class Registrxo {
  final String hora;
  final String idDispensador;
  final String idManguera;
  final String tipoMedicion;
  final String idCombustible;
  final double meter;
  final String fechaRegistroApp;

  Registrxo({
    required this.hora,
    required this.idDispensador,
    required this.idManguera,
    required this.tipoMedicion,
    required this.idCombustible,
    required this.meter,
    required this.fechaRegistroApp,
  });

  // Convertir el objeto a un mapa para guardarlo o serializarlo
  Map<String, dynamic> toMap() {
    return {
      'hora': hora,
      'idDispensador': idDispensador,
      'idManguera': idManguera,
      'tipoMedicion': tipoMedicion,
      'idCombustible': idCombustible,
      'meter': meter,
      'fechaRegistroApp': fechaRegistroApp,
    };
  }

  // Convertir un mapa a un objeto Registro
  factory Registrxo.fromMap(Map<String, dynamic> map) {
    return Registrxo(
      hora: map['hora'],
      idDispensador: map['idDispensador'],
      idManguera: map['idManguera'],
      tipoMedicion: map['tipoMedicion'],
      idCombustible: map['idCombustible'],
      meter: map['meter'],
      fechaRegistroApp: map['fechaRegistroApp'],
    );
  }
}
