import 'package:alimenta_app/src/ui/pages/carrito_compras/models/carrito_local.dart';
import 'package:alimenta_app/src/ui/pages/carrito_compras/models/producto_carrito.dart';
import 'package:hive/hive.dart';

class CarritoLocalService {
  CarritoLocalService();

  static const String _boxName = 'carrito_compras_box';
  static const String _carritoKey = 'carrito_activo';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }

  Future<CarritoLocal?> obtenerCarrito() async {
    final box = await _openBox();
    final data = box.get(_carritoKey);
    if (data is Map) {
      return CarritoLocal.fromJson(data.cast<String, dynamic>());
    }
    return null;
  }

  Future<void> guardarCarrito(CarritoLocal carrito) async {
    final box = await _openBox();
    await box.put(_carritoKey, carrito.toJson());
  }

  Future<void> eliminarCarrito() async {
    final box = await _openBox();
    await box.delete(_carritoKey);
  }

  Future<CarritoLocal?> actualizarEstadoProducto(
    String productoId,
    bool comprado,
  ) async {
    final carrito = await obtenerCarrito();
    if (carrito == null) return null;
    final productosActualizados = carrito.productos
        .map(
          (producto) => producto.id == productoId
              ? producto.copyWith(comprado: comprado)
              : producto,
        )
        .toList();
    final actualizado = carrito.copyWith(productos: productosActualizados);
    await guardarCarrito(actualizado);
    return actualizado;
  }

  Future<CarritoLocal> guardarDesdeProductos({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required List<ProductoCarrito> productos,
  }) async {
    final carrito = CarritoLocal(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      productos: productos,
    );
    await guardarCarrito(carrito);
    return carrito;
  }

  Future<CarritoLocal> agregarProducto({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required ProductoCarrito producto,
  }) async {
    final existente = await obtenerCarrito();
    if (existente == null) {
      final nuevo = CarritoLocal(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        productos: [producto],
      );
      await guardarCarrito(nuevo);
      return nuevo;
    }

    final productos = [...existente.productos];
    final index = productos.indexWhere((item) => item.id == producto.id);
    if (index >= 0) {
      productos[index] = producto.copyWith(comprado: productos[index].comprado);
    } else {
      productos.add(producto);
    }

    final actualizado = existente.copyWith(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      productos: productos,
    );
    await guardarCarrito(actualizado);
    return actualizado;
  }
}
