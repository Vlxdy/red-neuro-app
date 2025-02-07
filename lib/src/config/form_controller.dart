import 'package:flutter/material.dart';

mixin FormController {
  bool validateForm(GlobalKey<FormState> formKey) {
    if (formKey.currentState != null) {
      return formKey.currentState!.validate();
    }
    return false;
  }

  String validateData(BuildContext context, String? value, String alias,
      {String? regExp, int? min, int? max, bool required = false}) {
    final existeValor = value != null || (value != null && value.isNotEmpty);
    if (required && !existeValor) {
      return '$alias es requerido';
    }
    if (!required && !existeValor) return '';
    if (regExp != null) {
      if (!RegExp(regExp).hasMatch(value!)) {
        return '$alias no válido';
      }
    }
    if (min != null) {
      if (value!.length < min) {
        return 'Mínimo $min caracteres';
      }
    }
    if (max != null) {
      if (value!.length > max) {
        return 'Máximo $max caracteres';
      }
    }
    return '';
  }
}
