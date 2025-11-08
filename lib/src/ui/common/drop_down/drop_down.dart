import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/extensions/colores_extension.dart';
import 'package:alimenta_app/src/extensions/strings_extensions.dart';
import 'package:alimenta_app/src/plugins/utils/logger.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class DropDown extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double? width;
  final bool requiredData;
  final GlobalKey<DropdownButton2State> dropKey;
  final String label;
  final String? initialValue;
  final Function(String? value, String alias)? validate;
  final Function(String? value)? onChange;
  final bool disable;
  final String? borderColor;
  final String? labelColor;

  const DropDown(
      {super.key,
      this.label = '',
      required this.dropKey,
      required this.items,
      this.onChange,
      this.validate,
      this.requiredData = false,
      this.disable = false,
      this.width,
      this.borderColor,
      this.labelColor,
      this.initialValue});

  @override
  State<DropDown> createState() => _DropDownState();
}

class _DropDownState extends State<DropDown> {
  String? value;
  bool _error = false;
  void _openDropdown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.dropKey.currentState != null) {
        try {
          widget.dropKey.currentState!.callTap();
        } catch (e) {
          Logger.warning(
              "El dropdown ya está abierto o se produjo un error al abrirlo: $e");
        }
      } else {
        Logger.warning('DropdownButton2 state is null.');
      }
    });
  }

  List<DropdownMenuItem<String>> _dropItems(List<dynamic> data) {
    return data
        .map((key) => DropdownMenuItem<String>(
              value: key['id'].toString(),
              child: Text(
                key['label'].toString().capitalize(),
                overflow: TextOverflow.ellipsis,
              ),
            ))
        .toList();
  }

  _onChanged(String? newValue) {
    setState(() => value = newValue);
    if (widget.onChange != null) {
      widget.onChange!(newValue);
    }
  }

  @override
  void initState() {
    // value = widget.initialValue;
    value = widget.initialValue != '' ? widget.initialValue : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return GestureDetector(
      onTap: widget.disable ? null : _openDropdown,
      child: Column(
        children: [
          Container(
            height: 60 + (_error ? 24 : 0),
            constraints:
                BoxConstraints(maxWidth: widget.width ?? 150, minWidth: 80),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  border: Border.all(
                      color: widget.disable
                          ? theme.grey
                          : _error
                              ? theme.error
                              : widget.borderColor != null
                                  ? HexColor.fromHex(widget.borderColor)
                                  : theme.grey.withValues(alpha: .4)),
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                        text: TextSpan(
                            text: widget.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    color: _error
                                        ? theme.error
                                        : widget.disable
                                            ? theme.grey
                                            : widget.labelColor != null
                                                ? HexColor.fromHex(
                                                    widget.labelColor)
                                                : theme.fontColor,
                                    fontSize: 12),
                            children: [
                          TextSpan(
                            text: widget.requiredData ? ' (*)' : '',
                            style: TextStyle(
                                color: widget.disable
                                    ? theme.grey
                                    : widget.labelColor != null
                                        ? HexColor.fromHex(widget.labelColor)
                                        : theme.error,
                                fontSize: 12),
                          )
                        ])),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: DropdownButtonFormField2<String>(
                        // key: widget.dropKey,
                        dropdownButtonKey: widget.dropKey,
                        decoration:
                            const InputDecoration.collapsed(hintText: ''),
                        isExpanded: true,
                        isDense: true,
                        validator: (value) {
                          String? result;
                          setState(() {
                            _error = false;
                            if (widget.requiredData) {
                              if (widget.validate != null) {
                                result = widget.validate!(value, widget.label);
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
                        value: value,
                        onChanged: widget.disable ? null : _onChanged,
                        items: _dropItems(widget.items),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
