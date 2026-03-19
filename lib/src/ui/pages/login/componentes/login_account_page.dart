import 'package:red_neuro_app/src/constants/resources.dart';
import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/global/template_page.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/credenciales.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/app_info.dart';
import 'package:red_neuro_app/src/ui/pages/login/componentes/login_decor_background.dart';

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
    final theme = ThemeController.instance;
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool compactHeight = screenSize.height < 700;
    final double logoWidth = (screenSize.width * 0.72).clamp(190.0, 350.0);
    final double logoHeight = (screenSize.height * 0.28).clamp(130.0, 250.0);

    return TemplatePage(
      background: const LoginDecorBackground(),
      page: ScaffoldMessenger(
        key: loginAccountMessenger,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: compactHeight ? 24 : 70),
                    Image.asset(
                      Recursos.iconoFor(isDark: theme.isDark),
                      height: logoHeight,
                      width: logoWidth,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 5),
                    const Credenciales(),
                    const SizedBox(height: 8),
                    const AppInfo(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
