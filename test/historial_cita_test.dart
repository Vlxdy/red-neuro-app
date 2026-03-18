import 'package:flutter_test/flutter_test.dart';
import 'package:red_neuro_app/src/models/historial_cita.dart';

void main() {
  group('HistorialCita.fromJson', () {
    test('lee historialCitaId en formato nuevo', () {
      final model = HistorialCita.fromJson({
        'id': '1',
        'citaId': '100',
        'historialCitaId': 'HIST-1',
      });

      expect(model.historialCitaId, 'HIST-1');
    });

    test('lee idHistorialCita como fallback legado', () {
      final model = HistorialCita.fromJson({
        'id': '1',
        'citaId': '100',
        'idHistorialCita': 'HIST-LEGACY',
      });

      expect(model.historialCitaId, 'HIST-LEGACY');
    });
  });
}
