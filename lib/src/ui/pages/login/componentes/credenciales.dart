import 'dart:ui';

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
    final Size screenSize = MediaQuery.sizeOf(context);
    final double formMaxWidth = screenSize.width < 420
        ? screenSize.width - 24
        : 420;
    final double responsiveTextScale =
        (screenSize.width / 390).clamp(0.90, 1.06);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: formMaxWidth),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(responsiveTextScale),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.background.withValues(
                    alpha: theme.isDark ? 0.24 : 0.42,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.white.withValues(
                      alpha: theme.isDark ? 0.28 : 0.60,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.black.withValues(
                        alpha: theme.isDark ? 0.22 : 0.09,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
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
                              service.store.form.password =
                                  Encode.toBase64(value),
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
          ),
        ),
      ),
    );
  }
}
