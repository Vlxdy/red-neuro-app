import 'package:flutter/material.dart';
import 'package:alimenta_app/src/features/comentarios/services/comentarios_service.dart';
import 'package:alimenta_app/src/features/comentarios/stores/comentarios_store.dart';
import 'package:alimenta_app/src/features/comentarios/widgets/seccion_comentarios.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';

class ComunicacionPage extends StatelessWidget {
  const ComunicacionPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final profile = Auth.instance.profile;
    final idHistoriaClinica = profile.idHistoriaClinica;
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

    final service = ComentariosService('', context);
    final store = ComentariosStore(
      service: service,
      idHistoriaClinica: idHistoriaClinica,
    );

    return FutureBuilder(
      future: store.cargarComentarios(),
      builder: (context, snapshot) {
        return SeccionComentarios(store: store);
      },
    );
  }
}
