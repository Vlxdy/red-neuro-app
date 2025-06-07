import 'package:camino_seguro/src/plugins/utils/utils.dart';

class CConductor {
  String? nombreCompleto;
  String? ci;
  String? numeroLicencia;

  CConductor({
    this.nombreCompleto,
    this.ci,
    this.numeroLicencia,
  });

  factory CConductor.fromJson(Map<String, dynamic> json) => CConductor(
        nombreCompleto: json['nombreCompleto'],
        ci: json['ci'],
        numeroLicencia: json['numeroLicencia'],
      );

  Map<String, dynamic> toJson() => {
        'nombreCompleto': nombreCompleto,
        'ci': ci,
        'numeroLicencia': numeroLicencia,
      };
}

class ConductorNuevo {
  String tipoDocumento;
  String nroDocumento;
  String nombres;
  String primerApellido;
  String segundoApellido;
  String fechaNacimiento;
  String correoElectronico;

  ConductorNuevo(
    this.tipoDocumento,
    this.nroDocumento,
    this.nombres,
    this.primerApellido,
    this.segundoApellido,
    this.fechaNacimiento,
    this.correoElectronico,
  );

  static empty() => ConductorNuevo('', '', '', '', '', '', '');

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['tipoDocumento'] = tipoDocumento.trim();
    data['nroDocumento'] = nroDocumento.trim();
    data['nombres'] = nombres.trim();
    data['primerApellido'] = primerApellido.trim();
    data['segundoApellido'] = segundoApellido.trim();
    data['fechaNacimiento'] = fechaNacimiento;
    data['correoElectronico'] = correoElectronico;
    return data;
  }
}

class ConductorVehiculo {
  String? id;
  String? nombreCompleto;
  String? inicial;
  String? tipo;
  String? usuario;
  String? identidad;

  ConductorVehiculo({
    this.id,
    this.nombreCompleto,
    this.inicial,
    this.tipo,
    this.usuario,
    this.identidad,
  });

  factory ConductorVehiculo.fromJson(Map<String, dynamic> json) {
    final nombreCompleto = Utils.armarNombre(json['usuario']['persona']);
    final inicial =
        Utils.armarNombre(json['usuario']['persona'], iniciales: true);
    return ConductorVehiculo(
      id: json['id'] ?? '',
      nombreCompleto: nombreCompleto,
      inicial: inicial,
      tipo: json['tipo'] ?? '',
      usuario: json['usuario']['usuario'] ?? '',
      identidad: json['identidad'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombreCompleto': nombreCompleto,
        'inicial': inicial,
        'tipo': tipo,
        'usuario': usuario,
        'identidad': identidad,
      };
}
