import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/models/area.dart';
import 'package:camino_seguro/src/ui/common/buttons/simple_button.dart';
import 'package:camino_seguro/src/ui/common/components/skeleton.dart';
import 'package:camino_seguro/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:camino_seguro/src/ui/pages/areas/componentes/form_registro_areas.dart';
import 'package:camino_seguro/src/ui/pages/areas/services/areas_service.dart';
import 'package:camino_seguro/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> areasMessenger =
    GlobalKey<ScaffoldMessengerState>();

class Areas extends StatefulWidget {
  const Areas({super.key});

  @override
  State<Areas> createState() => AreasScreen();
}

class AreasScreen extends State<Areas> {
  //service
  late AreasService service;
  @override
  void initState() {
    super.initState();
    service = AreasService('/mobile', context);
    service.fetchData();
  }

  Future<void> _refresh() async {
    await service.fetchData();
  }

  void _mostrarModal(RegistroAreasStore store, Area? areaEditar) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => FractionallySizedBox(
              heightFactor: 0.95,
              child: FormAreas(
                titulo: "Registro de área",
                descripcion: "Registrarás una nueva área permitida",
                areaEditar: areaEditar,
              ),
            )).whenComplete(() async {
      store.limpiarDatos();
      _refresh();
    });
  }

  void _cambiarEstado(RegistroAreasStore store, Area? areaEditar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmación"),
          content: Text(
              "¿Está seguro de que desea ${areaEditar?.estado == 'ACTIVO' ? 'deshabilitar' : 'habilitar'} esta área?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () async {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  if (areaEditar != null) {
                    await service.cambiarEstadoArea(context, areaEditar);
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
    final store = context.watch<RegistroAreasStore>();
    return ScaffoldMessenger(
      key: areasMessenger,
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
                      Icon(Icons.map, size: 28, color: theme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Áreas permitidas',
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
                    title: 'Nueva área',
                    preffixicon: Icons.add,
                    background: theme.primary,
                    textColor: theme.white,
                    onTap: () async {
                      _mostrarModal(store, null);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<Area>>(
                      future: Future.value(store.listaAreas),
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

                        final areas = snapshot.data!;
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
                                    contenidoTabla: areas.map((area) {
                                      return [
                                        Center(
                                          child: Text(
                                            dividirNombre(area.nombre),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Center(child: Text(area.estado)),
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
                                                _mostrarModal(store, area);
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                area.estado == 'ACTIVO'
                                                    ? Icons.toggle_on
                                                    : Icons.toggle_off,
                                                color: area.estado == 'ACTIVO'
                                                    ? Colors.green
                                                    : Colors.grey,
                                              ),
                                              onPressed: () async {
                                                _cambiarEstado(store, area);
                                                _refresh();
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
