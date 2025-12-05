import 'package:red_neuro_app/src/models/modulo.dart';

class Rol {
  String idRol;
  String idUsuarioRol;
  String rol;
  String nombre;
  String descripcion;
  List<Modulo> modulos;

  Rol({
    required this.idRol,
    required this.idUsuarioRol,
    required this.rol,
    required this.nombre,
    required this.descripcion,
    required this.modulos,
  });

  factory Rol.fromJson(Map<String, dynamic> json) => Rol(
        idRol: json['idRol'] ?? '',
        idUsuarioRol: json['idUsuarioRol'] ?? '',
        rol: json['rol'] ?? '',
        nombre: json['nombre'] ?? '',
        descripcion: json['descripcion'] ?? '',
        modulos: (json['modulos'] as List<dynamic>?)
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
        'modulos': modulos.map((m) => m.toJson()).toList(),
      };
}
