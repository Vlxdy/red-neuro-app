import 'package:red_neuro_app/src/models/modulo.dart';

class Rol {
  String idRol;
  String idUsuarioRol;
  String rol;
  String nombre;
  String descripcion;
  bool esSupervisor;
  List<Modulo> modulos;

  Rol({
    required this.idRol,
    required this.idUsuarioRol,
    required this.rol,
    required this.nombre,
    required this.descripcion,
    required this.esSupervisor,
    required this.modulos,
  });

  factory Rol.fromJson(Map<String, dynamic> json) => Rol(
    idRol: json['idRol']?.toString() ?? '',
    idUsuarioRol: json['idUsuarioRol']?.toString() ?? '',
    rol: json['rol']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    descripcion: json['descripcion']?.toString() ?? '',
    esSupervisor: json['esSupervisor'] == true || json['es_supervisor'] == true,
    modulos:
        (json['modulos'] as List<dynamic>?)
            ?.map((m) => Modulo.fromJson(m))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'idRol': idRol,
    'idUsuarioRol': idUsuarioRol,
    'rol': rol,
    'nombre': nombre,
    'descripcion': descripcion,
    'esSupervisor': esSupervisor,
    'modulos': modulos.map((m) => m.toJson()).toList(),
  };
}
