import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/login/componentes/header.dart';
import 'package:control_ventas_movil/src/ui/pages/login/login_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

GlobalKey<ScaffoldMessengerState> olvideContrasenaMessenger =
    GlobalKey<ScaffoldMessengerState>();

class OlvideContrasena extends StatefulWidget {
  const OlvideContrasena({super.key});

  @override
  State<OlvideContrasena> createState() => _OlvideContrasenaState();
}

class _OlvideContrasenaState extends State<OlvideContrasena> {
  late TextEditingController _controller;

  final GlobalKey<FormState> _formState = GlobalKey<FormState>();

  late LoginService service;

  @override
  void initState() {
    service = LoginService('', context);
    _controller = TextEditingController(text: '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return TemplatePage(
      page: ScaffoldMessenger(
        key: olvideContrasenaMessenger,
        child: Scaffold(
          backgroundColor: theme.transparent,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            elevation: 0,
            systemOverlayStyle: services.SystemUiOverlayStyle(
                statusBarBrightness:
                    theme.isDark ? Brightness.dark : Brightness.light,
                statusBarColor: theme.transparent),
            backgroundColor: theme.transparent,
          ),
          body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formState,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HeaderLogin(
                        mensaje: '¿Olvidaste tu contraseña?',
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Ingresa tu correo electrónico, enviaremos un enlace para que puedas recuperar tu cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.fontColor),
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        controller: _controller,
                        requiredData: true,
                        title: 'Correo electrónico',
                        validate: (value, alias) =>
                            service.validateData(context, value, alias),
                      ),
                      const SizedBox(height: 8),
                      SimpleButton(
                          title: 'Enviar',
                          onTap: () {
                            if (service.validateForm(_formState)) {
                              service.recuperarCuenta(_controller.value.text,
                                  'Revisa tu bandeja de correo, enviamos un enlace para que puedas recuperar tu cuenta');
                            }
                          })
                    ],
                  ),
                )),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
