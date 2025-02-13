import 'package:control_ventas_movil/src/config/dispositivo_service.dart';
import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/plugins/utils/encode.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:control_ventas_movil/src/ui/common/text_inputs/text_input.dart';
import 'package:control_ventas_movil/src/ui/global/loading_animation.dart';
import 'package:control_ventas_movil/src/ui/pages/login/login_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Credenciales extends StatefulWidget {
  const Credenciales({super.key});

  @override
  State<Credenciales> createState() => _CredencialesState();
}

class _CredencialesState extends State<Credenciales> {
  final GlobalKey<FormState> _scaffoldingFormKey = GlobalKey<FormState>();

  late TextEditingController _email;
  late TextEditingController _password;

  late LoginService service;
  late DispositivoService dsService;

  LoadingAnimation loading = LoadingAnimation.instance;

  @override
  void initState() {
    super.initState();
    service = LoginService('', context);
    _email = TextEditingController(text: service.store.username);
    _password = TextEditingController(text: service.store.password);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loading.state = Overlay.of(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final listener = context.watch<LoadingAnimation>();
    final theme = ThemeController.instance;
    return Column(
      children: [
        Form(
            key: _scaffoldingFormKey,
            child: Column(
              children: [
                const SizedBox(
                  height: 35,
                ),
                Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CustomTextInput(
                        disable: listener.isLoading,
                        requiredData: true,
                        controller: _email,
                        title: 'Usuario',
                        onChange: (value) =>
                            service.store.form.username = value,
                        validate: (value, alias) => service.validateData(
                              context,
                              value,
                              alias,
                              // regExp: PatternRegexp.email,
                            ))),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CustomTextInput(
                        disable: listener.isLoading,
                        requiredData: true,
                        obscure: true,
                        controller: _password,
                        title: 'Contraseña',
                        onChange: (value) => service.store.form.password =
                            Encode.toBase64(value),
                        validate: (value, alias) =>
                            service.validateData(context, value, alias))),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: listener.isLoading
                        ? null
                        : () => context.pushNamed(RouteNames.olvideContrasena),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: theme.accent500),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SimpleButton(
                    disabled: listener.isLoading,
                    title: 'Iniciar sesión',
                    background: theme.primary700,
                    textColor: theme.white,
                    suffixicon: Icons.login,
                    onTap: () {
                      if (service.validateForm(_scaffoldingFormKey)) {
                        service.login();
                      }
                    }),
              ],
            )),
      ],
    );
  }
}
