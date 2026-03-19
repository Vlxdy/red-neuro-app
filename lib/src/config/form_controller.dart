import 'package:flutter/material.dart';

mixin FormController {
  bool validateForm(GlobalKey<FormState> formKey) {
    if (formKey.currentState != null) {
      return formKey.currentState!.validate();
    }
    return false;
  }

  String validateData(
    BuildContext context,
    String? value,
    String alias, {
    String? regExp,
    int? min,
    int? max,
    bool required = false,
  }) {
    final String sanitizedValue = value?.trim() ?? '';
    final bool existeValor = sanitizedValue.isNotEmpty;

    if (required && !existeValor) {
      return '$alias es requerido';
    }
    if (!required && !existeValor) return '';
    if (regExp != null) {
      if (!RegExp(regExp).hasMatch(sanitizedValue)) {
        return '$alias no válido';
      }
    }
    if (min != null) {
      if (sanitizedValue.length < min) {
        return 'Mínimo $min caracteres';
      }
    }
    if (max != null) {
      if (sanitizedValue.length > max) {
        return 'Máximo $max caracteres';
      }
    }
    return '';
  }
}
