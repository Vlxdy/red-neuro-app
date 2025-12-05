class Ciudadano {
  String sub;
  Profile profile;
  String fechaNacimiento;
  String email;
  String celular;

  Ciudadano({
    required this.sub,
    required this.profile,
    required this.fechaNacimiento,
    required this.celular,
    required this.email,
  });

  factory Ciudadano.fromJson(Map<String, dynamic> json) {
    return Ciudadano(
      sub: json['sub'] ?? '',
      profile: Profile.fromJson(json['profile']), // json['profile'] ?? '',
      fechaNacimiento: json['fecha_nacimiento'] ?? '',
      email: json['email'] ?? '',
      celular: json['celular'] ?? '',
    );
  }

  @override
  String toString() {
    return """
      sub: $sub
      profile: $profile
      fechaNacimiento: $fechaNacimiento
      email: $email
      celular: $celular
    """;
  }
}

//  {
//   sub: 748d0f6f-90ff-4ab7-835f-107036399176,
//   profile: {
//     documento_identidad: {
//       numero_documento: 9270816,
//       tipo_documento: CI
//     },
//     nombre: {
//       nombres: JUAN,
//       primer_apellido: PEREZ,
//       segundo_apellido: PEREZ
//     }
//   },
//   fecha_nacimiento: 09/02/2002,
//   email: 123456@yopmail.com,
//   celular: 77770011
// }

class Profile {
  DocumentoIdentidad documentoIdentidad;
  Nombre nombre;

  Profile({required this.documentoIdentidad, required this.nombre});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      documentoIdentidad: DocumentoIdentidad.fromJson(
        json['documento_identidad'],
      ),
      nombre: Nombre.fromJson(json['nombre']),
    );
  }
}

class DocumentoIdentidad {
  String numeroDocumento;
  String tipoDocumento;

  DocumentoIdentidad({
    required this.numeroDocumento,
    required this.tipoDocumento,
  });

  factory DocumentoIdentidad.fromJson(Map<String, dynamic> json) {
    return DocumentoIdentidad(
      numeroDocumento: json['numero_documento'].toString(),
      tipoDocumento: json['tipo_documento'],
    );
  }
}

class Nombre {
  String nombres;
  String primerApellido;
  String segundoApellido;

  Nombre({
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
  });

  factory Nombre.fromJson(Map<String, dynamic> json) {
    return Nombre(
      nombres: json['nombres'],
      primerApellido: json['primer_apellido'],
      segundoApellido: json['segundo_apellido'],
    );
  }
}
