import 'dart:convert';

import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/models/dependiente.dart';
import 'package:camino_seguro/src/ui/common/buttons/simple_button.dart';
import 'package:camino_seguro/src/ui/common/components/skeleton.dart';
import 'package:camino_seguro/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/componentes/form_registro_dependientes.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/services/dependientes.dart';
import 'package:camino_seguro/src/ui/pages/dependientes/stores/registro_dependientes_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> dependientesMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Dependientes extends StatefulWidget {
  const Dependientes({super.key});

  @override
  State<Dependientes> createState() => DependientesScreen();
}

class DependientesScreen extends State<Dependientes> {
  //service
  late DependientesService service;
  @override
  void initState() {
    super.initState();
    service = DependientesService('/mobile', context);
  }

  Future<void> _refresh() async {
    await service.fetchData(null);
  }

  void _mostrarNotificaciones(
      RegistroDependientesStore store, Dependiente? dependienteEditar) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => FractionallySizedBox(
            heightFactor: 0.95,
            child: dependienteEditar?.notificaciones.isEmpty ?? true
                ? const Center(
                    child: Text('No hay notificaciones disponibles'),
                  )
                : ListView.builder(
                    itemCount: dependienteEditar!.notificaciones.length,
                    itemBuilder: (context, index) {
                      final notificacion =
                          dependienteEditar.notificaciones[index];
                      return ListTile(
                        title: Text(
                            '${jsonEncode(dependienteEditar)} fuera del area'),
                        subtitle: Text(notificacion.cuerpo),
                        leading: Icon(Icons.notifications,
                            color: Theme.of(context).primaryColor),
                      );
                    },
                  ))).whenComplete(() async {
      _refresh();
    });
  }

  void _mostrarModal(
      RegistroDependientesStore store, Dependiente? dependienteEditar) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => FractionallySizedBox(
              heightFactor: 0.95,
              child: FormDependientes(
                titulo: "Registro de dependiente",
                descripcion: "Registrarás un nuevo dependiente",
                dependienteEditar: dependienteEditar,
              ),
            )).whenComplete(() async {
      store.limpiarDatos();
      _refresh();
    });
  }

  void _cambiarEstado(
      RegistroDependientesStore store, Dependiente? dependienteEditar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmación"),
          content: Text(
              "¿Está seguro de que desea ${dependienteEditar?.estado == 'ACTIVO' ? 'deshabilitar' : 'habilitar'} esta dependiente?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  if (dependienteEditar != null) {
                    await service.cambiarEstadoDependiente(
                        context, dependienteEditar);
                    _refresh();
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  String dividirNombre(String nombre, {int limite = 17}) {
    if (nombre.length <= limite) return nombre;

    final idx = nombre.lastIndexOf(' ', limite);
    if (idx == -1) return nombre; // No hay espacios para dividir
    return '${nombre.substring(0, idx)}\n${nombre.substring(idx + 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final store = context.watch<RegistroDependientesStore>();
    return ScaffoldMessenger(
      key: dependientesMessenger,
      child: RefreshIndicator(
          onRefresh: _refresh,
          child: Scaffold(
            backgroundColor: theme.background,
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 28, color: theme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Dependientes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SimpleButton(
                    title: 'Nuevo dependiente',
                    preffixicon: Icons.add,
                    background: theme.primary,
                    textColor: theme.white,
                    onTap: () async {
                      _mostrarModal(store, null);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<Dependiente>>(
                      future: Future.value(store.listaDependientes),
                      builder: (context, snapshot) {
                        if (store.cargando) {
                          return const SkeletonGrid(
                              rows: 10, columns: 3, itemHeight: 35);
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: const Center(
                                child: Text('No hay datos disponibles'),
                              ),
                            ),
                          );
                        }

                        final dependientes = snapshot.data!;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  width: constraints
                                      .maxWidth, // 👈 asegura ancho completo
                                  child: CustomDesktopDataTable(
                                    columnas: [
                                      CriterioOrdenType(nombre: 'Nombre'),
                                      CriterioOrdenType(nombre: 'Estado'),
                                      CriterioOrdenType(nombre: 'Accion'),
                                    ],
                                    contenidoTabla:
                                        dependientes.map((dependiente) {
                                      return [
                                        Center(
                                          child: Text(
                                            dividirNombre(dependiente.nombre),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Center(child: Text(dependiente.estado)),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () {
                                                _mostrarModal(
                                                    store, dependiente);
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                dependiente.estado == 'ACTIVO'
                                                    ? Icons.toggle_on
                                                    : Icons.toggle_off,
                                                color: dependiente.estado ==
                                                        'ACTIVO'
                                                    ? Colors.green
                                                    : Colors.grey,
                                              ),
                                              onPressed: () async {
                                                _cambiarEstado(
                                                    store, dependiente);
                                                _refresh();
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.visibility,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () {
                                                _mostrarNotificaciones(
                                                    store, dependiente);
                                              },
                                            ),
                                          ],
                                        ),
                                      ];
                                    }).toList(),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
