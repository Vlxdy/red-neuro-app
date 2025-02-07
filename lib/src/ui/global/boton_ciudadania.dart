import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:control_ventas_movil/src/constants/resources.dart';

class BotonCiudadania extends StatelessWidget {
  final VoidCallback? onPressed;
  const BotonCiudadania({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return SimpleButton(
        // disabled: listener.isLoading,
        title: 'Iniciar con Ciudadanía Digital',
        background: theme.white,
        textColor: theme.primary,
        customPreffixicon: Padding(
          padding: const EdgeInsets.only(right: 5.0),
          child: SvgPicture.asset(
            Recursos.logoCiudadania,
            height: 35,
            width: 35,
            semanticsLabel: 'Logo Ciudadania',
          ),
        ),
        onTap: onPressed);
  }
}
