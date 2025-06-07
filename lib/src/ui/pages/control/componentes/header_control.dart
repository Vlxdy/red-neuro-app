import 'package:camino_seguro/src/constants/resources.dart';
import 'package:flutter/material.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';

class HeaderControl extends StatelessWidget {
  final String titulo;
  final String subTitulo;
  final String nombreUsuario;
  final String regimiento;
  final String tipoFuerza;

  const HeaderControl({
    Key? key,
    required this.titulo,
    required this.subTitulo,
    required this.nombreUsuario,
    required this.regimiento,
    required this.tipoFuerza,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          height: 100,
          width: 250,
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(Recursos.logoPrincipal),
                  fit: BoxFit.contain)),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            titulo,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: theme.fontColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(subTitulo,
            style: TextStyle(
              fontSize: 16,
              color: theme.grey,
            )),
        const SizedBox(height: 4),
        Text(nombreUsuario,
            style: TextStyle(
              fontSize: 18,
              color: theme.black,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 2),
        Text(regimiento,
            style: TextStyle(
              fontSize: 16,
              color: theme.black,
            )),
        const SizedBox(height: 2),
        Text(tipoFuerza,
            style: TextStyle(
              fontSize: 16,
              color: theme.black,
            )),
      ],
    );
  }
}
