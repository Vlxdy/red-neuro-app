import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/extensions/strings_extensions.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:flutter/material.dart';

class AvatarPerfil extends StatelessWidget {
  AvatarPerfil({super.key});

  final perfil = Auth.instance.profile;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.white,
          child: Text(
            '${perfil.nombres[0]}${perfil.primerApellido[0]}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: theme.fontColor),
          ),
        ),
        // Container(
        //   height: 120,
        //   width: 120,
        //   decoration: BoxDecoration(
        //     borderRadius: BorderRadius.circular(75),
        //     color: theme.monochromatic200,
        //   ),
        //   child: Center(
        //     child: Icon(Icons.person, color: theme.grey, size: 30),
        //   ),
        // ),
        const SizedBox(height: 20),
        Text(
          '${perfil.nombres.capitalize()} ${perfil.primerApellido.capitalize()}',
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: theme.fontColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        // Text(
        //   perfil.codigo ?? '',
        //   style: Theme.of(context)
        //       .textTheme
        //       .labelMedium!
        //       .copyWith(color: theme.grey),
        // )
      ],
    );
  }
}
