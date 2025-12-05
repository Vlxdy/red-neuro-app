import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/account_login.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/header.dart';

GlobalKey<ScaffoldMessengerState> loginMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return TemplatePage(
      page: ScaffoldMessenger(
        key: loginMessenger,
        child: Scaffold(
          backgroundColor: theme.background,
          body: const SafeArea(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeaderLogin(mensaje: 'Inicia sesión con tus credenciales'),
                    SizedBox(height: 16),
                    AccountLogin(),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
