class Persona {
  late String fechaNacimiento;
  late String nombres;
  late String nroDocumento;
  late String primerApellido;
  late String segundoApellido;
  late String tipoDocumento;
  String? telefono;

  Persona(
    this.fechaNacimiento,
    this.nombres,
    this.nroDocumento,
    this.primerApellido,
    this.segundoApellido,
    this.tipoDocumento, [
    this.telefono,
  ]);

  static Persona empty() => Persona('', '', '', '', '', '');

  Persona.fromJson(Map<String, dynamic> json) {
    fechaNacimiento = json['fechaNacimiento'] ?? '';
    nombres = json['nombres'] ?? '';
    nroDocumento = json['nroDocumento'] ?? '';
    primerApellido = json['primerApellido'] ?? '';
    segundoApellido = json['segundoApellido'] ?? '';
    tipoDocumento = json['tipoDocumento'] ?? '';
    telefono = json['telefono'];
  }

  Map<String, dynamic> toJson() => {
    'fechaNacimiento': fechaNacimiento,
    'nombres': nombres,
    'nroDocumento': nroDocumento,
    'primerApellido': primerApellido,
    'segundoApellido': segundoApellido,
    'tipoDocumento': tipoDocumento,
    'telefono': telefono,
  };
}
