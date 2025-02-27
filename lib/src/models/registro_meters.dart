class DropDownType {
  String id;
  String nombre;

  DropDownType({required this.id, required this.nombre});
}

class RegistroMeterStore {
  final DropDownType tipoMedicion;
  final List<DispensadorStore> dispensadores;

  RegistroMeterStore({
    required this.tipoMedicion,
    required this.dispensadores,
  });

  // Convertir el objeto a un mapa para guardarlo o serializarlo
  Map<String, dynamic> toMap() {
    return {
      'tipoMedicion': tipoMedicion,
      'dispensadores': dispensadores.map((d) => d.toMap()).toList(),
    };
  }

  // Convertir un mapa a un objeto RegistroMeterStore
  factory RegistroMeterStore.fromMap(Map<String, dynamic> map) {
    return RegistroMeterStore(
      tipoMedicion: map['tipoMedicion'],
      dispensadores: List<DispensadorStore>.from(
        map['dispensadores']?.map((d) => DispensadorStore.fromMap(d)),
      ),
    );
  }
}

class DispensadorStore {
  final String hora;
  final String idDispensador;
  final String codigo;
  final List<MangueraStore> mangueras;

  DispensadorStore({
    required this.hora,
    required this.idDispensador,
    required this.codigo,
    required this.mangueras,
  });

  // Convertir el objeto a un mapa para guardarlo o serializarlo
  Map<String, dynamic> toMap() {
    return {
      'hora': hora,
      'idDispensador': idDispensador,
      'codigo': codigo,
      'mangueras': mangueras.map((m) => m.toMap()).toList(),
    };
  }

  // Convertir un mapa a un objeto DispensadorStore
  factory DispensadorStore.fromMap(Map<String, dynamic> map) {
    return DispensadorStore(
      hora: map['hora'],
      idDispensador: map['idDispensador'],
      codigo: map['codigo'],
      mangueras: List<MangueraStore>.from(
        map['mangueras']?.map((m) => MangueraStore.fromMap(m)),
      ),
    );
  }
}

class MangueraStore {
  final String idManguera;
  final String codigo;
  final DropDownType combustible;
  final int meter;

  MangueraStore({
    required this.idManguera,
    required this.codigo,
    required this.combustible,
    required this.meter,
  });

  // Convertir el objeto a un mapa para guardarlo o serializarlo
  Map<String, dynamic> toMap() {
    return {
      'idManguera': idManguera,
      'codigo': codigo,
      'combustible': combustible,
      'meter': meter,
    };
  }

  // Convertir un mapa a un objeto MangueraStore
  factory MangueraStore.fromMap(Map<String, dynamic> map) {
    return MangueraStore(
      idManguera: map['idManguera'],
      codigo: map['codigo'],
      combustible: map['combustible'],
      meter: map['meter'],
    );
  }
}
