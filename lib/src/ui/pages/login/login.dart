import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/account_login.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/app_info.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/header.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/login_decor_background.dart';

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
    return TemplatePage(
      background: const LoginDecorBackground(),
      page: ScaffoldMessenger(
        key: loginMessenger,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  HeaderLogin(mensaje: 'Inicia sesión con tus credenciales'),
                  SizedBox(height: 16),
                  AccountLogin(),
                  const AppInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
