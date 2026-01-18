import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

final _theme = ThemeController.instance;

Color _getColor(StatusSnackBar state) {
  switch (state) {
    case StatusSnackBar.success:
      return _theme.success;
    case StatusSnackBar.error:
      return _theme.error;
    case StatusSnackBar.warning:
      return _theme.warning;
    case StatusSnackBar.info:
      return _theme.neutral;
    default:
      return _theme.primary;
  }
}

void showSnackBar(
  GlobalKey<ScaffoldMessengerState> key,
  String content, {
  StatusSnackBar? state,
  Color? colorText,
}) {
  final messenger = key.currentState;
  if (messenger == null || !messenger.mounted) return;
  final hasScaffold = Scaffold.maybeOf(messenger.context) != null;
  if (!hasScaffold) return;
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: _theme.transparent,
      elevation: 0,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 50, minHeight: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: state != null ? _getColor(state) : _theme.primary,
          ),
          child: Center(
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorText ?? _theme.fontColor),
            ),
          ),
        ),
      ),
    ),
  );
}

void showSimpleSnackBar(GlobalKey<ScaffoldMessengerState> key, String content) {
  key.currentState?.showSnackBar(SnackBar(content: Text(content)));
}

Future<void> showErrorDialog(BuildContext context, String message) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

enum StatusSnackBar { error, info, success, main, warning }
