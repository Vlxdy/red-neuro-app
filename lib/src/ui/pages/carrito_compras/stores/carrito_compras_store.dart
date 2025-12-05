import 'package:red_neuro_app/src/ui/pages/carrito_compras/models/carrito_local.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/models/producto_carrito.dart';
import 'package:flutter/material.dart';

enum CarritoVista { generador, resultados, carrito }

class CarritoComprasStore extends ChangeNotifier {
  CarritoComprasStore._();

  static final CarritoComprasStore instance = CarritoComprasStore._();

  DateTime _fechaInicio = DateTime.now();
  int _cantidadDias = 7;
  bool _cargando = false;
  bool _guardando = false;
  String? _error;
  CarritoLocal? _carritoActivo;
  List<ProductoCarrito> _productos = [];
  String? _idUsuarioRol;
  CarritoVista _vistaActual = CarritoVista.generador;
  Set<String> _productosAgregados = <String>{};

  DateTime get fechaInicio => _fechaInicio;
  int get cantidadDias => _cantidadDias;
  DateTime get fechaFin =>
      _fechaInicio.add(Duration(days: _cantidadDias.clamp(1, 30).toInt()));
  bool get cargando => _cargando;
  bool get guardando => _guardando;
  String? get error => _error;
  CarritoLocal? get carritoActivo => _carritoActivo;
  bool get tieneCarritoActivo => _carritoActivo != null;
  List<ProductoCarrito> get productos => List.unmodifiable(_productos);
  String? get idUsuarioRol => _idUsuarioRol;
  CarritoVista get vistaActual => _vistaActual;
  Set<String> get productosAgregados => Set.unmodifiable(_productosAgregados);

  bool get tieneResultados => _productos.isNotEmpty;

  void setFechaInicio(DateTime fecha) {
    _fechaInicio = DateTime(fecha.year, fecha.month, fecha.day);
    notifyListeners();
  }

  void setCantidadDias(int dias) {
    final clamped = dias.clamp(1, 30).toInt();
    if (clamped == _cantidadDias) return;
    _cantidadDias = clamped;
    notifyListeners();
  }

  void setCargando(bool value) {
    if (_cargando == value) return;
    _cargando = value;
    notifyListeners();
  }

  void setGuardando(bool value) {
    if (_guardando == value) return;
    _guardando = value;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void setIdUsuarioRol(String? value) {
    _idUsuarioRol = value;
    notifyListeners();
  }

  void setProductos(List<ProductoCarrito> productos) {
    _productos = productos;
    _productosAgregados = <String>{
      ...?_carritoActivo?.productos.map((producto) => producto.id),
    };
    _vistaActual = CarritoVista.resultados;
    notifyListeners();
  }

  void limpiarResultados() {
    _productos = [];
    _productosAgregados.clear();
    if (!tieneCarritoActivo) {
      _vistaActual = CarritoVista.generador;
    }
    notifyListeners();
  }

  void setCarritoActivo(
    CarritoLocal? carrito, {
    bool notificar = true,
    CarritoVista? vista,
  }) {
    _carritoActivo = carrito;
    if (carrito == null) {
      _productosAgregados.clear();
    } else {
      _productosAgregados = <String>{
        ..._productosAgregados,
        ...carrito.productos.map((producto) => producto.id),
      };
    }
    if (vista != null) {
      _vistaActual = vista;
    } else {
      _vistaActual = carrito != null
          ? CarritoVista.carrito
          : (_productos.isNotEmpty
              ? CarritoVista.resultados
              : CarritoVista.generador);
    }
    if (notificar) {
      notifyListeners();
    }
  }

  void actualizarEstadoProducto(String productoId, bool comprado) {
    if (_carritoActivo == null) return;
    final productosActualizados = _carritoActivo!.productos
        .map(
          (producto) => producto.id == productoId
              ? producto.copyWith(comprado: comprado)
              : producto,
        )
        .toList();
    _carritoActivo =
        _carritoActivo!.copyWith(productos: productosActualizados);
    notifyListeners();
  }

  void setVista(CarritoVista vista) {
    if (_vistaActual == vista) return;
    _vistaActual = vista;
    notifyListeners();
  }

  bool productoYaEnCarrito(String productoId) {
    if (_carritoActivo == null) return false;
    return _carritoActivo!.productos.any((producto) => producto.id == productoId);
  }

  bool productoMarcadoComoAgregado(String productoId) {
    return _productosAgregados.contains(productoId) ||
        productoYaEnCarrito(productoId);
  }

  void registrarProductoAgregado(String productoId) {
    if (_productosAgregados.contains(productoId)) return;
    _productosAgregados = <String>{
      ..._productosAgregados,
      productoId,
    };
    notifyListeners();
  }
}
