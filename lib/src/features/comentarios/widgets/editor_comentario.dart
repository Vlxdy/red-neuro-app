import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/features/comentarios/models/comentario_chat_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class EditorComentario extends StatefulWidget {
  EditorComentario({
    super.key,
    required this.enviando,
    required this.onSubmit,
    this.onValidationError,
    this.replyingTo,
    this.editing,
    this.onCancelReply,
    this.onCancelEdit,
    int? maxFiles,
    int? maxFileSizeBytes,
  })  : maxFiles = maxFiles ?? Constantes.chatMaxFiles,
        maxFileSizeBytes = maxFileSizeBytes ?? Constantes.chatMaxFileBytes;

  final bool enviando;
  final Future<void> Function(
    String contenido,
    List<ComentarioArchivoLocal> archivos,
  ) onSubmit;
  final void Function(String message)? onValidationError;
  final ComentarioChat? replyingTo;
  final ComentarioChat? editing;
  final VoidCallback? onCancelReply;
  final VoidCallback? onCancelEdit;
  final int maxFiles;
  final int maxFileSizeBytes;

  @override
  State<EditorComentario> createState() => _EditorComentarioState();
}

class _EditorComentarioState extends State<EditorComentario> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ComentarioArchivoLocal> _archivos = [];

  static const List<String> _allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
    'tiff',
    'svg',
    'mp3',
    'aac',
    'wav',
    'ogg',
    'webm',
    'flac',
    'mp4',
    'mov',
    'avi',
    'mpeg',
    'mpg',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EditorComentario oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing?.id != oldWidget.editing?.id) {
      _controller.text = widget.editing?.contenido ?? '';
      if (widget.editing != null) {
        _focusNode.requestFocus();
      }
    }
    if (widget.replyingTo == null && oldWidget.replyingTo != null) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _handleSubmit() async {
    final contenido = _controller.text.trim();
    if (contenido.isEmpty && _archivos.isEmpty) {
      widget.onValidationError
          ?.call('Escribe un mensaje o adjunta al menos un archivo.');
      return;
    }

    await widget.onSubmit(contenido, List.unmodifiable(_archivos));

    if (mounted) {
      setState(() {
        _archivos.clear();
      });
      _controller.clear();
    }
  }

  Future<void> _pickFiles() async {
    final remaining = widget.maxFiles - _archivos.length;
    if (remaining <= 0) {
      widget.onValidationError?.call(
        'Solo se permiten ${widget.maxFiles} archivos por mensaje.',
      );
      return;
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      allowedExtensions: _allowedExtensions,
      type: FileType.custom,
      withReadStream: false,
    );

    if (result == null) {
      return;
    }

    final selected = result.files.take(remaining).where((PlatformFile file) {
      if (file.size > widget.maxFileSizeBytes) {
        widget.onValidationError?.call(
          'El archivo "${file.name}" supera el límite de ${(widget.maxFileSizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB.',
        );
        return false;
      }
      return true;
    }).toList();

    setState(() {
      for (final file in selected) {
        _archivos.add(ComentarioArchivoLocal.fromPlatformFile(file));
      }
    });
  }

  void _removeFile(ComentarioArchivoLocal archivo) {
    setState(() {
      _archivos.removeWhere((item) => item.id == archivo.id);
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    final isReplying = widget.replyingTo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isReplying || isEditing)
          _buildContextBanner(isEditing: isEditing, isReplying: isReplying),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          minLines: 1,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: isEditing
                ? 'Editar comentario'
                : isReplying
                    ? 'Responder comentario'
                    : 'Escribe un mensaje',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        if (_archivos.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _archivos
                .map(
                  (archivo) => Chip(
                    label: Text(
                      '${archivo.nombre} • ${_formatFileSize(archivo.sizeBytes)}',
                    ),
                    onDeleted: () => _removeFile(archivo),
                  ),
                )
                .toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: widget.enviando ? null : _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Adjuntar'),
            ),
            FilledButton(
              onPressed: widget.enviando ? null : _handleSubmit,
              child: widget.enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Guardar cambios' : 'Enviar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextBanner({
    required bool isEditing,
    required bool isReplying,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isEditing ? Icons.edit : Icons.reply,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEditing
                  ? 'Editando tu comentario'
                  : 'Respondiendo a ${widget.replyingTo?.usuario.nombreCompleto ?? ''}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              if (isEditing) {
                widget.onCancelEdit?.call();
                _controller.clear();
              } else {
                widget.onCancelReply?.call();
              }
              setState(() {
                _archivos.clear();
              });
            },
          )
        ],
      ),
    );
  }
}
