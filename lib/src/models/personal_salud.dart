class PersonalSalud {
  final String id;
  final String estado;
  final String? rol;
  final List<String> roles;
  final String nombres;
  final String? primerApellido;
  final String? segundoApellido;
  final String? nroDocumento;
  final String? fechaNacimiento;
  final String? telefono;
  final String? correoElectronico;
  final String? genero;
  final String? urlFoto;
  final String? ocupacion;

  const PersonalSalud({
    required this.id,
    required this.estado,
    required this.rol,
    required this.roles,
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
    required this.nroDocumento,
    required this.fechaNacimiento,
    required this.telefono,
    required this.correoElectronico,
    required this.genero,
    required this.urlFoto,
    required this.ocupacion,
  });

  factory PersonalSalud.fromJson(Map<String, dynamic> json) {
    final persona = json['persona'];
    String resolveString(String key) {
      final value = json[key] ??
          (persona is Map<String, dynamic> ? persona[key] : null);
      if (value == null) return '';
      return value.toString();
    }

    String? resolveOcupacion() {
      final ocupacionRaw = json['ocupacion'];
      if (ocupacionRaw != null && ocupacionRaw.toString().trim().isNotEmpty) {
        return ocupacionRaw.toString();
      }
      final ocupacionesRaw = json['ocupaciones'];
      if (ocupacionesRaw is List && ocupacionesRaw.isNotEmpty) {
        final first = ocupacionesRaw.first;
        if (first is Map<String, dynamic>) {
          return first['nombre']?.toString();
        }
      }
      return null;
    }

    final rol = resolveString('rol').trim();
    final rolesRaw = json['roles'];

    String? resolveRoleItem(dynamic item) {
      if (item == null) return null;
      if (item is String) {
        final value = item.trim();
        return value.isEmpty ? null : value;
      }
      if (item is Map<String, dynamic>) {
        final candidates = <dynamic>[
          item['rol'],
          item['nombre'],
          item['descripcion'],
        ];
        for (final candidate in candidates) {
          final value = candidate?.toString().trim() ?? '';
          if (value.isNotEmpty) return value;
        }
      }
      final value = item.toString().trim();
      return value.isEmpty ? null : value;
    }

    final roles = rolesRaw is List
        ? rolesRaw
            .map(resolveRoleItem)
            .whereType<String>()
            .toList()
        : <String>[];
    final rolesNormalizados = <String>[
      ...roles,
      if (rol.isNotEmpty) rol,
    ];
    final rolPrincipal = roles.isNotEmpty ? roles.first : rol;
    return PersonalSalud(
      id: (json['id'] ?? '').toString(),
      estado: (json['estado'] ?? 'ACTIVO').toString(),
      rol: rolPrincipal.isEmpty ? null : rolPrincipal,
      roles: rolesNormalizados.toSet().toList(),
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
      ocupacion: resolveOcupacion(),
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
