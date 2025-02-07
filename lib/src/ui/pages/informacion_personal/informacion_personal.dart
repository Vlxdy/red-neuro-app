import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/plugins/utils/utils.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/mi_cuenta/componentes/avatar_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InformacionPersonal extends StatelessWidget {
  const InformacionPersonal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final profile = Auth.instance.profile;
    return TemplatePage(
      page: Scaffold(
        backgroundColor: theme.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarBrightness:
                  theme.isDark ? Brightness.dark : Brightness.light,
              statusBarColor: theme.transparent),
          backgroundColor: theme.transparent,
        ),
        body: ListView(
          children: [
            AvatarPerfil(),
            ListTile(
              title: Text(
                'Correo electrónico',
                style: TextStyle(color: theme.fontColor),
              ),
              subtitle: Text(
                profile.correoElectronico,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: theme.grey),
              ),
            ),
            ListTile(
              tileColor: theme.monochromatic50,
              title: Text(
                'Número de documento',
                style: TextStyle(color: theme.fontColor),
              ),
              subtitle: Text(
                  '${profile.tipoDocumento}: ${profile.nroDocumento}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: theme.grey)),
            ),
            ListTile(
              title: Text(
                'Fecha de nacimiento',
                style: TextStyle(color: theme.fontColor),
              ),
              subtitle: Text(
                  profile.fechaNacimiento.isEmpty
                      ? 'Sin datos'
                      : Utils.formatearFecha(profile.fechaNacimiento),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: theme.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
