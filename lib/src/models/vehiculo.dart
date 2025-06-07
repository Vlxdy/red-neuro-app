import 'package:camino_seguro/src/models/asignacion.dart';
import 'package:camino_seguro/src/models/combustible.dart';

class Vehiculo {
  String id;
  String placa;
  String servicio;
  String clase;
  String marca;
  String tipo;
  String modelo;
  String identidad;
  Combustible combustible;
  Asignacion asignacion;

  Vehiculo({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.placa,
    required this.tipo,
    required this.clase,
    required this.combustible,
    required this.servicio,
    required this.asignacion,
    required this.identidad,
  });

  static Vehiculo get empty => Vehiculo(
      id: '',
      marca: '',
      modelo: '',
      placa: '',
      tipo: '',
      clase: '',
      combustible: Combustible.empty,
      servicio: '',
      asignacion: Asignacion.empty,
      identidad: '');

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
        id: json['vehiculo']['id'] ?? '',
        marca: json['vehiculo']['marca'] ?? '',
        modelo: json['vehiculo']['modelo'] ?? '',
        placa: json['vehiculo']['placa'] ?? '',
        tipo: json['vehiculo']['tipo'] ?? '',
        clase: json['vehiculo']['clase'] ?? '',
        combustible: Combustible.empty,
        servicio: json['vehiculo']['tipoServicio'] ?? '',
        asignacion: Asignacion.fromJson(json),
        identidad: json['vehiculo']['identidad'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'marca': marca,
        'modelo': modelo,
        'placa': placa,
        'tipo': tipo,
        'clase': clase,
        'combustible': combustible,
        'servicio': servicio,
        'asignacion': asignacion,
        'identidad': identidad,
      };
}

class VehiculoNuevo {
  String crpva;
  String idBSisa;

  VehiculoNuevo(this.crpva, this.idBSisa);

  static empty() => VehiculoNuevo('', '');

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['crpva'] = crpva.trim();
    data['idBSisa'] = idBSisa.trim();
    return data;
  }
}
