import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/constants.dart';
import 'package:red_neuro_app/src/ui/common/keep_alive_page.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/models/producto_carrito.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/services/carrito_compras_service.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/stores/carrito_compras_store.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/widgets/carrito_scaffold_messenger.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CarritoComprasPage extends StatefulWidget {
  const CarritoComprasPage({super.key});

  @override
  State<CarritoComprasPage> createState() => _CarritoComprasPageState();
}

class _CarritoComprasPageState extends State<CarritoComprasPage>
    with AutomaticKeepAliveClientMixin {
  late CarritoComprasService _service;
  late ThemeController _theme;

  @override
  void initState() {
    super.initState();
    _service = CarritoComprasService(context);
    _theme = ThemeController.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<CarritoComprasStore>(
      builder: (context, store, _) {
        return ScaffoldMessenger(
          key: carritoMessengerKey,
          child: Scaffold(
            backgroundColor: _theme.background,
            appBar: _buildAppBar(store),
            body: _buildBody(store),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(CarritoComprasStore store) {
    return AppBar(
      title: const Text('Carrito de compras'),
      backgroundColor: _theme.background,
      elevation: 0,
      leading: _buildAppBarLeading(store),
      actions: _buildAppBarActions(store),
    );
  }

  Widget? _buildAppBarLeading(CarritoComprasStore store) {
    switch (store.vistaActual) {
      case CarritoVista.resultados:
        return IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => store.setVista(CarritoVista.generador),
        );
      case CarritoVista.carrito:
        if (store.tieneResultados) {
          return IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => store.setVista(CarritoVista.resultados),
          );
        }
        break;
      case CarritoVista.generador:
        break;
    }
    return null;
  }

  List<Widget>? _buildAppBarActions(CarritoComprasStore store) {
    final actions = <Widget>[];
    if (store.vistaActual != CarritoVista.carrito && store.tieneCarritoActivo) {
      actions.add(
        IconButton(
          tooltip: 'Ver carrito activo',
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => store.setVista(CarritoVista.carrito),
        ),
      );
    }
    if (store.vistaActual == CarritoVista.carrito && store.tieneResultados) {
      actions.add(
        IconButton(
          tooltip: 'Ver productos sugeridos',
          icon: const Icon(Icons.list_alt_outlined),
          onPressed: () => store.setVista(CarritoVista.resultados),
        ),
      );
    }
    if (store.vistaActual == CarritoVista.carrito) {
      actions.add(
        IconButton(
          tooltip: 'Seleccionar nuevas fechas',
          icon: const Icon(Icons.edit_calendar_outlined),
          onPressed: () => store.setVista(CarritoVista.generador),
        ),
      );
    }
    return actions.isEmpty ? null : actions;
  }

  Widget _buildBody(CarritoComprasStore store) {
    if (store.cargando && store.vistaActual == CarritoVista.generador) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (store.vistaActual) {
      case CarritoVista.generador:
        return _buildGenerador(store);
      case CarritoVista.resultados:
        if (store.cargando && !store.tieneResultados) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildListaProductos(store);
      case CarritoVista.carrito:
        if (store.carritoActivo == null) {
          return _buildGenerador(store);
        }
        return _buildCarritoActivo(store);
    }
  }

  Widget _buildGenerador(CarritoComprasStore store) {
    final rango =
        '${DateFormat('dd/MM/yyyy').format(store.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(store.fechaFin)}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generar carrito',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _theme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFechaInicio(store),
          const SizedBox(height: 16),
          _buildCantidadDias(store),
          const SizedBox(height: 16),
          Text(
            'Rango: $rango',
            style: TextStyle(color: _theme.neutral),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: store.cargando
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      _service.obtenerProductos();
                    },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: store.cargando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Obtener productos'),
            ),
          ),
          if ((store.error ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              store.error!,
              style: TextStyle(color: _theme.error, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFechaInicio(CarritoComprasStore store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _theme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _theme.neutral.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fecha de inicio',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _theme.fontColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd/MM/yyyy').format(store.fechaInicio),
                  style: TextStyle(
                    fontSize: 16,
                    color: _theme.fontColor,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: store.fechaInicio,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('es'),
                  );
                  if (fecha != null) {
                    store.setFechaInicio(fecha);
                  }
                },
                child: const Text('Seleccionar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCantidadDias(CarritoComprasStore store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _theme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _theme.neutral.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Días a planificar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _theme.fontColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: store.cantidadDias > 1
                    ? () => store.setCantidadDias(store.cantidadDias - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    store.cantidadDias.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _theme.primary,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: store.cantidadDias < 30
                    ? () => store.setCantidadDias(store.cantidadDias + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Máximo 30 días',
            style: TextStyle(color: _theme.neutral),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductos(CarritoComprasStore store) {
    final productos = store.productos;
    final rango =
        '${DateFormat('dd/MM/yyyy').format(store.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(store.fechaFin)}';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Productos sugeridos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _theme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rango seleccionado: $rango',
                          style: TextStyle(color: _theme.neutral),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => store.setVista(CarritoVista.generador),
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Modificar fechas'),
                  ),
                ],
              ),
              if ((store.error ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  store.error!,
                  style: TextStyle(
                    color: _theme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (store.cargando) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(color: _theme.primary),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: productos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final producto = productos[index];
              return _buildProductoItem(store, producto);
            },
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed:
                    store.guardando ? null : () => _service.adicionarAlCarrito(),
                icon: const Icon(Icons.playlist_add_check_outlined),
                label: store.guardando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Agregar todos al carrito'),
              ),
              if (store.tieneCarritoActivo) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => store.setVista(CarritoVista.carrito),
                  icon: const Icon(Icons.shopping_cart_checkout_outlined),
                  label: const Text('Ir a mi carrito'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductoItem(
      CarritoComprasStore store, ProductoCarrito producto) {
    final agregado = store.productoMarcadoComoAgregado(producto.id);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _theme.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.restaurant_menu),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _theme.fontColor,
                        ),
                      ),
                      Text(
                        '${producto.cantidad.toStringAsFixed(1)} ${producto.unidadMedida}',
                        style: TextStyle(color: _theme.neutral),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${producto.calorias.toStringAsFixed(0)} cal',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _theme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(producto.categoria),
                  backgroundColor: _theme.primary.withValues(alpha: 0.1),
                ),
                Text(
                  'Unidad referencial: ${producto.cantidadReferencial}',
                  style: TextStyle(color: _theme.neutral),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _mostrarDetalleProducto(producto),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver detalles'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: agregado || store.guardando
                      ? null
                      : () => _service.adicionarProductoIndividual(producto),
                  icon: Icon(agregado ? Icons.check_circle_outline : Icons.add),
                  label: Text(
                    agregado ? 'Agregado' : 'Agregar al carrito',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarritoActivo(CarritoComprasStore store) {
    final carrito = store.carritoActivo!;
    final rango =
        '${DateFormat('dd/MM').format(carrito.fechaInicio)} al ${DateFormat('dd/MM/yyyy').format(carrito.fechaFin)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Mi carrito de compras',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _theme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Semana del $rango',
            style: TextStyle(color: _theme.neutral),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: carrito.productos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final producto = carrito.productos[index];
              return Card(
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: producto.comprado,
                  onChanged: (value) {
                    if (value == null) return;
                    _service.marcarProducto(producto.id, value);
                  },
                  title: Text(producto.nombre),
                  subtitle: Text(
                    '${producto.cantidad.toStringAsFixed(1)} ${producto.unidadMedida}',
                  ),
                  secondary: IconButton(
                    tooltip: 'Ver detalles',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _mostrarDetalleProducto(producto),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final confirmar = await _mostrarConfirmacion(
                    titulo: 'Repetir planificación',
                    mensaje:
                        'Esto eliminará el carrito actual y te permitirá generar uno nuevo. ¿Deseas continuar?',
                  );
                  if (confirmar) {
                    await _service.repetirPlanificacion();
                  }
                },
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Repetir planificación'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmar = await _mostrarConfirmacion(
                    titulo: 'Eliminar carrito',
                    mensaje:
                        '¿Seguro que deseas eliminar tu carrito de compras? Esta acción no se puede deshacer.',
                  );
                  if (confirmar) {
                    await _service.eliminarCarrito();
                  }
                },
                style: TextButton.styleFrom(foregroundColor: _theme.error),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar carrito'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _mostrarConfirmacion({
    required String titulo,
    required String mensaje,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _mostrarDetalleProducto(ProductoCarrito producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final imageUrl = producto.urlImage.isEmpty
            ? null
            : Uri.tryParse(producto.urlImage)?.isAbsolute == true
                ? producto.urlImage
                : Uri.parse(Constantes.apiUrl)
                    .resolve(producto.urlImage)
                    .toString();
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _theme.neutral.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: _theme.neutral.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: _theme.neutral,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  producto.nombre,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _theme.fontColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Categoría: ${producto.categoria}'),
                Text('Unidad de medida: ${producto.unidadMedida}'),
                Text('Cantidad referencial: ${producto.cantidadReferencial}'),
                Text('Calorías: ${producto.calorias.toStringAsFixed(0)} kcal'),
                const SizedBox(height: 16),
                Text(
                  'Macronutrientes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _theme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroChip('Carbohidratos',
                        '${producto.carbohidratos.toStringAsFixed(1)} g'),
                    _buildMacroChip(
                        'Grasas', '${producto.grasa.toStringAsFixed(1)} g'),
                    _buildMacroChip('Proteínas',
                        '${producto.proteinas.toStringAsFixed(1)} g'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Descripción',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _theme.fontColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  producto.descripcion.isEmpty
                      ? 'Sin descripción disponible.'
                      : producto.descripcion,
                  style: TextStyle(color: _theme.neutral),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroChip(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _theme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _theme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: _theme.fontColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class CarritoComprasKeepAlivePage extends StatelessWidget {
  const CarritoComprasKeepAlivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const KeepAlivePage(child: CarritoComprasPage());
  }
}
