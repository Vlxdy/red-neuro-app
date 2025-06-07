import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camino_seguro/src/config/dispositivo_service.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/plugins/utils/encode.dart';
import 'package:camino_seguro/src/ui/common/buttons/simple_button.dart';
import 'package:camino_seguro/src/ui/common/text_inputs/text_input.dart';
import 'package:camino_seguro/src/ui/global/loading_animation.dart';
import 'package:camino_seguro/src/ui/pages/login/login_service.dart';

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

    return Stack(
      children: [
        Center(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // sin bordes redondeados
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _scaffoldingFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextInput(
                      disable: listener.isLoading,
                      requiredData: true,
                      controller: _email,
                      title: 'Usuario',
                      onChange: (value) => service.store.form.username = value,
                      validate: (value, alias) =>
                          service.validateData(context, value, alias),
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      disable: listener.isLoading,
                      requiredData: true,
                      obscure: true,
                      controller: _password,
                      title: 'Contraseña',
                      onChange: (value) =>
                          service.store.form.password = Encode.toBase64(value),
                      validate: (value, alias) =>
                          service.validateData(context, value, alias),
                    ),
                    const SizedBox(height: 12),
                    SimpleButton(
                      disabled: listener.isLoading,
                      title: 'Iniciar sesión',
                      background: theme.primary,
                      textColor: theme.white,
                      onTap: () {
                        if (service.validateForm(_scaffoldingFormKey)) {
                          service.login();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
