import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_neuro_app/src/config/dispositivo_service.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/plugins/utils/encode.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/text_inputs/text_input.dart';
import 'package:red_neuro_app/src/ui/global/loading_animation.dart';
import 'package:red_neuro_app/src/ui/pages/login/login_service.dart';

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
    final LoadingAnimation listener = context.watch<LoadingAnimation>();
    final ThemeController theme = ThemeController.instance;

    return Stack(
      children: <Widget>[
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
                  children: <Widget>[
                    CustomTextInput(
                      disable: listener.isLoading,
                      requiredData: true,
                      controller: _email,
                      title: 'Usuario',
                      onChange: (String value) =>
                          service.store.form.username = value,
                      validate: (String? value, String alias) =>
                          service.validateData(context, value, alias),
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      disable: listener.isLoading,
                      requiredData: true,
                      obscure: true,
                      controller: _password,
                      title: 'Contraseña',
                      onChange: (String value) =>
                          service.store.form.password = Encode.toBase64(value),
                      validate: (String? value, String alias) =>
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
