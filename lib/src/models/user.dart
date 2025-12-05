import 'package:red_neuro_app/src/models/person.dart';

class Usuario extends Persona {
  // Ya existentes
  late String correoElectronico;
  late bool ciudadaniaDigital;
  String? urlFoto;
  String? id;
  String? estado;
  String? usuario;

  // 🔹 Nuevos
  String accessToken = '';
  String? idUsuarioRol;
  String? idRol;
  String? rol;
  String? idHistoriaClinica;

  Usuario(
    super.fechaNacimiento,
    super.nombres,
    super.nroDocumento,
    super.primerApellido,
    super.segundoApellido,
    super.tipoDocumento,
    super.telefono, {
    this.id,
    this.usuario,
    required this.correoElectronico,
    this.urlFoto,
    this.estado,
    this.ciudadaniaDigital = false,
    this.accessToken = '',
    this.idUsuarioRol,
    this.idRol,
    this.rol,
    this.idHistoriaClinica,
  });

  static Usuario empty() =>
      Usuario('', '', '', '', '', '', '', correoElectronico: '');

  /// Soporta tanto json plano como con `datos`
  factory Usuario.fromJson(Map<String, dynamic> jsonRaw) {
    final json = (jsonRaw['datos'] is Map<String, dynamic>)
        ? (jsonRaw['datos'] as Map<String, dynamic>)
        : jsonRaw;

    // Persona
    final personaMap = (json['persona'] as Map<String, dynamic>?);

    final usuario = Usuario(
      personaMap?['fechaNacimiento'] ?? '',
      personaMap?['nombres'] ?? '',
      personaMap?['nroDocumento'] ?? '',
      personaMap?['primerApellido'] ?? '',
      personaMap?['segundoApellido'] ?? '',
      personaMap?['tipoDocumento'] ?? '',
      personaMap?['telefono'] ?? '',
      id: json['id']?.toString(),
      usuario: json['usuario']?.toString(),
      correoElectronico: json['correoElectronico']?.toString() ?? '',
      urlFoto: json['urlFoto']?.toString(),
      estado: json['estado']?.toString(),
      ciudadaniaDigital: json['ciudadania_digital'] == true, // puede no venir
    );

    // Tokens (acepta snake/camel)
    usuario.accessToken = (json['access_token'] ?? json['accessToken'] ?? '')
        .toString();

    // Identificadores de relación rol/usuario
    usuario.idUsuarioRol = json['idUsuarioRol']?.toString();
    usuario.idRol = json['idRol']?.toString();
    usuario.rol = json['rol']?.toString();

    // Historia clínica (puede venir en varios lugares; prioriza en `datos`)
    usuario.idHistoriaClinica = json['idHistoriaClinica']?.toString();

    return usuario;
  }

  @override
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['persona'] = super.toJson();
    data['id'] = id;
    data['usuario'] = usuario;
    data['correoElectronico'] = correoElectronico;
    data['urlFoto'] = urlFoto;
    data['estado'] = estado;
    data['ciudadania_digital'] = ciudadaniaDigital;

    // Nuevos
    data['access_token'] = accessToken;
    data['idUsuarioRol'] = idUsuarioRol;
    data['idRol'] = idRol;
    data['rol'] = rol;
    data['idHistoriaClinica'] = idHistoriaClinica;

    return data;
  }
}
