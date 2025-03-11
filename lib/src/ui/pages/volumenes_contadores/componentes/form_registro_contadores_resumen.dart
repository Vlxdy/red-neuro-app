import 'package:control_ventas_movil/src/ui/common/alerts/confirmation_alert_dialog.dart';
import 'package:control_ventas_movil/src/ui/common/buttons/simple_button.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/meters_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:control_ventas_movil/src/ui/pages/volumenes_contadores/registro_meters_store.dart';
import 'package:control_ventas_movil/src/config/theme_controller.dart';

class FormRegistroContadoresFinal extends StatefulWidget {
  const FormRegistroContadoresFinal({super.key});

  @override
  State<FormRegistroContadoresFinal> createState() =>
      _FormRegistroContadoresFinal();
}

class _FormRegistroContadoresFinal extends State<FormRegistroContadoresFinal> {
  late MeterService service;

  @override
  void initState() {
    service = MeterService('', context);
    super.initState();
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Confirmación',
        text: '¿Está seguro de guardar el registro de contadores?',
        onConfirm: () {
          service.guardarMetersRegistro(context);
          Navigator.of(context)
            ..pop()
            ..pop();
        },
      ),
    );
  }

  void _mostrarDialogoCancelar(store) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        icon: Icons.cancel,
        title: 'Cancelar',
        text: '¿Está seguro de cancelar el registro de contadores?\n'
            'Se perderán todos los datos registrados',
        onConfirm: () {
          store.limpiarRegistros();
          Navigator.of(context)
            ..pop()
            ..pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RegistroMetersStore>();
    final theme = ThemeController.instance;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: theme.secondary),
                const SizedBox(width: 8),
                Text("Registro de contadores",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: theme.secondary)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _mostrarDialogoCancelar(store),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: store.registros.length,
          itemBuilder: (context, index) {
            final registro = store.registros[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    "Registrarás el valor de cada meter de manguera de los dispensadores de la EESS",
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    text: 'Tipo de Medición: ',
                    style: TextStyle(color: theme.secondary),
                    children: <TextSpan>[
                      TextSpan(
                        text: registro.tipoMedicion,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ...registro.dispensadores.map((dispensador) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Divider(),
                      Text(
                        'Dispensador ${dispensador.codigo}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.secondary,
                          fontSize: 15,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Hora: ',
                          style: TextStyle(color: theme.secondary),
                          children: <TextSpan>[
                            TextSpan(
                              text: dispensador.hora,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      ...dispensador.mangueras.map((manguera) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manguera ${manguera.codigo}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.secondary,
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                text: 'Tipo de combustible: ',
                                style: TextStyle(color: theme.secondary),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: manguera.combustible.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                text: 'Meter: ',
                                style: TextStyle(color: theme.secondary),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${manguera.meter}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SimpleButton(
                textColor: theme.black,
                outlined: true,
                onTap: () {
                  store.limpiarRegistros();
                  Navigator.pop(context);
                },
                title: 'Atrás',
              ),
              SimpleButton(
                onTap: _mostrarDialogoConfirmacion,
                title: 'Guardar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
