class Persona {
  late String fechaNacimiento;
  late String nombres;
  late String nroDocumento;
  late String primerApellido;
  late String segundoApellido;
  late String tipoDocumento;

  Persona(this.fechaNacimiento, this.nombres, this.nroDocumento,
      this.primerApellido, this.segundoApellido, this.tipoDocumento);

  static empty() => Persona('', '', '', '', '', '');

  Persona.fromJson(Map<String, dynamic> json) {
    fechaNacimiento = json['fechaNacimiento'] ?? '';
    nombres = json['nombres'] ?? '';
    nroDocumento = json['nroDocumento'] ?? '';
    primerApellido = json['primerApellido'] ?? '';
    segundoApellido = json['segundoApellido'] ?? '';
    tipoDocumento = json['tipoDocumento'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['fechaNacimiento'] = fechaNacimiento;
    data['nombres'] = nombres;
    data['nroDocumento'] = nroDocumento;
    data['primerApellido'] = primerApellido;
    data['segundoApellido'] = segundoApellido;
    data['tipoDocumento'] = tipoDocumento;
    return data;
  }
}
