import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/extensions/colores_extension.dart';
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
  final String? initialValue;

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
    this.initialValue, // Added to constructor
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.controller != null) {
      widget.controller!.text = widget.initialValue!;
    }
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay initialTime = widget.controller?.text.isNotEmpty == true
        ? TimeOfDay.fromDateTime(
            DateTime.parse("2000-01-01 ${widget.controller!.text}:00"))
        : TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        widget.controller?.text = picked.format(context);
      });
      widget.onChange?.call(widget.controller!.text);
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
          _selectTime(context);
        }
      },
      child: Container(
        height: 60 + ((widget.linesLabel! - 1) * 10) + (_error ? 20 : 0),
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
                validator: (value) {
                  String? result;
                  setState(() {
                    _error = false;
                    if (widget.requiredData) {
                      if (widget.validate != null) {
                        result = widget.validate!(value, widget.title);
                        if (result != '') {
                          _error = true;
                        } else {
                          result = null;
                        }
                      }
                    }
                  });
                  return result;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
