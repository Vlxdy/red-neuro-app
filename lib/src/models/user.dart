import 'package:alimenta_app/src/models/person.dart';
import 'package:alimenta_app/src/models/rol.dart';

class Usuario extends Persona {
  late String id;
  late String usuario;
  late String correoElectronico;
  String? urlFoto;
  late String estado;
  late List<Rol> roles;
  String? idRol;

  Usuario(
    super.fechaNacimiento,
    super.nombres,
    super.nroDocumento,
    super.primerApellido,
    super.segundoApellido,
    super.tipoDocumento,
    super.telefono, {
    required this.id,
    required this.usuario,
    required this.correoElectronico,
    this.urlFoto,
    required this.estado,
    required this.roles,
    this.idRol,
  });

  /// ✅ Crea un usuario vacío
  factory Usuario.empty() => Usuario(
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        id: '',
        usuario: '',
        correoElectronico: '',
        estado: '',
        roles: [],
      );

  /// ✅ Crea desde JSON
  factory Usuario.fromJson(Map<String, dynamic> json) {
    final datos = json['datos'] ?? json; // por si llega con o sin "datos"
    final persona = datos['persona'] ?? {};

    return Usuario(
      persona['fechaNacimiento'] ?? '',
      persona['nombres'] ?? '',
      persona['nroDocumento'] ?? '',
      persona['primerApellido'] ?? '',
      persona['segundoApellido'] ?? '',
      persona['tipoDocumento'] ?? '',
      persona['telefono'] ?? '',
      id: datos['id'] ?? '',
      usuario: datos['usuario'] ?? '',
      correoElectronico: datos['correoElectronico'] ?? '',
      urlFoto: datos['urlFoto'],
      estado: datos['estado'] ?? '',
      roles: (datos['roles'] as List<dynamic>?)
              ?.map((r) => Rol.fromJson(r))
              .toList() ??
          [],
      idRol: datos['idRol'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario': usuario,
        'correoElectronico': correoElectronico,
        'urlFoto': urlFoto,
        'estado': estado,
        'roles': roles.map((r) => r.toJson()).toList(),
        'persona': super.toJson(),
        'idRol': idRol,
      };
}
