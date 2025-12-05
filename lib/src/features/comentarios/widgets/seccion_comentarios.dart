import 'package:red_neuro_app/src/features/comentarios/stores/comentarios_store.dart';
import 'package:red_neuro_app/src/features/comentarios/widgets/card_comentario.dart';
import 'package:red_neuro_app/src/features/comentarios/widgets/editor_comentario.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SeccionComentarios extends StatefulWidget {
  const SeccionComentarios({super.key});

  @override
  State<SeccionComentarios> createState() => _SeccionComentariosState();
}

class _SeccionComentariosState extends State<SeccionComentarios> {
  late final ScrollController _scrollController;
  bool _mostrarEditor = false;

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

        final tieneAccionActiva = store.comentarioEnEdicion != null ||
            store.comentarioEnRespuesta != null;

        if (tieneAccionActiva && !_mostrarEditor) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _mostrarEditor = true;
              });
            }
          });
        }

        final debeMostrarEditor = _mostrarEditor || tieneAccionActiva;
        final mediaQuery = MediaQuery.of(context);
        final bottomSafeArea = mediaQuery.padding.bottom;
        final bottomInset = mediaQuery.viewInsets.bottom;
        final keyboardOverlap =
            bottomInset > bottomSafeArea ? bottomInset - bottomSafeArea : 0.0;
        // const fabHeight = 56.0;
        // final listBottomPadding = debeMostrarEditor
        //     ? bottomSafeArea + 16
        //     : bottomSafeArea + 16 + fabHeight + 24;

        return AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: keyboardOverlap),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        triggerMode: RefreshIndicatorTriggerMode.anywhere,
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
                                reverse: false,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                // padding: EdgeInsets.fromLTRB(
                                //   16,
                                //   listBottomPadding,
                                //   16,
                                //   32,
                                // ),
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
                                reverse: false,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                // padding: EdgeInsets.fromLTRB(
                                //   16,
                                //   listBottomPadding,
                                //   16,
                                //   16,
                                // ),
                                itemCount: comentarios.length +
                                    (store.cargandoMas ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= comentarios.length) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  final comentario = comentarios[index];
                                  return AnimatedScale(
                                    key: ValueKey(comentario.id),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    scale: comentario.esNuevo ? 1.05 : 1.0,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 600),
                                      curve: Curves.easeOut,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: comentario.esNuevo
                                            ? Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withOpacity(0.12)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: comentario.esNuevo
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withOpacity(0.6)
                                              : Colors.transparent,
                                          width: comentario.esNuevo ? 1.5 : 0.5,
                                        ),
                                      ),
                                      child: CardComentario(
                                        comentario: comentario,
                                        esPropio:
                                            comentario.usuario.idUsuarioRol ==
                                                userId,
                                        usuarioActualId: userId,
                                        onResponder: (comentarioSeleccionado) {
                                          setState(() => _mostrarEditor = true);
                                          store.seleccionarRespuesta(
                                              comentarioSeleccionado);
                                        },
                                        onEditar: (comentarioSeleccionado) {
                                          if (comentarioSeleccionado
                                                  .usuario.idUsuario !=
                                              userId) {
                                            _showMessage(context,
                                                'Solo puedes editar tus propios comentarios.');
                                            return;
                                          }
                                          setState(() => _mostrarEditor = true);
                                          store.seleccionarEdicion(
                                              comentarioSeleccionado);
                                        },
                                        onEliminar:
                                            (comentarioSeleccionado) async {
                                          if (comentarioSeleccionado
                                                  .usuario.idUsuario !=
                                              userId) {
                                            _showMessage(context,
                                                'Solo puedes eliminar tus propios comentarios.');
                                            return;
                                          }
                                          try {
                                            await store.eliminarComentario(
                                                comentarioSeleccionado.id);
                                          } catch (_) {
                                            _showMessage(context,
                                                'No se pudo eliminar el comentario.');
                                          }
                                        },
                                        onDescargarArchivo: (archivo) async {
                                          try {
                                            await store
                                                .descargarArchivo(archivo);
                                          } catch (_) {
                                            _showMessage(context,
                                                'No se pudo descargar el archivo.');
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    if (debeMostrarEditor) ...[
                      const Divider(height: 1),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: EditorComentario(
                            enviando: store.enviando,
                            replyingTo: store.comentarioEnRespuesta,
                            editing: store.comentarioEnEdicion,
                            onCancelReply: () {
                              store.seleccionarRespuesta(null);
                              if (mounted) {
                                setState(() {
                                  _mostrarEditor = false;
                                });
                              }
                            },
                            onCancelEdit: () {
                              store.seleccionarEdicion(null);
                              if (mounted) {
                                setState(() {
                                  _mostrarEditor = false;
                                });
                              }
                            },
                            onCancel: () {
                              store.seleccionarRespuesta(null);
                              store.seleccionarEdicion(null);
                              if (mounted) {
                                setState(() {
                                  _mostrarEditor = false;
                                });
                              }
                            },
                            onValidationError: (message) =>
                                _showMessage(context, message),
                            onSubmit: (contenido, archivos) async {
                              try {
                                if (store.comentarioEnEdicion != null) {
                                  await store.editarComentario(
                                    comentario: store.comentarioEnEdicion!,
                                    contenido: contenido,
                                  );
                                  store.seleccionarEdicion(null);
                                } else if (store.comentarioEnRespuesta !=
                                    null) {
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
                                if (mounted) {
                                  setState(() {
                                    _mostrarEditor = false;
                                  });
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
                      ),
                    ],
                  ],
                ),
                if (!debeMostrarEditor)
                  Positioned(
                      bottom: 24 + bottomSafeArea,
                      right: 24,
                      child: FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            _mostrarEditor = true;
                          });
                        },
                        child: const Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.add_comment_rounded,
                              size: 30,
                            ),
                          ],
                        ),
                      )),
              ],
            ));
      },
    );
  }
}
