import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/ui/common/snackbar/snackbar.dart';
import 'package:flutter/material.dart';

class SimpleAlert extends StatefulWidget {
  final String content;
  final StatusSnackBar? state;
  final Color? colorText;
  final bool showAlert;
  final bool animate;
  const SimpleAlert(this.content,
      {this.state = StatusSnackBar.info,
      this.showAlert = false,
      this.animate = true,
      this.colorText,
      super.key});

  @override
  State<SimpleAlert> createState() => _SimpleAlertState();
}

class _SimpleAlertState extends State<SimpleAlert>
    with SingleTickerProviderStateMixin {
  final _theme = ThemeController.instance;

  late Animation<double> _animation;
  late AnimationController _controller;

  Color _getColor(StatusSnackBar? state) {
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _animation = Tween<double>(begin: 5, end: 0).animate(_controller);
    _animation.addListener(() {
      setState(() {});
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
        !widget.showAlert
            ? 0
            : widget.animate
                ? _animation.value * 100
                : 0,
        -8,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 50, minHeight: 40),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border(
                    left: BorderSide(color: _getColor(widget.state), width: 6)),
                color: widget.state != null
                    ? _getColor(widget.state).withValues(alpha: .2)
                    : _theme.primary),
            child: Center(
              child: Text(
                widget.content,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: widget.colorText ??
                        _getColor(widget.state).withValues(alpha: .8),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
