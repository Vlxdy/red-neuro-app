
class RoleOptionData {
  final String codigo;
  final String nombre;

  const RoleOptionData({required this.codigo, required this.nombre});
}

class RoleUtils {
  static const String administrador = 'ADMINISTRADOR';
  static const String jefe = 'JEFE';
  static const String coordinador = 'COORDINADOR';
  static const String personal = 'PERSONAL';
  static const String profesionalInvitado = 'PROFESIONAL_INVITADO';

  static const List<String> explicitStaffRoles = <String>[
    administrador,
    jefe,
    coordinador,
    personal,
    profesionalInvitado,
  ];

  static const List<RoleOptionData> explicitStaffRoleOptions = <RoleOptionData>[
    RoleOptionData(codigo: administrador, nombre: 'Administrador'),
    RoleOptionData(codigo: jefe, nombre: 'Jefe'),
    RoleOptionData(codigo: coordinador, nombre: 'Coordinador'),
    RoleOptionData(codigo: personal, nombre: 'Personal'),
    RoleOptionData(codigo: profesionalInvitado, nombre: 'Profesional invitado'),
  ];

  static String normalizeRole(String? role) {
    final normalized = (role ?? '').trim().toUpperCase();
    switch (normalized) {
      case 'ADMIN':
        return administrador;
      case 'MEDICO':
      case 'PERSONAL_MEDICO':
      case 'PERSONAL_SALUD':
        return personal;
      case 'SUPERVISOR':
      case 'PERSONAL_SALUD_ADMIN':
        return jefe;
      default:
        return normalized;
    }
  }

  static String roleLabel(String? role) {
    switch (normalizeRole(role)) {
      case administrador:
        return 'Administrador';
      case jefe:
        return 'Jefe';
      case coordinador:
        return 'Coordinador';
      case personal:
        return 'Personal';
      case profesionalInvitado:
        return 'Profesional invitado';
      default:
        final value = (role ?? '').trim();
        if (value.isEmpty) return 'Sin rol';
        return value
            .toLowerCase()
            .split('_')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }

  static bool hasRole(dynamic profile, String role) {
    final normalized = normalizeRole(role);
    final roles = <String>{};

    final activeRole = normalizeRole(profile?.rol?.toString());
    if (activeRole.isNotEmpty) {
      roles.add(activeRole);
    }

    final rawRoles = profile?.roles;
    if (rawRoles is Iterable) {
      for (final item in rawRoles) {
        String roleName = '';
        if (item is Map<String, dynamic>) {
          roleName = (item['rol'] ?? '').toString();
        } else if (item is Map) {
          roleName = (item['rol'] ?? '').toString();
        } else {
          roleName = (item.rol ?? '').toString();
        }

        final normalizedRole = normalizeRole(roleName);
        if (normalizedRole.isNotEmpty) {
          roles.add(normalizedRole);
        }
      }
    }

    return roles.contains(normalized);
  }

  static bool canManageStaff(dynamic profile) =>
      hasRole(profile, administrador) || hasRole(profile, jefe);

  static bool canCoordinateOperation(dynamic profile) =>
      hasRole(profile, administrador) ||
      hasRole(profile, jefe) ||
      hasRole(profile, coordinador);

  static bool canViewAllAppointments(dynamic profile) =>
      canCoordinateOperation(profile);

  static List<String> creatableStaffRolesFor(String? authenticatedRole) {
    switch (normalizeRole(authenticatedRole)) {
      case administrador:
        return explicitStaffRoles;
      case jefe:
        return const <String>[coordinador, personal, profesionalInvitado];
      default:
        return const <String>[];
    }
  }
}
