import 'package:alimenta_app/src/features/comentarios/models/comentario_chat_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CardComentario extends StatelessWidget {
  const CardComentario({
    super.key,
    required this.comentario,
    this.esPropio = false,
    this.onResponder,
    this.onEditar,
    this.onEliminar,
    this.onDescargarArchivo,
    this.depth = 0,
    this.usuarioActualId,
  });

  final ComentarioChat comentario;
  final bool esPropio;
  final void Function(ComentarioChat comentario)? onResponder;
  final void Function(ComentarioChat comentario)? onEditar;
  final void Function(ComentarioChat comentario)? onEliminar;
  final Future<void> Function(ComentarioArchivo archivo)? onDescargarArchivo;
  final int depth;
  final String? usuarioActualId;

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = esPropio
        ? colorScheme.primary.withOpacity(0.08)
        : colorScheme.surfaceVariant;
    final borderRadius = BorderRadius.circular(12);

    return Container(
      margin: EdgeInsets.only(top: depth == 0 ? 12 : 8, left: depth * 24.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          Text(
            comentario.contenido,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (comentario.fueEditado)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Editado',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colorScheme.outline),
              ),
            ),
          if (comentario.archivos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: comentario.archivos
                  .map(
                    (archivo) => _AttachmentChip(
                      archivo: archivo,
                      onTap: archivo.urlDescarga.isNotEmpty &&
                              !(archivo.esTemporal)
                          ? () => onDescargarArchivo?.call(archivo)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ],
          if ((onResponder != null && !comentario.esRespuesta) ||
              onEditar != null ||
              onEliminar != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (onResponder != null && !comentario.esRespuesta)
                    TextButton.icon(
                      onPressed: () => onResponder!(comentario),
                      icon: const Icon(Icons.reply, size: 16),
                      label: const Text('Responder'),
                    ),
                  if (onEditar != null)
                    TextButton.icon(
                      onPressed: () => onEditar!(comentario),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar'),
                    ),
                  if (onEliminar != null)
                    TextButton.icon(
                      onPressed: () => onEliminar!(comentario),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Eliminar'),
                    ),
                ],
              ),
            ),
          if (comentario.respuestas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: comentario.respuestas
                    .map(
                    (respuesta) => CardComentario(
                      comentario: respuesta,
                      esPropio: usuarioActualId != null &&
                          respuesta.usuario.idUsuario == usuarioActualId,
                      onResponder: null,
                      onEditar: onEditar,
                      onEliminar: onEliminar,
                      onDescargarArchivo: onDescargarArchivo,
                      depth: depth + 1,
                      usuarioActualId: usuarioActualId,
                    ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final nombre = comentario.usuario.nombreCompleto.isNotEmpty
        ? comentario.usuario.nombreCompleto
        : 'Usuario';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    final fecha = _dateFormat.format(comentario.fechaCreacion);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          child: Text(inicial),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                fecha,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.archivo,
    this.onTap,
  });

  final ComentarioArchivo archivo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = archivo.pesoBytes != null && archivo.pesoBytes! > 0
        ? '${archivo.nombre} • ${_formatFileSize(archivo.pesoBytes!)}'
        : archivo.nombre;
    return InputChip(
      label: Text(label),
      avatar: const Icon(Icons.attach_file, size: 18),
      onPressed: onTap,
      disabledColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }

  String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
}
