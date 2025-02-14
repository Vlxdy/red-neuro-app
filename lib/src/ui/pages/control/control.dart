import 'package:control_ventas_movil/src/config/routes.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:control_ventas_movil/src/ui/global/template_page.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_service.dart';
import 'package:control_ventas_movil/src/ui/pages/control/control_store.dart';
import 'package:flutter/services.dart' as services;
import 'package:go_router/go_router.dart';

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
  late ControlService service;
  final store = ControlStore.instance;
  final GlobalKey<FormState> _scaffoldingFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    service = ControlService(context);
    // service.cargarDatosIniciales();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return TemplatePage(
      page: ScaffoldMessenger(
        key: controlMessenger,
        child: Scaffold(
          backgroundColor: theme.transparent,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            elevation: 0,
            systemOverlayStyle: services.SystemUiOverlayStyle(
                statusBarBrightness:
                theme.isDark ? Brightness.dark : Brightness.light,
                statusBarColor: theme.transparent),
            backgroundColor: theme.transparent,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  HeaderControl(
                    titulo: 'Lince',
                    subTitulo: 'Te damos la bienvenida',
                    nombreUsuario: 'TTE. ARMINIA ALCÁZAR SALAZAR',
                    cuartel: 'CUARTEL GENERAL A',
                  ),
                  const SizedBox(height: 16),

                  const FormControl(),
                  const SizedBox(height: 16),

                  // SimpleButton(
                  //     title: 'Iniciar control',
                  //     background: theme.primary700,
                  //     textColor: theme.white,
                  //     onTap: () {
                  //       // TODO: Refactor goNamed
                  //       GoRouter.of(context).goNamed(RouteNames.resumenDia);
                  //       if (service.validateForm(_scaffoldingFormKey)) {
                  //         service.iniciarControl();
                  //         GoRouter.of(context).goNamed(RouteNames.resumenDia);
                  //       }
                  //     }),
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
