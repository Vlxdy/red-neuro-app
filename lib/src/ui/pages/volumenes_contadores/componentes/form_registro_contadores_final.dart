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
              onPressed: () {
                store.limpiarRegistros();
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
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
                      Text(
                        'Dispensador ${dispensador.codigo}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.secondary,
                          fontSize: 15, // Increased font size
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                store.limpiarRegistros();
                Navigator.pop(context);
              },
              child: const Text('Atrás'),
            ),
            ElevatedButton(
              onPressed: () {
                service.guardarMetersRegistro(context);
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
