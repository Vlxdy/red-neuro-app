import 'package:flutter_test/flutter_test.dart';
import 'package:red_neuro_app/src/models/user.dart';

void main() {
  group('Usuario.fromJson', () {
    test('lee payload anidado en datos y conserva ids de rol', () {
      final payload = {
        'finalizado': true,
        'mensaje': 'ok',
        'datos': {
          'access_token': 'abc123',
          'id': '1',
          'usuario': 'ADMINISTRADOR',
          'correoElectronico': 'admin@test.com',
          'idUsuarioRol': '99',
          'idRol': '1',
          'rol': 'ADMINISTRADOR',
          'roles': [
            {
              'idRol': '1',
              'idUsuarioRol': '99',
              'rol': 'ADMINISTRADOR',
              'nombre': 'Administrador',
              'descripcion': 'desc',
              'modulos': [],
            },
          ],
          'persona': {
            'nombres': 'Admin',
            'primerApellido': 'Root',
            'segundoApellido': '',
            'tipoDocumento': 'CI',
            'nroDocumento': '123',
            'fechaNacimiento': '1990-01-01',
            'telefono': '77777777',
          },
        },
      };

      final user = Usuario.fromJson(payload);

      expect(user.accessToken, 'abc123');
      expect(user.idUsuarioRol, '99');
      expect(user.idRol, '1');
      expect(user.rol, 'ADMINISTRADOR');
      expect(user.roles, hasLength(1));
      expect(user.roles.first.idUsuarioRol, '99');
    });

    test('usa el primer rol como fallback cuando faltan ids planos', () {
      final payload = {
        'access_token': 'abc123',
        'id': '1',
        'usuario': 'ADMINISTRADOR',
        'correoElectronico': 'admin@test.com',
        'roles': [
          {
            'idRol': 7,
            'idUsuarioRol': 11,
            'rol': 'SUPERVISOR',
            'nombre': 'Supervisor',
            'descripcion': 'desc',
            'modulos': [],
          },
        ],
        'persona': {
          'nombres': 'Admin',
          'primerApellido': 'Root',
          'segundoApellido': '',
          'tipoDocumento': 'CI',
          'nroDocumento': '123',
          'fechaNacimiento': '1990-01-01',
          'telefono': '77777777',
        },
      };

      final user = Usuario.fromJson(payload);

      expect(user.idUsuarioRol, '11');
      expect(user.idRol, '7');
      expect(user.rol, 'SUPERVISOR');
    });
  });
}
