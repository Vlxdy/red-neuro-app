import 'dart:collection';

import 'package:red_neuro_app/src/features/notificaciones/services/notificaciones_service.dart';
import 'package:red_neuro_app/src/models/notificacion.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificacionesStore extends ChangeNotifier {
  NotificacionesStore._();

  static final NotificacionesStore instance = NotificacionesStore._();

  final List<Notificacion> _notificaciones = [];
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _initialized = false;
  bool _error = false;
  bool _isLastPage = false;
  int _pagina = 1;
  final int _limite = 10;
  int _total = 0;
  int _totalNoVistas = 0;

  UnmodifiableListView<Notificacion> get notificaciones =>
      UnmodifiableListView(_notificaciones);
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get initialized => _initialized;
  bool get hayError => _error;
  bool get isLastPage => _isLastPage;
  int get total => _total;
  int get pagina => _pagina;
  int get limite => _limite;
  int get totalNoVistas => _totalNoVistas;

  Future<void> inicializar(BuildContext context, {bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;
    try {
      await cargarNotificaciones(context, reset: true);
      _initialized = true;
    } catch (error) {
      _initialized = _notificaciones.isNotEmpty;
      rethrow;
    }
  }

  Future<void> refrescar(BuildContext context) async {
    await cargarNotificaciones(context, reset: true);
  }

  Future<void> cargarMas(BuildContext context) async {
    await cargarNotificaciones(context);
  }

  Future<void> cargarNotificaciones(BuildContext context, {bool reset = false}) async {
    if (_cargando || _cargandoMas) return;
    if (reset) {
      _pagina = 1;
      _isLastPage = false;
    } else if (_isLastPage) {
      return;
    }

    if (reset) {
      _cargando = true;
    } else {
      _cargandoMas = true;
    }
    notifyListeners();

    try {
      final service = NotificacionesService(context);
      final resultado = await service.obtenerNotificaciones(
        pagina: _pagina,
        limite: _limite,
      );

      _total = resultado.total;
      _totalNoVistas =
          resultado.totalNoVistas < 0 ? 0 : resultado.totalNoVistas;

      if (reset) {
        _notificaciones
          ..clear()
          ..addAll(resultado.notificaciones);
      } else {
        _mergeNotificaciones(resultado.notificaciones);
      }

      _pagina += 1;
      _isLastPage = _notificaciones.length >= _total ||
          resultado.notificaciones.isEmpty;
      _error = false;
    } catch (error) {
      _error = true;
      rethrow;
    } finally {
      if (reset) {
        _cargando = false;
      } else {
        _cargandoMas = false;
      }
      notifyListeners();
    }
  }

  Future<void> marcarComoVistas(
    BuildContext context,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return;
    final idsPendientes = ids
        .where((id) =>
            _notificaciones.any((notificacion) =>
                notificacion.id == id && notificacion.visto == false))
        .toList();
    if (idsPendientes.isEmpty) return;

    final service = NotificacionesService(context);
    await service.marcarComoVistas(idsPendientes);

    bool actualizo = false;
    for (final id in idsPendientes) {
      final index =
          _notificaciones.indexWhere((notificacion) => notificacion.id == id);
      if (index != -1) {
        _notificaciones[index] =
            _notificaciones[index].copyWith(visto: true);
        actualizo = true;
      }
    }

    if (actualizo) {
      _totalNoVistas =
          _notificaciones.where((notificacion) => !notificacion.visto).length;
      notifyListeners();
    }
  }

  void agregarNotificacion(Notificacion notificacion) {
    final index =
        _notificaciones.indexWhere((elemento) => elemento.id == notificacion.id);
    if (index != -1) {
      _notificaciones[index] = notificacion;
    } else {
      _notificaciones.insert(0, notificacion);
      _total += 1;
    }
    if (!notificacion.visto) {
      _totalNoVistas += 1;
    }
    notifyListeners();
  }

  void reset() {
    _notificaciones.clear();
    _cargando = false;
    _cargandoMas = false;
    _initialized = false;
    _error = false;
    _isLastPage = false;
    _pagina = 1;
    _total = 0;
    _totalNoVistas = 0;
    notifyListeners();
  }

  void _mergeNotificaciones(List<Notificacion> nuevas) {
    final idsExistentes = _notificaciones.map((n) => n.id).toSet();
    for (final notificacion in nuevas) {
      if (idsExistentes.contains(notificacion.id)) {
        final index = _notificaciones
            .indexWhere((elemento) => elemento.id == notificacion.id);
        if (index != -1) {
          _notificaciones[index] = notificacion;
        }
      } else {
        _notificaciones.add(notificacion);
        idsExistentes.add(notificacion.id);
      }
    }
    _totalNoVistas =
        _notificaciones.where((notificacion) => !notificacion.visto).length;
  }
}
