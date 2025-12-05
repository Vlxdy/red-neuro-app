import 'package:red_neuro_app/src/constants/resources.dart';
import 'package:flutter/material.dart';

class HeaderLogin extends StatelessWidget {
  final String mensaje;
  const HeaderLogin({required this.mensaje, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          height: 100,
          width: 250,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Recursos.logoPrincipal),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Text(
          'Bienvenido a Alimenta',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600),
        ),
        Align(
          child: Text(mensaje, style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }
}
