import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/models/cita.dart';

class CitasConfirmarSolicitadaResult {
  const CitasConfirmarSolicitadaResult();

  Map<String, dynamic> toRequestBody(CitaMedica _) => const {};
}

Future<CitasConfirmarSolicitadaResult?> showCitasConfirmarSolicitadaDialog({
  required BuildContext context,
  required CitaMedica cita,
  required DateFormat dateTimeFormat,
  String title = 'Confirmar cita solicitada',
}) async {
  final _ = dateTimeFormat;
  return showDialog<CitasConfirmarSolicitadaResult>(
    context: context,
    builder: (_) => _CitasConfirmarSolicitadaDialog(
      cita: cita,
      title: title,
    ),
  );
}

class _CitasConfirmarSolicitadaDialog extends StatelessWidget {
  const _CitasConfirmarSolicitadaDialog({
    required this.cita,
    required this.title,
  });

  final CitaMedica cita;
  final String title;

  String _capitalizar(String valor) {
    if (valor.isEmpty) return valor;
    return valor[0].toUpperCase() + valor.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final fechaLocal = cita.fechaInicio?.toLocal();
    final fechaFinLocal = cita.fechaFin?.toLocal();
    final lugarTexto = (cita.lugarNombre ?? cita.lugarId ?? '').trim();
    final diaSemanaTexto = fechaLocal == null
        ? 'Aún no se definió el día de la semana.'
        : _capitalizar(DateFormat('EEEE', 'es').format(fechaLocal));
    final fechaTexto = fechaLocal == null
        ? ''
        : _capitalizar(DateFormat("d 'de' MMMM 'de' y", 'es').format(fechaLocal));
    final horaTexto = fechaLocal == null
        ? 'Sin hora definida'
        : fechaFinLocal == null
        ? DateFormat('HH:mm').format(fechaLocal)
        : '${DateFormat('HH:mm').format(fechaLocal)} - ${DateFormat('HH:mm').format(fechaFinLocal)}';

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revisa la información de cuándo será la cita.',
          ),
          const SizedBox(height: 12),
          if (fechaLocal != null) ...[
            Text('Fecha: $fechaTexto'),
            const SizedBox(height: 8),
            Text('Día: $diaSemanaTexto'),
            const SizedBox(height: 8),
            Text('Hora: $horaTexto'),
          ] else ...[
            Text('Fecha: Sin fecha definida'),
            const SizedBox(height: 8),
            Text('Día: $diaSemanaTexto'),
            const SizedBox(height: 8),
            Text('Hora: $horaTexto'),
          ],
          if (lugarTexto.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lugar: $lugarTexto'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            const CitasConfirmarSolicitadaResult(),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
