import 'package:red_neuro_app/src/constants/resources.dart';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/credenciales.dart';

GlobalKey<ScaffoldMessengerState> loginAccountMessenger =
    GlobalKey<ScaffoldMessengerState>();

class LoginAccount extends StatefulWidget {
  const LoginAccount({super.key});

  @override
  State<LoginAccount> createState() => _LoginState();
}

class _LoginState extends State<LoginAccount> {
  @override
  Widget build(BuildContext context) {
    return TemplatePage(
      page: ScaffoldMessenger(
        key: loginAccountMessenger,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3, // Adjust the opacity value as needed
                  child: Image.asset(
                    Recursos.logoPrincipal,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 70),
                        Image.asset(
                          Recursos.icono,
                          height: 250,
                          width: 350,
                        ),
                        const SizedBox(height: 5),
                        const Credenciales(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
