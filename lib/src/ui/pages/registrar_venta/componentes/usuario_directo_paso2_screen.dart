import 'package:control_ventas_movil/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

class UsuarioDirectoScreen2 extends StatefulWidget {
  const UsuarioDirectoScreen2({Key? key}) : super(key: key);

  @override
  _UsuarioDirectoScreenState createState() => _UsuarioDirectoScreenState();
}

class _UsuarioDirectoScreenState extends State<UsuarioDirectoScreen2> {
  final ScrollController _scrollController = ScrollController();

  final theme = ThemeController.instance;
  List<Map<String, String>> autorizaciones = [];

  void _mostrarModalAgregarAutorizacion() {
    String tipoCombustible = 'Diesel Oil';
    TextEditingController codigoController = TextEditingController();
    TextEditingController volumenController = TextEditingController();
    TextEditingController observacionController = TextEditingController();
    bool agregarObservacion = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.receipt, color: theme.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Agregar autorización',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                controller: _scrollController, // Agregamos el controlador
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tipo de combustible',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: tipoCombustible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      items: ['Diesel Oil', 'Gasolina Especial', 'GLP']
                          .map((item) =>
                              DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) {
                        setStateModal(
                            () => tipoCombustible = value ?? 'Diesel Oil');
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Código de autorización',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: codigoController,
                      decoration: InputDecoration(
                        hintText: 'Ej. ABC123',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Volumen',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: volumenController,
                      decoration: InputDecoration(
                        hintText: 'Ej. 50',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Agregar una observación'),
                      value: agregarObservacion,
                      onChanged: (bool? value) {
                        setStateModal(() {
                          agregarObservacion = value ?? false;

                          if (agregarObservacion) {
                            Future.delayed(Duration(milliseconds: 300), () {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                              );
                            });
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (agregarObservacion)
                      TextField(
                        controller: observacionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Escribe una observación...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.cancel, color: theme.error),
                  label: Text('Cancelar',
                      style: TextStyle(color: theme.error)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      autorizaciones.add({
                        'codigo': codigoController.text,
                        'combustible': tipoCombustible,
                        'volumen': volumenController.text,
                        'observacion': agregarObservacion
                            ? observacionController.text
                            : '',
                      });
                    });
                  },
                  icon: Icon(Icons.add, color: theme.white),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.secondary,
                      foregroundColor: theme.white),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _eliminarAutorizacion(int index) {
    setState(() {
      autorizaciones.removeAt(index);
    });
  }

  void _finalizarProceso() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proceso finalizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.local_gas_station, color: theme.secondary, size: 28),
            SizedBox(width: 8),
            Expanded( // Permite que el texto se ajuste sin desbordar
              child: Text(
                'Venta de combustible a\nUsuarios Directos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.secondary,
                ),
                overflow: TextOverflow.ellipsis, // Evita el desbordamiento
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),


      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row(
                    //   children: [
                    //     IconButton(
                    //         icon: Icon(Icons.arrow_back, color: theme.secondary),
                    //         onPressed: () => Navigator.pop(context)),
                    //     Icon(Icons.local_gas_station,
                    //         color: theme.secondary, size: 28),
                    //     SizedBox(width: 8),
                    //     Text(
                    //       'Venta de combustible a\nUSUARIOS DIRECTOS',
                    //       style: TextStyle(
                    //           fontSize: 22,
                    //           fontWeight: FontWeight.bold,
                    //           color: theme.secondary),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 6),
                    Text('Registrarás una nueva venta de combustible',
                        style: TextStyle(fontSize: 14, color: theme.secondary)),
                    const SizedBox(height: 20),
                    const Text('Autorizaciones',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _mostrarModalAgregarAutorizacion,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          foregroundColor: theme.primary,
                          backgroundColor: theme.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(Icons.receipt, color: theme.primary),
                        label: const Text(
                          'Agregar autorización',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (autorizaciones.isNotEmpty)
                      Column(
                        children: List.generate(autorizaciones.length, (index) {
                          var autorizacion = autorizaciones[index];
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  theme.primary.withOpacity(0.05), // Fondo claro
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow('Cód. autorización',
                                          autorizacion['codigo']!),
                                      _buildInfoRow('Tipo combustible',
                                          autorizacion['combustible']!),
                                      _buildInfoRow(
                                          'Volumen', autorizacion['volumen']!),
                                      if (autorizacion.containsKey('placa') &&
                                          autorizacion['placa']!.isNotEmpty)
                                        _buildInfoRow('Nro. de Placa',
                                            autorizacion['placa']!),
                                      if (autorizacion
                                              .containsKey('observacion') &&
                                          autorizacion['observacion']!
                                              .isNotEmpty) ...[
                                         Text(
                                          'Observación',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: theme.error),
                                        ),
                                        Text(
                                          autorizacion['observacion']!,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: theme.black),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: theme.grey),
                                  onPressed: () => _eliminarAutorizacion(index),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              ),
            ),
            if (autorizaciones.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _finalizarProceso,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.secondary,
                        foregroundColor: theme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Finalizar'),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.secondary,
                        side: BorderSide(color: theme.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: Icon(Icons.cancel, color: theme.secondary),
                      label: const Text('Cancelar'),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.black),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: theme.black),
          ),
        ],
      ),
    );
  }
}
