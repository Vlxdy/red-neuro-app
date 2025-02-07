import 'package:control_ventas_movil/src/ui/pages/login/componentes/app_info.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/login/componentes/credenciales.dart';
import 'package:control_ventas_movil/src/ui/pages/login/componentes/header_login_account.dart';

GlobalKey<ScaffoldMessengerState> loginAccountMessenger =
    GlobalKey<ScaffoldMessengerState>();

class LoginAccount extends StatefulWidget {
  const LoginAccount({super.key});

  @override
  State<LoginAccount> createState() => _LoginState();
}

class _LoginState extends State<LoginAccount> {
  // late LoginService service;
  @override
  void initState() {
    super.initState();
    // service = LoginService('', context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return TemplatePage(
      page: ScaffoldMessenger(
        key: loginAccountMessenger,
        child: Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const HeaderLoginAccount(false),
                      const SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Iniciar sesión',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.fontColor),
                        ),
                      ),
                      const Credenciales(),
                      const SizedBox(height: 20),
                      // BotonCiudadania(onPressed: service.loginCiudadania),
                      const AppInfo()
                    ],
                  ),
                )),
          ),
        ),
      ),
    );
  }
}
