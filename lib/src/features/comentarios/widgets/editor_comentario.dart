import 'package:flutter/material.dart';

class EditorComentario extends StatefulWidget {
  final void Function(String texto) onEnviar;
  final bool enviando;

  const EditorComentario({
    super.key,
    required this.onEnviar,
    this.enviando = false,
  });

  @override
  State<EditorComentario> createState() => _EditorComentarioState();
}

class _EditorComentarioState extends State<EditorComentario> {
  final TextEditingController _controller = TextEditingController();

  void _handleEnviar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    widget.onEnviar(texto);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 18, child: Icon(Icons.person)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Escribe un comentario...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.enviando ? null : _handleEnviar,
          icon: widget.enviando
              ? const CircularProgressIndicator()
              : const Icon(Icons.send),
        ),
      ],
    );
  }
}
