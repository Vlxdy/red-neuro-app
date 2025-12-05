import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/models/producto_carrito.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/services/carrito_local_service.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/stores/carrito_compras_store.dart';
import 'package:red_neuro_app/src/ui/pages/carrito_compras/widgets/carrito_scaffold_messenger.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/plugins/auth/auth.dart';

class CarritoComprasService extends ServiceConfig {
  CarritoComprasService(BuildContext context)
      : _store = CarritoComprasStore.instance,
        _localService = CarritoLocalService(),
        _theme = ThemeController.instance,
        super('', context);

  final CarritoComprasStore _store;
  final CarritoLocalService _localService;
  final ThemeController _theme;
  final Usuario profile = Auth.instance.profile;

  Future<void> initialize() async {
    await _cargarCarritoLocal();
  }

  Future<void> obtenerProductos() async {
    final String? idUsuarioRol = profile.idUsuarioRol;
    if (idUsuarioRol == null || idUsuarioRol.isEmpty) {
      _mostrarError('No se pudo identificar al paciente.');
      return;
    }

    _store.setCargando(true);
    _store.setError(null);

    final fechaInicio = _store.fechaInicio;
    final fechaFin = _store.fechaFin;

    try {
      final response = await fetch(
        '/planes-nutricionales/paciente/$idUsuarioRol/carrito-compras',
        params: {
          'desde': DateFormat('yyyy-MM-dd').format(fechaInicio),
          'hasta': DateFormat('yyyy-MM-dd').format(fechaFin),
        },
      );

      if (response.status != StatusNetwork.connected) {
        _store.limpiarResultados();
        _mostrarError(response.message);
        return;
      }
      final datos = response.data;
      final items = (datos['list'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProductoCarrito.fromJson)
          .toList();

      if (items.isEmpty) {
        _mostrarError(
            'No se encontraron productos para el rango seleccionado.');
        _store.limpiarResultados();
        return;
      }

      _store.setProductos(items);
    } catch (error, stacktrace) {
      Logger.error('Error al obtener carrito: $error');
      Logger.error(stacktrace.toString());
      _mostrarError('Ocurrió un error al obtener los productos.');
      _store.limpiarResultados();
    } finally {
      _store.setCargando(false);
    }
  }

  Future<void> adicionarAlCarrito() async {
    if (_store.productos.isEmpty) {
      _mostrarError('No hay productos para guardar.');
      return;
    }
    _store.setGuardando(true);
    try {
      final carrito = await _localService.guardarDesdeProductos(
        fechaInicio: _store.fechaInicio,
        fechaFin: _store.fechaFin,
        productos: _store.productos,
      );
      _store.setCarritoActivo(carrito);
      _store.limpiarResultados();
      showSnackBar(
        carritoMessengerKey,
        'Carrito guardado correctamente.',
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
    } catch (error, stacktrace) {
      Logger.error('Error al guardar carrito: $error');
      Logger.error(stacktrace.toString());
      _mostrarError('No se pudo guardar el carrito.');
    } finally {
      _store.setGuardando(false);
    }
  }

  Future<void> adicionarProductoIndividual(ProductoCarrito producto) async {
    _store.setGuardando(true);
    try {
      final carrito = await _localService.agregarProducto(
        fechaInicio: _store.fechaInicio,
        fechaFin: _store.fechaFin,
        producto: producto,
      );
      _store.setCarritoActivo(
        carrito,
        vista: CarritoVista.resultados,
      );
      _store.registrarProductoAgregado(producto.id);
      showSnackBar(
        carritoMessengerKey,
        'Producto agregado al carrito.',
        state: StatusSnackBar.success,
        colorText: _theme.white,
      );
    } catch (error, stacktrace) {
      Logger.error('Error al agregar producto al carrito: $error');
      Logger.error(stacktrace.toString());
      _mostrarError('No se pudo agregar el producto al carrito.');
    } finally {
      _store.setGuardando(false);
    }
  }

  Future<void> marcarProducto(String productoId, bool comprado) async {
    _store.actualizarEstadoProducto(productoId, comprado);
    try {
      final actualizado =
          await _localService.actualizarEstadoProducto(productoId, comprado);
      if (actualizado != null) {
        _store.setCarritoActivo(actualizado, notificar: false);
      }
    } catch (error, stacktrace) {
      Logger.error('Error al actualizar producto: $error');
      Logger.error(stacktrace.toString());
      _mostrarError('No se pudo actualizar el estado del producto.');
    }
  }

  Future<void> eliminarCarrito() async {
    try {
      await _localService.eliminarCarrito();
      _store.setCarritoActivo(null);
    } catch (error, stacktrace) {
      Logger.error('Error al eliminar carrito: $error');
      Logger.error(stacktrace.toString());
      _mostrarError('No se pudo eliminar el carrito.');
    }
  }

  Future<void> repetirPlanificacion() async {
    await eliminarCarrito();
    _store.limpiarResultados();
  }

  Future<void> _cargarCarritoLocal() async {
    try {
      _store.setCargando(true);
      final carrito = await _localService.obtenerCarrito();
      if (carrito != null) {
        _store.setCarritoActivo(carrito);
      }
    } catch (error, stacktrace) {
      Logger.error('Error al cargar carrito local: $error');
      Logger.error(stacktrace.toString());
    } finally {
      _store.setCargando(false);
    }
  }

  void _mostrarError(String mensaje) {
    _store.setError(mensaje);
    showSnackBar(
      carritoMessengerKey,
      mensaje,
      state: StatusSnackBar.error,
      colorText: _theme.white,
    );
  }
}
