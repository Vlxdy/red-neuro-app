import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/auth/auth.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/perfil/componentes/perfil_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

GlobalKey<ScaffoldMessengerState> perfilMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Perfil extends StatelessWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final profile = Auth.instance.profile;
    return TemplatePage(
        page: ScaffoldMessenger(
            key: perfilMessenger,
            child: Scaffold(
                backgroundColor: theme.background,
                appBar: AppBar(
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarBrightness:
                          theme.isDark ? Brightness.dark : Brightness.light,
                      statusBarColor: theme.transparent),
                  backgroundColor: theme.transparent,
                  centerTitle: true,
                  title: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfil',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 8),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: theme.accent900),
                            child: Text(
                                '${profile.nombres[0]}${profile.primerApellido[0]}',
                                style: TextStyle(
                                    color: theme.fontColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "${profile.nombres} ${profile.primerApellido} ${profile.segundoApellido}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        PerfilInfoCard(
                            bgColor: theme.white,
                            borderColor: theme.grey.withValues(alpha: .4),
                            headerIcon: Icons.person_outline_rounded,
                            headerTitle: 'Datitos personales',
                            items: [
                              {
                                "clave": "Nombres",
                                "valor":
                                    "${profile.nombres} ${profile.primerApellido} ${profile.segundoApellido}"
                              },
                              {
                                "clave": "Fecha de nacimiento",
                                "valor": profile.fechaNacimiento
                              },
                              {
                                "clave": "Número de documento",
                                "valor": profile.nroDocumento
                              },
                              {
                                "clave": "Tipo de documento",
                                "valor": profile.tipoDocumento
                              },
                            ]),
                        const SizedBox(
                          height: 20,
                        ),
                        PerfilInfoCard(
                            bgColor: theme.white,
                            borderColor: theme.grey.withValues(alpha: .4),
                            headerIcon: Icons.contact_page_outlined,
                            headerTitle: 'Datos de contacto',
                            items: [
                              {"clave": "Celular", "valor": profile.celular},
                              {
                                "clave": "Correo electrónico",
                                "valor": profile.correoElectronico
                              }
                            ]),
                      ],
                    ),
                  ),
                ))));
  }
}
