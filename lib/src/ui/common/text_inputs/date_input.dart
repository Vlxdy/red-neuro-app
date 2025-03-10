import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/extensions/colores_extension.dart';
import 'package:flutter/material.dart';

class CustomTimePicker extends StatefulWidget {
  final String title;
  final bool requiredData;
  final TextEditingController? controller;
  final Function(String value)? onChange;
  final VoidCallback? onTap;
  final Function(String? value, String alias)? validate;
  final bool disable;
  final bool disablePointer;
  final String placeholder;
  final String? borderColor;
  final String? labelColor;
  final int? linesLabel;
  final bool obscure;

  const CustomTimePicker({
    super.key,
    this.title = "",
    @required this.controller,
    this.requiredData = false,
    this.validate,
    this.onTap,
    this.onChange,
    this.placeholder = '',
    this.disable = false,
    this.disablePointer = false,
    this.borderColor,
    this.labelColor,
    this.linesLabel = 1,
    this.obscure = false,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  bool _error = false;

  void _selectTime(BuildContext context) async {
    final TimeOfDay initialTime = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        // Set the picked time into the controller's text
        widget.controller?.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          _selectTime(context); // Open the time picker when tapped
        }
      },
      child: Container(
        height: 60 + ((widget.linesLabel! - 1) * 10) + (_error ? 16 : 0),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.grey.withValues(alpha: .9),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  text: widget.title,
                  style: TextStyle(
                    color: _error
                        ? theme.error
                        : widget.disable
                            ? theme.grey
                            : widget.labelColor != null
                                ? HexColor.fromHex(widget.labelColor)
                                : theme.fontColor,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: widget.requiredData ? ' (*)' : '',
                      style: TextStyle(
                        color: widget.disable
                            ? theme.grey
                            : widget.labelColor != null
                                ? HexColor.fromHex(widget.labelColor)
                                : theme.error,
                        fontSize: 12,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: widget.controller,
                enabled: !widget.disable,
                onTap: () => _selectTime(context),
                readOnly: true,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintMaxLines: 1,
                  hintStyle: const TextStyle(fontSize: 12),
                  suffix: Icon(Icons.access_time, color: theme.primary),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  errorBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
