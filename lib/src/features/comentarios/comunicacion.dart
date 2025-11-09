import 'package:flutter/material.dart';
import 'package:alimenta_app/src/features/comentarios/services/comentarios_service.dart';
import 'package:alimenta_app/src/features/comentarios/stores/comentarios_store.dart';
import 'package:alimenta_app/src/features/comentarios/widgets/seccion_comentarios.dart';

class ComunicacionPage extends StatelessWidget {
  final String? idHistoriaClinica;
  final String baseUrl;

  const ComunicacionPage({
    super.key,
    required this.idHistoriaClinica,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (idHistoriaClinica == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no se ha realizado ninguna cita nutricional. Comuníquese con el administrador.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final service = ComentariosService(baseUrl);
    final store = ComentariosStore(
      service: service,
      idHistoriaClinica: idHistoriaClinica!,
    );

    return FutureBuilder(
      future: store.cargarComentarios(),
      builder: (context, snapshot) {
        return SeccionComentarios(store: store);
      },
    );
  }
}
