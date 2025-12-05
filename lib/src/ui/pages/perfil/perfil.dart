import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';
import 'package:red_neuro_app/src/ui/pages/perfil/componentes/perfil_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
GlobalKey<ScaffoldMessengerState> perfilMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Perfil extends StatelessWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final profile = Auth.instance.profile;
    return ScaffoldMessenger(
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
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.isLight
                                  ? Colors.black.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: profile.urlFoto != null &&
                                  profile.urlFoto!.isNotEmpty &&
                                  Uri.tryParse(profile.urlFoto!) != null
                              ? Image.network(
                                  profile.urlFoto!.startsWith('http')
                                      ? profile.urlFoto!
                                      : '${Constantes.apiUrl}${profile.urlFoto!}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildAvatarFallback(theme, profile),
                                )
                              : _buildAvatarFallback(theme, profile),
                        ),
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
                          {"clave": "Celular", "valor": profile.telefono},
                          {
                            "clave": "Correo electrónico",
                            "valor": profile.correoElectronico
                          }
                        ]),
                  ],
                ),
              ),
            )));
  }
}

Widget _buildAvatarFallback(ThemeController theme, dynamic profile) {
  return Container(
    color: theme.primary,
    alignment: Alignment.center,
    child: Text(
      '${profile.nombres.isNotEmpty ? profile.nombres[0] : ''}'
      '${profile.primerApellido.isNotEmpty ? profile.primerApellido[0] : ''}',
      style: TextStyle(
        color: theme.white,
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
