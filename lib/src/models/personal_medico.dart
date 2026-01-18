class PersonalMedico {
  final String id;
  final String nombres;
  final String? primerApellido;
  final String? segundoApellido;
  final String? nroDocumento;

  const PersonalMedico({
    required this.id,
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
    required this.nroDocumento,
  });

  factory PersonalMedico.fromJson(Map<String, dynamic> json) {
    return PersonalMedico(
      id: (json['id'] ?? '').toString(),
      nombres: (json['nombres'] ?? '').toString(),
      primerApellido: json['primerApellido']?.toString(),
      segundoApellido: json['segundoApellido']?.toString(),
      nroDocumento: json['nroDocumento']?.toString(),
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
