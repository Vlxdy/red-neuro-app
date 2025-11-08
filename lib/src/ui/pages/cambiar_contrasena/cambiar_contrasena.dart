import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alimenta_app/src/config/theme_controller.dart';
import 'package:alimenta_app/src/ui/common/buttons/simple_button.dart';
import 'package:alimenta_app/src/ui/common/text_inputs/text_input.dart';
import 'package:alimenta_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena_service.dart';
import 'package:alimenta_app/src/ui/pages/cambiar_contrasena/cambiar_contrasena_store.dart';
import 'package:provider/provider.dart';
import 'package:zxcvbn/zxcvbn.dart';

GlobalKey<ScaffoldMessengerState> cambiarContrasenaMessenger =
    GlobalKey<ScaffoldMessengerState>();

class CambiarContrasena extends StatefulWidget {
  const CambiarContrasena({super.key});

  @override
  State<CambiarContrasena> createState() => _CambiarContrasenaState();
}

class _CambiarContrasenaState extends State<CambiarContrasena> {
  late TextEditingController _contrasenaActualController;
  late TextEditingController _nuevaContrasenaController;
  late TextEditingController _repiteContrasenaController;

  final GlobalKey<FormState> _formularioKey = GlobalKey<FormState>();
  late CambiarContrasenaService _service;

  final zxcvbn = Zxcvbn();

  Color color(int score) {
    final theme = ThemeController.instance;
    switch (score) {
      case 0:
        return theme.error;
      case 1:
        return theme.error;
      case 2:
        return theme.warning;
      case 3:
        return theme.warning;
      case 4:
        return theme.success;
      default:
        return theme.neutral;
    }
  }

  @override
  void initState() {
    _contrasenaActualController = TextEditingController();
    _nuevaContrasenaController = TextEditingController();
    _repiteContrasenaController = TextEditingController();
    _service = CambiarContrasenaService('', context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final store = context.watch<CambiarContrasenaStore>();
    return ScaffoldMessenger(
      key: cambiarContrasenaMessenger,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          elevation: 0,
          title: const Text('Cambiar contraseña'),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarBrightness:
                  theme.isDark ? Brightness.dark : Brightness.light,
              statusBarColor: theme.transparent),
          backgroundColor: theme.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formularioKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('* Las contraseñas deben tener 8 caracteres o más',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: theme.grey)),
                  Text(
                      '* Las buenas contraseñas son dificiles de adivinar y usan palabras, números, símbolos y letras mayúsculas poco comunes.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: theme.grey)),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    requiredData: true,
                    obscure: true,
                    controller: _contrasenaActualController,
                    title: 'Contraseña actual',
                    onChange: (String? value) => store.contrasena = value ?? '',
                    validate: (value, alias) =>
                        _service.validateData(context, value, alias),
                  ),
                  const SizedBox(height: 8),
                  CustomTextInput(
                    requiredData: true,
                    obscure: true,
                    controller: _nuevaContrasenaController,
                    title: 'Nueva contraseña',
                    onChange: (String? value) {
                      store.nuevaContrasena = value ?? '';
                      if (value != null && value.isNotEmpty) {
                        final result = zxcvbn.evaluate(value);
                        store.calificacion = result.score ?? 0.0;
                      }
                    },
                    validate: (value, alias) =>
                        _service.validateData(context, value, alias),
                  ),
                  _nuevaContrasenaController.text.length > 1
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nivel de seguridad',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: theme.fontColor)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: store.calificacion * 0.25,
                                color: color(store.calificacion.toInt()),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                  const SizedBox(height: 8),
                  CustomTextInput(
                    requiredData: true,
                    obscure: true,
                    controller: _repiteContrasenaController,
                    title: 'Repite la nueva contraseña',
                    onChange: (String? value) =>
                        store.repiteContrasena = value ?? '',
                    validate: (value, alias) =>
                        _service.validateData(context, value, alias),
                  ),
                  const SizedBox(height: 16),
                  SimpleButton(
                      title: 'Modificar',
                      onTap: () {
                        if (_service.validarForm(
                            _formularioKey, 'Las contraseñas no coinciden')) {
                          _service.cambiarContrasena();
                        }
                      })
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _repiteContrasenaController.dispose();
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    super.dispose();
  }
}
