import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';

class AutocompleteField<T extends Object> extends StatelessWidget {
  const AutocompleteField({
    required this.optionsBuilder,
    required this.displayStringForOption,
    required this.onSelected,
    required this.labelText,
    super.key,
    this.onChanged,
    this.loading = false,
    this.loadingText = 'Cargando...',
    this.emptyText = 'Sin resultados.',
    this.optionsHeaderText,
    this.optionsScrollController,
    this.isOptionSelected,
    this.selectedIconColor,
    this.maxOptionsHeight = 260,
    this.requiredData = false,
  });

  final Iterable<T> Function(TextEditingValue textEditingValue) optionsBuilder;
  final String Function(T option) displayStringForOption;
  final ValueChanged<T> onSelected;
  final ValueChanged<String>? onChanged;
  final bool loading;
  final String labelText;
  final String loadingText;
  final String emptyText;
  final String? optionsHeaderText;
  final ScrollController? optionsScrollController;
  final bool Function(T option)? isOptionSelected;
  final Color? selectedIconColor;
  final double maxOptionsHeight;
  final bool requiredData;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      optionsBuilder: optionsBuilder,
      displayStringForOption: displayStringForOption,
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, _) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: CustomTextInputStyles.decoration(
            label: labelText,
            requiredData: requiredData,
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more),
          ),
          onChanged: onChanged,
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        if (options.isEmpty) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  loading ? loadingText : emptyText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxOptionsHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (optionsHeaderText != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            optionsHeaderText!,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => FocusScope.of(context).unfocus(),
                          ),
                        ],
                      ),
                    ),
                  if (optionsHeaderText != null) const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: optionsScrollController,
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final selected = isOptionSelected?.call(option) ?? false;
                        return ListTile(
                          title: Text(displayStringForOption(option)),
                          trailing: selected
                              ? Icon(Icons.check, color: selectedIconColor)
                              : null,
                          enabled: !selected,
                          onTap: selected
                              ? null
                              : () => onSelectedOption(option),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
