class Paciente {
  final String id;
  final String nombres;
  final String? primerApellido;
  final String? segundoApellido;
  final String? nroDocumento;
  final String? fechaNacimiento;
  final String? telefono;
  final String? genero;
  final String? observacion;
  final String estado;

  const Paciente({
    required this.id,
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
    required this.nroDocumento,
    required this.fechaNacimiento,
    required this.telefono,
    required this.genero,
    required this.observacion,
    required this.estado,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: (json['id'] ?? '').toString(),
      nombres: (json['nombres'] ?? '').toString(),
      primerApellido: json['primerApellido']?.toString(),
      segundoApellido: json['segundoApellido']?.toString(),
      nroDocumento: json['nroDocumento']?.toString(),
      fechaNacimiento: json['fechaNacimiento']?.toString(),
      telefono: json['telefono']?.toString(),
      genero: json['genero']?.toString(),
      observacion: json['observacion']?.toString(),
      estado: (json['estado'] ?? '').toString(),
    );
  }

  String get nombreCompleto {
    final parts = [
      nombres,
      if ((primerApellido ?? '').trim().isNotEmpty) primerApellido!.trim(),
      if ((segundoApellido ?? '').trim().isNotEmpty) segundoApellido!.trim(),
    ];
    return parts.join(' ').trim();
  }

  String get descripcionBreve {
    final nombre = nombreCompleto;
    if ((nroDocumento ?? '').trim().isEmpty) return nombre;
    return '$nombre · ${nroDocumento!.trim()}';
  }
}
