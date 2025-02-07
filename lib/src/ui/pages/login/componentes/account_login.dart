import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:go_router/go_router.dart';

class AccountLogin extends StatelessWidget {
  const AccountLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Column(
      children: [
        RichText(
            text: TextSpan(
          text: '¿Tienes una cuenta institucional?',
          style: TextStyle(color: theme.grey),
        )),
        TextButton(
            onPressed: () => context.pushNamed(RouteNames.loginAccount),
            child: Text(
              'Iniciar sesión con cuenta',
              style: TextStyle(color: theme.neutral),
            ))
      ],
    );
  }
}
