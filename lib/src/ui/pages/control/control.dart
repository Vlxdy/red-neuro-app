import 'package:camino_seguro/src/plugins/auth/auth.dart';
import 'package:camino_seguro/src/plugins/estaciones/regimiento_store.dart';
import 'package:flutter/material.dart';
import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/ui/global/template_page.dart';
import 'package:camino_seguro/src/ui/pages/control/control_store.dart';

import 'componentes/form_control.dart';
import 'componentes/header_control.dart';

GlobalKey<ScaffoldMessengerState> controlMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Control extends StatefulWidget {
  const Control({super.key});

  @override
  State<Control> createState() => _ControlState();
}

class _ControlState extends State<Control> {
  final store = ControlStore.instance;

  @override
  void initState() {
    // service.cargarDatosIniciales();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final profile = Auth.instance.profile;
    final regimiento = RegimientoStore.instance.regimiento;
    return TemplatePage(
      page: ScaffoldMessenger(
        key: controlMessenger,
        child: Scaffold(
          backgroundColor: theme.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  HeaderControl(
                    titulo: 'Lince',
                    subTitulo: 'Te damos la bienvenida',
                    nombreUsuario:
                        '${profile.nombres} ${profile.primerApellido} ${profile.segundoApellido}',
                    regimiento: regimiento.nombre,
                    tipoFuerza: regimiento.tipoFuerza,
                  ),
                  const SizedBox(height: 16),
                  const FormControl(),
                  const SizedBox(height: 16),
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
    super.dispose();
  }
}
