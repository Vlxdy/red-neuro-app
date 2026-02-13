import 'package:red_neuro_app/src/models/estudio.dart';

class PersonalSalud {
  final String id;
  final String estado;
  final bool esSupervisor;
  final String nombres;
  final String? primerApellido;
  final String? segundoApellido;
  final String? nroDocumento;
  final String? fechaNacimiento;
  final String? telefono;
  final String? correoElectronico;
  final String? genero;
  final String? urlFoto;
  final List<EspecialidadResumen> especialidades;

  const PersonalSalud({
    required this.id,
    required this.estado,
    required this.esSupervisor,
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
    required this.nroDocumento,
    required this.fechaNacimiento,
    required this.telefono,
    required this.correoElectronico,
    required this.genero,
    required this.urlFoto,
    required this.especialidades,
  });

  factory PersonalSalud.fromJson(Map<String, dynamic> json) {
    final persona = json['persona'];
    String resolveString(String key) {
      final value = json[key] ??
          (persona is Map<String, dynamic> ? persona[key] : null);
      if (value == null) return '';
      return value.toString();
    }

    final especialidadesRaw = json['especialidades'] ?? [];

    return PersonalSalud(
      id: (json['id'] ?? '').toString(),
      estado: (json['estado'] ?? 'ACTIVO').toString(),
      esSupervisor: json['esSupervisor'] == true ||
          json['es_supervisor'] == true,
      nroDocumento: resolveString('nroDocumento').trim().isEmpty
          ? null
          : resolveString('nroDocumento'),
      nombres: resolveString('nombres'),
      primerApellido: resolveString('primerApellido').trim().isEmpty
          ? null
          : resolveString('primerApellido'),
      segundoApellido: resolveString('segundoApellido').trim().isEmpty
          ? null
          : resolveString('segundoApellido'),
      fechaNacimiento: resolveString('fechaNacimiento').trim().isEmpty
          ? null
          : resolveString('fechaNacimiento'),
      telefono: resolveString('telefono').trim().isEmpty
          ? null
          : resolveString('telefono'),
      correoElectronico: resolveString('correoElectronico').trim().isEmpty
          ? null
          : resolveString('correoElectronico'),
      genero: resolveString('genero').trim().isEmpty
          ? null
          : resolveString('genero'),
      urlFoto: resolveString('urlFoto').trim().isEmpty
          ? null
          : resolveString('urlFoto'),
      especialidades: especialidadesRaw is List
          ? especialidadesRaw
              .whereType<Map<String, dynamic>>()
              .map(EspecialidadResumen.fromJson)
              .toList()
          : const [],
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

  bool get estaActivo => estado.toUpperCase() == 'ACTIVO';
}
