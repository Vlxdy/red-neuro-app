import 'package:red_neuro_app/src/features/comentarios/services/comentarios_service.dart';
import 'package:red_neuro_app/src/features/comentarios/stores/comentarios_store.dart';
import 'package:red_neuro_app/src/features/comentarios/widgets/seccion_comentarios.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ComunicacionPage extends StatelessWidget {
  const ComunicacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Auth.instance.profile;
    final idHistoriaClinica = profile.idHistoriaClinica;

    if (idHistoriaClinica == null || idHistoriaClinica.isEmpty) {
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

    return ChangeNotifierProvider<ComentariosStore>(
      create: (context) => ComentariosStore(
        service: ComentariosService(context),
        idHistoriaClinica: idHistoriaClinica,
      ),
      child: const _ComunicacionView(),
    );
  }
}

class _ComunicacionView extends StatelessWidget {
  const _ComunicacionView();

  @override
  Widget build(BuildContext context) {
    return const SeccionComentarios();
  }
}
