import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/extensions/colores_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextInput extends StatefulWidget {
  final String title;
  final bool requiredData;
  final TextEditingController? controller;
  final Function(String value)? onChange;
  final VoidCallback? onTap;
  final Function(String? value, String alias)? validate;
  final RegExp? textFiltering;
  final bool obscure;
  final int? lines;
  final bool disable;
  final bool disablePointer;
  final int? maxLength;
  final bool withBorder;
  final bool onlyNumbers;
  final String placeholder;
  final String? borderColor;
  final String? labelColor;
  final int? linesLabel;

  const CustomTextInput({
    super.key,
    this.title = "",
    @required this.controller,
    this.requiredData = false,
    this.obscure = false,
    this.validate,
    this.onTap,
    this.onChange,
    this.lines = 1,
    this.linesLabel = 1,
    this.placeholder = '',
    this.textFiltering,
    this.maxLength,
    this.disable = false,
    this.disablePointer = false,
    this.onlyNumbers = false,
    this.borderColor,
    this.labelColor,
    this.withBorder = true,
  });

  @override
  State<CustomTextInput> createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<CustomTextInput> {
  bool _error = false;
  late bool _visibleText;
  late FocusNode _focusNode;

  @override
  void initState() {
    _visibleText = false;
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return GestureDetector(
      onTap: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      },
      child: Container(
        height:
            (widget.obscure ? 68 : 60) +
            ((widget.linesLabel! - 1) * 10) +
            ((widget.lines! - 1) * 24 + (_error ? 16 : 0)),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: !widget.withBorder
                ? Colors.transparent
                : _error
                ? theme.error
                : widget.borderColor != null
                ? HexColor.fromHex(widget.borderColor)
                : theme.grey.withValues(alpha: .9),
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                focusNode: _focusNode,
                enabled: !(widget.disable || widget.disablePointer),
                maxLines: widget.lines,
                keyboardType: widget.onlyNumbers
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: [
                  ...widget.maxLength != null
                      ? [LengthLimitingTextInputFormatter(widget.maxLength)]
                      : [],
                  widget.textFiltering != null
                      ? FilteringTextInputFormatter.allow(widget.textFiltering!)
                      : FilteringTextInputFormatter.singleLineFormatter,
                  ...widget.onlyNumbers
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : [],
                ],
                obscureText: widget.obscure ? !_visibleText : false,
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
                controller: widget.controller,
                onTap: () {
                  if (widget.onTap != null) widget.onTap!();
                },
                onChanged: (String value) {
                  if (widget.onChange != null) widget.onChange!(value);
                },
                cursorColor: widget.labelColor != null
                    ? HexColor.fromHex(widget.labelColor)
                    : theme.primary,
                style: TextStyle(
                  color: widget.disable
                      ? theme.grey
                      : widget.labelColor != null
                      ? HexColor.fromHex(widget.labelColor)
                      : theme.fontColor,
                ),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintMaxLines: 1,
                  hintStyle: const TextStyle(fontSize: 12),
                  suffix: widget.obscure
                      ? GestureDetector(
                          onTap: () =>
                              setState(() => _visibleText = !_visibleText),
                          child: Icon(
                            _visibleText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: widget.labelColor != null
                                ? HexColor.fromHex(widget.labelColor)
                                : theme.fontColor,
                          ),
                        )
                      : const SizedBox(),
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

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
