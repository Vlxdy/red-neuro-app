import 'package:flutter_test/flutter_test.dart';
import 'package:red_neuro_app/src/models/personal_salud.dart';

void main() {
  group('PersonalSalud.fromJson', () {
    test('usa el primer rol del vector cuando no existe rol plano', () {
      final personal = PersonalSalud.fromJson({
        'id': '10',
        'estado': 'ACTIVO',
        'correoElectronico': 'medico@test.com',
        'persona': {
          'nombres': 'Ana',
          'primerApellido': 'Pérez',
          'nroDocumento': '123456',
        },
        'roles': [
          {
            'idRol': 2,
            'rol': 'MEDICO',
            'nombre': 'Médico',
          },
          {
            'idRol': 3,
            'rol': 'SUPERVISOR',
            'nombre': 'Supervisor',
          },
        ],
      });

      expect(personal.rol, 'MEDICO');
      expect(personal.roles, containsAll(<String>['MEDICO', 'SUPERVISOR']));
    });

    test('prioriza el primer rol del vector sobre el rol plano para edición', () {
      final personal = PersonalSalud.fromJson({
        'id': '11',
        'estado': 'ACTIVO',
        'rol': 'ADMINISTRADOR',
        'persona': {
          'nombres': 'Luis',
          'primerApellido': 'Gómez',
          'nroDocumento': '654321',
        },
        'roles': [
          {'rol': 'ENFERMERA'},
        ],
      });

      expect(personal.rol, 'ENFERMERA');
      expect(personal.roles.first, 'ENFERMERA');
      expect(personal.roles, contains('ADMINISTRADOR'));
    });
  });
}
