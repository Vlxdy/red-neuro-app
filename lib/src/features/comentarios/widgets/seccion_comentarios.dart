import 'package:alimenta_app/src/features/comentarios/models/comentario_chat_models.dart';
import 'package:alimenta_app/src/features/comentarios/stores/comentarios_store.dart';
import 'package:alimenta_app/src/features/comentarios/widgets/card_comentario.dart';
import 'package:alimenta_app/src/features/comentarios/widgets/editor_comentario.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SeccionComentarios extends StatefulWidget {
  const SeccionComentarios({super.key});

  @override
  State<SeccionComentarios> createState() => _SeccionComentariosState();
}

class _SeccionComentariosState extends State<SeccionComentarios> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComentariosStore>().inicializar();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final store = context.read<ComentariosStore>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !store.cargandoMas &&
        !store.isLastPage) {
      store.cargarComentarios();
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComentariosStore>(
      builder: (context, store, _) {
        if (store.cargando && store.comentarios.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final comentarios = store.comentarios;
        final profile = Auth.instance.profile;
        final userId = profile.idUsuarioRol ?? '';

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  try {
                    await store.cargarComentarios(reset: true);
                  } catch (error) {
                    _showMessage(
                      context,
                      'No se pudieron actualizar los comentarios.',
                    );
                  }
                },
                child: comentarios.isEmpty
                    ? ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 32),
                        children: const [
                          Center(
                            child: Text(
                              'Aún no existen comentarios registrados.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            comentarios.length + (store.cargandoMas ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= comentarios.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }
                          final comentario = comentarios[index];
                          return CardComentario(
                            comentario: comentario,
                            esPropio: comentario.usuario.idUsuarioRol == userId,
                            usuarioActualId: userId,
                            onResponder: (comentarioSeleccionado) {
                              store.seleccionarRespuesta(
                                  comentarioSeleccionado);
                            },
                            onEditar: (comentarioSeleccionado) {
                              if (comentarioSeleccionado.usuario.idUsuario !=
                                  userId) {
                                _showMessage(
                                  context,
                                  'Solo puedes editar tus propios comentarios.',
                                );
                                return;
                              }
                              store
                                  .seleccionarEdicion(comentarioSeleccionado);
                            },
                            onEliminar: (comentarioSeleccionado) async {
                              if (comentarioSeleccionado.usuario.idUsuario !=
                                  userId) {
                                _showMessage(
                                  context,
                                  'Solo puedes eliminar tus propios comentarios.',
                                );
                                return;
                              }
                              try {
                                await store.eliminarComentario(
                                    comentarioSeleccionado.id);
                              } catch (error) {
                                _showMessage(
                                  context,
                                  'No se pudo eliminar el comentario.',
                                );
                              }
                            },
                            onDescargarArchivo:
                                (ComentarioArchivo archivo) async {
                              try {
                                await store.descargarArchivo(archivo);
                              } catch (error) {
                                _showMessage(
                                  context,
                                  'No se pudo descargar el archivo. Intenta nuevamente.',
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: EditorComentario(
                enviando: store.enviando,
                replyingTo: store.comentarioEnRespuesta,
                editing: store.comentarioEnEdicion,
                onCancelReply: () => store.seleccionarRespuesta(null),
                onCancelEdit: () => store.seleccionarEdicion(null),
                onValidationError: (message) => _showMessage(context, message),
                onSubmit: (contenido, archivos) async {
                  try {
                    if (store.comentarioEnEdicion != null) {
                      await store.editarComentario(
                        comentario: store.comentarioEnEdicion!,
                        contenido: contenido,
                      );
                      store.seleccionarEdicion(null);
                    } else if (store.comentarioEnRespuesta != null) {
                      await store.responderComentario(
                        padre: store.comentarioEnRespuesta!,
                        contenido: contenido,
                        archivos: archivos,
                      );
                      store.seleccionarRespuesta(null);
                    } else {
                      await store.enviarComentario(
                        contenido: contenido,
                        archivos: archivos,
                      );
                    }
                  } catch (error) {
                    _showMessage(
                      context,
                      'No se pudo enviar el comentario. Revisa tu conexión.',
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
