import 'package:camino_seguro/src/models/person.dart';

class Usuario extends Persona {
  late String correoElectronico;
  late String celular;
  late bool ciudadaniaDigital;
  String? id;
  String? estado;
  String? usuario;

  Usuario(
    super.fechaNacimiento,
    super.nombres,
    super.nroDocumento,
    super.primerApellido,
    super.segundoApellido,
    super.tipoDocumento,
    this.correoElectronico,
    this.celular, {
    this.id,
    this.ciudadaniaDigital = false,
    this.estado,
    this.usuario,
  });

  static get empty => Usuario('', '', '', '', '', '', '', '');

  Usuario.fromJson(Map<String, dynamic> json)
      : super.fromJson(json['persona']) {
    ciudadaniaDigital = json['ciudadania_digital'] ?? false;
    correoElectronico = json['correoElectronico'] ?? '';
    celular = json['celular'] ?? '';
    estado = json['estado'] ?? '';
    id = json['id'] ?? '';
    usuario = json['usuario'] ?? '';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['persona'] = super.toJson();
    data['ciudadania_digital'] = ciudadaniaDigital;
    data['correoElectronico'] = correoElectronico;
    data['celular'] = celular;
    data['estado'] = estado;
    data['id'] = id;
    data['usuario'] = usuario;

    return data;
  }

  Map<String, dynamic> toJsonUpdate() {
    final Map<String, dynamic> data = {};
    data.addEntries(super.toJson().entries);
    return data;
  }
}
