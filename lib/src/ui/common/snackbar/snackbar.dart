import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/routes.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

final _theme = ThemeController.instance;
OverlayEntry? _activeSnackOverlay;
Timer? _activeSnackTimer;

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
  final overlayState = navigatorKey.currentState?.overlay;
  final currentContext = key.currentContext;
  final overlay = overlayState ??
      (currentContext != null
          ? Overlay.maybeOf(currentContext, rootOverlay: true)
          : null);
  if (overlay == null || content.trim().isEmpty) return;

  _activeSnackTimer?.cancel();
  _activeSnackOverlay?.remove();

  final overlayEntry = OverlayEntry(
    builder: (context) => _GlobalSnackBarOverlay(
      content: content,
      backgroundColor: state != null ? _getColor(state) : _theme.primary,
      colorText: colorText ?? _theme.fontColor,
      onClose: _removeActiveSnackOverlay,
    ),
  );

  _activeSnackOverlay = overlayEntry;
  overlay.insert(overlayEntry);
  _activeSnackTimer = Timer(
    const Duration(seconds: 6),
    _removeActiveSnackOverlay,
  );
}

void _removeActiveSnackOverlay() {
  _activeSnackTimer?.cancel();
  _activeSnackTimer = null;
  _activeSnackOverlay?.remove();
  _activeSnackOverlay = null;
}

void showSimpleSnackBar(GlobalKey<ScaffoldMessengerState> key, String content) {
  showSnackBar(key, content);
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

class _GlobalSnackBarOverlay extends StatelessWidget {
  const _GlobalSnackBarOverlay({
    required this.content,
    required this.backgroundColor,
    required this.colorText,
    required this.onClose,
  });

  final String content;
  final Color backgroundColor;
  final Color colorText;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final topInset = (mediaQuery?.padding.top ?? 0) + 8;

    return Positioned(
      top: topInset,
      left: 8,
      right: 8,
      child: IgnorePointer(
        ignoring: false,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: backgroundColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x29000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            content,
                            style: TextStyle(
                              color: colorText,
                              fontSize: 12,
                              height: 1.15,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                          tooltip: 'Cerrar mensaje',
                          splashRadius: 16,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.only(left: 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum StatusSnackBar { error, info, success, main, warning }
