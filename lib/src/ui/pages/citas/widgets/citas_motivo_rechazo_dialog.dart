import 'package:flutter/material.dart';

Future<String?> showCitasMotivoRechazoDialog({
  required BuildContext context,
  bool useRootNavigator = false,
}) {
  return showDialog<String>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: false,
    builder: (dialogContext) => const _MotivoRechazoDialog(),
  );
}

Future<bool?> showCitasMotivoRechazoSubmitDialog({
  required BuildContext context,
  required bool useRootNavigator,
  required Future<bool> Function(String motivo) onSubmit,
}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: false,
    builder: (dialogContext) => _MotivoRechazoDialog(onSubmit: onSubmit),
  );
}

class _MotivoRechazoDialog extends StatefulWidget {
  final Future<bool> Function(String motivo)? onSubmit;

  const _MotivoRechazoDialog({this.onSubmit});

  @override
  State<_MotivoRechazoDialog> createState() => _MotivoRechazoDialogState();
}

class _MotivoRechazoDialogState extends State<_MotivoRechazoDialog> {
  final _formKey = GlobalKey<FormState>();
  var _motivo = '';
  var _intentoEnvio = false;
  var _enviando = false;

  bool get _esModoEnvio => widget.onSubmit != null;

  Future<void> _confirmar() async {
    FocusScope.of(context).unfocus();
    if (!_intentoEnvio) {
      setState(() => _intentoEnvio = true);
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final motivoNormalizado = _motivo.trim();
    if (!_esModoEnvio) {
      Navigator.of(context).pop(motivoNormalizado);
      return;
    }

    setState(() => _enviando = true);
    final ok = await widget.onSubmit!(motivoNormalizado);
    if (!mounted) return;
    if (!ok) {
      setState(() => _enviando = false);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Motivo de rechazo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Escribe un motivo para continuar con el rechazo de la cita.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _intentoEnvio
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Motivo',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                enabled: !_enviando,
                initialValue: _motivo,
                maxLines: 4,
                minLines: 3,
                maxLength: 255,
                autofocus: true,
                textInputAction: TextInputAction.newline,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Escribe un motivo breve',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.72),
                  ),
                  helperText: 'Campo obligatorio.',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.22),
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.4,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                      width: 1.4,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Debes ingresar un motivo de rechazo.';
                  }
                  return null;
                },
                onChanged: (value) => _motivo = value,
              ),
              if (_enviando) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(minHeight: 3),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando
              ? null
              : () => Navigator.of(context).pop(_esModoEnvio ? false : null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _confirmar,
          child: Text(_enviando ? 'Rechazando...' : 'Rechazar'),
        ),
      ],
    );
  }
}
