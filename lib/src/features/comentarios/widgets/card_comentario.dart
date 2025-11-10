import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/features/comentarios/models/comentario_chat_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor = esPropio
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.surfaceContainerHighest;
    final BorderRadius borderRadius = BorderRadius.circular(12);

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
          const SizedBox(height: 2),
          Html(
            data:
                comentario.contenido, // ← este es el HTML que viene del backend
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(12),
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
              ),
            },
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
            const SizedBox(height: 2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: comentario.archivos
                  .map(
                    (ComentarioArchivo archivo) => _AttachmentChip(
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
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  if (onResponder != null && !comentario.esRespuesta)
                    TextButton.icon(
                      onPressed: () => onResponder!(comentario),
                      icon: const Icon(Icons.reply, size: 16),
                      label: const Text('Responder'),
                    ),
                  if (onEditar != null && esPropio)
                    TextButton.icon(
                      onPressed: () => onEditar!(comentario),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar'),
                    ),
                  if (onEliminar != null && esPropio)
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
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: comentario.respuestas
                    .map(
                      (ComentarioChat respuesta) => CardComentario(
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
    final theme = ThemeController.instance;
    final usuario = comentario.usuario;

    final String nombre =
        usuario.nombreCompleto.isNotEmpty ? usuario.nombreCompleto : 'Usuario';
    final String fecha = _dateFormat.format(comentario.fechaCreacion);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: usuario.urlFoto != null &&
                    usuario.urlFoto!.isNotEmpty &&
                    Uri.tryParse(usuario.urlFoto!) != null
                ? Image.network(
                    usuario.urlFoto!.startsWith('http')
                        ? usuario.urlFoto!
                        : '${Constantes.apiUrl}${usuario.urlFoto!}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarFallback(theme, usuario),
                  )
                : _buildAvatarFallback(theme, usuario),
          ),
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
    final String label = archivo.pesoBytes != null && archivo.pesoBytes! > 0
        ? '${archivo.nombre} • ${_formatFileSize(archivo.pesoBytes!)}'
        : archivo.nombre;
    return InputChip(
      label: Text(label),
      avatar: const Icon(Icons.attach_file, size: 18),
      onPressed: onTap,
      disabledColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  String _formatFileSize(int bytes) {
    const List<String> units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
}

Widget _buildAvatarFallback(ThemeController theme, dynamic usuario) {
  return Container(
    color: theme.primary,
    alignment: Alignment.center,
    child: Text(
      '${usuario.nombres.isNotEmpty ? usuario.nombres[0] : ''}'
      '${usuario.primerApellido.isNotEmpty ? usuario.primerApellido[0] : ''}',
      style: TextStyle(
        color: theme.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
