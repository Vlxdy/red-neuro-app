import 'package:camino_seguro/src/models/combustible.dart';

class DropDownType {
  String id;
  String nombre;
  DropDownType({required this.id, required this.nombre});
}

/* Modelo para llenar el formulario Vólumenes y contadores */

class RegistroMeterStore {
  final String tipoMedicion;
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
  final Combustible combustible;
  final int meter;
  final String? tipoMedicion;

  MangueraStore({
    required this.idManguera,
    required this.codigo,
    required this.combustible,
    required this.meter,
    this.tipoMedicion,
  });

  // Convertir el objeto a un mapa para guardarlo o serializarlo
  Map<String, dynamic> toMap() {
    return {
      'idManguera': idManguera,
      'codigo': codigo,
      'combustible': combustible,
      'meter': meter,
      'tipoMedicion': tipoMedicion,
    };
  }

  // Convertir un mapa a un objeto MangueraStore
  factory MangueraStore.fromMap(Map<String, dynamic> map) {
    return MangueraStore(
      idManguera: map['idManguera'],
      codigo: map['codigo'],
      combustible: map['combustible'],
      meter: map['meter'],
      tipoMedicion: map['tipoMedicion'],
    );
  }
}

/* Modelo para listar Vólumenes y contadores */
class DataListMangueras {
  final String id;
  final String codigo;
  final Combustible combustible;
  final String meter;
  final String tipoMedicion;

  DataListMangueras({
    required this.id,
    required this.codigo,
    required this.combustible,
    required this.meter,
    required this.tipoMedicion,
  });

  factory DataListMangueras.fromJson(Map<String, dynamic> json) {
    return DataListMangueras(
      id: json['id'],
      codigo: json['codigo'],
      combustible: Combustible.fromJson(json['combustible']),
      meter: json['meter'],
      tipoMedicion: json['tipoMedicion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'combustible': combustible.toJson(),
      'meter': meter,
      'tipoMedicion': tipoMedicion,
    };
  }
}

class DataListDispensador {
  final String codigo;
  final List<DataListMangueras> mangueras;

  DataListDispensador({
    required this.codigo,
    required this.mangueras,
  });

  factory DataListDispensador.fromJson(Map<String, dynamic> json) {
    return DataListDispensador(
      codigo: json['codigo'],
      mangueras: (json['mangueras'] as List)
          .map((manguera) => DataListMangueras.fromJson(manguera))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'mangueras': mangueras.map((manguera) => manguera.toJson()).toList(),
    };
  }
}

class DataListVolumenes {
  final String hora;
  final List<DataListDispensador> dispensadores;

  DataListVolumenes({
    required this.hora,
    required this.dispensadores,
  });

  factory DataListVolumenes.fromJson(Map<String, dynamic> json) {
    return DataListVolumenes(
      hora: json['hora'],
      dispensadores: (json['dispensadores'] as List)
          .map((dispensador) => DataListDispensador.fromJson(dispensador))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hora': hora,
      'dispensadores':
          dispensadores.map((dispensador) => dispensador.toJson()).toList(),
    };
  }
}

class DataListadoMeters {
  final List<DataListVolumenes> volumenes;

  DataListadoMeters({
    required this.volumenes,
  });

  factory DataListadoMeters.fromJson(List<dynamic> json) {
    return DataListadoMeters(
      volumenes:
          json.map((volumen) => DataListVolumenes.fromJson(volumen)).toList(),
    );
  }

  List<dynamic> toJson() {
    return volumenes.map((volumen) => volumen.toJson()).toList();
  }
}
