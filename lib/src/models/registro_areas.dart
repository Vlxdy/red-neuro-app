import 'package:camino_seguro/src/models/area.dart';

class RegistroAreas {
  String idBitacora;
  List<Area> listaAreas;

  RegistroAreas({
    required this.idBitacora,
    required this.listaAreas,
  });

  static RegistroAreas get empty =>
      RegistroAreas(idBitacora: '', listaAreas: []);

  factory RegistroAreas.fromJson(Map<String, dynamic> json) => RegistroAreas(
        idBitacora: json['idBitacora'] ?? '',
        listaAreas: json['listaAreas'] != null
            ? List<Area>.from(json['listaAreas'].map((e) => Area.fromJson(e)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        'idBitacora': idBitacora,
        'listaAreas': listaAreas.map((e) => e.toJson()).toList(),
      };
}

class ItemRegistroArea {
  int index;
  RegistroAreas registro;
  ItemRegistroArea(this.index, this.registro);
}
