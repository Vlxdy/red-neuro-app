import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/comentarios_store.dart';
import '../widgets/card_comentario.dart';
import '../widgets/editor_comentario.dart';

class SeccionComentarios extends StatelessWidget {
  final ComentariosStore store;

  const SeccionComentarios({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: Consumer<ComentariosStore>(
        builder: (context, store, _) {
          if (store.cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: store.comentarios.length,
                  itemBuilder: (context, index) {
                    final comentario = store.comentarios[index];
                    return CardComentario(comentario: comentario);
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: EditorComentario(
                  enviando: store.enviando,
                  onEnviar: (texto) async {
                    await store.agregarComentario('Usuario actual', texto);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
