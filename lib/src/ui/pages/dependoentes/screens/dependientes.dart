import 'package:camino_seguro/src/config/theme_controller.dart';
import 'package:camino_seguro/src/models/area.dart';
import 'package:camino_seguro/src/models/dependiente.dart';
import 'package:camino_seguro/src/ui/common/buttons/simple_button.dart';
import 'package:camino_seguro/src/ui/common/components/skeleton.dart';
import 'package:camino_seguro/src/ui/common/customdatatable/custom_datatable.dart';
import 'package:camino_seguro/src/ui/pages/areas/stores/registro_areas_store.dart';
import 'package:camino_seguro/src/ui/pages/dependoentes/services/dependiente_service.dart';
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
  late DependientesService service;
  @override
  void initState() {
    super.initState();
    service = DependientesService('/', context);
    service.fetchData();
  }

  Future<void> _refresh() async {
    await service.fetchData();
  }

  void _mostrarModal(RegistroAreasStore store, Dependiente? areaEditar) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => FractionallySizedBox(
              heightFactor: 0.95,
            )).whenComplete(() async {
      store.limpiarDatos();
      _refresh();
    });
  }

  void _cambiarEstado(
      RegistroAreasStore store, Dependiente? dependienteEditar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmación"),
          content: Text(
              "¿Está seguro de que desea ${dependienteEditar?.estado == 'ACTIVO' ? 'deshabilitar' : 'habilitar'} esta área?"),
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
                Navigator.of(context).pop();
                if (dependienteEditar != null) {
                  // await service.cambiarEstadoArea(context, dependienteEditar);
                  _refresh();
                }
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
                  // const CustomTitle(
                  //   title: 'Áreas permitidas',
                  //   icon: Icons.map,
                  // ),
                  if (store.tiposMedicionTanques.isNotEmpty)
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
                                                // _mostrarModal(store, area);
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
                                                // _cambiarEstado(store, area);
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
