import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/categoria.dart';
import 'package:red_neuro_app/src/models/estudio.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class ServicioPageResult {
  final List<Servicio> servicios;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const ServicioPageResult({
    required this.servicios,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory ServicioPageResult.empty(String message) => ServicioPageResult(
        servicios: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class CategoriaPageResult {
  final List<Categoria> items;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const CategoriaPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory CategoriaPageResult.empty(String message) => CategoriaPageResult(
        items: const [],
        total: 0,
        page: 1,
        limit: 20,
        message: message,
        status: StatusNetwork.noContent,
      );
}

typedef OcupacionPageResult = CategoriaPageResult;

class EstudiosService extends ServiceConfig {
  EstudiosService(BuildContext context) : super('', context);

  Future<ServicioPageResult> obtenerServicios({
    int page = 1,
    int limit = 10,
    String? filtro,
    String? tipo,
  }) async {
    try {
      final response = await fetch(
        '/servicios',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );

      if (response.status != StatusNetwork.connected) {
        return ServicioPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final servicios = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Servicio.fromJson)
              .toList()
          : <Servicio>[];

      return ServicioPageResult(
        servicios: servicios,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? servicios.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar servicios $e');
      Logger.error('stacktrace $stacktrace');
      return ServicioPageResult.empty('No se pudieron cargar los servicios');
    }
  }

  @Deprecated('Usar obtenerServicios')
  Future<ServicioPageResult> obtenerEstudios({
    int page = 1,
    int limit = 10,
    String? filtro,
    String? tipo,
  }) => obtenerServicios(
        page: page,
        limit: limit,
        filtro: filtro,
        tipo: tipo,
      );

  Future<CategoriaPageResult> obtenerCategoriasPaginadas({
    int page = 1,
    int limit = 20,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/categorias',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.trim().isNotEmpty) 'filtro': filtro.trim(),
        },
      );

      if (response.status != StatusNetwork.connected) {
        return CategoriaPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final categorias = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Categoria.fromJson)
              .toList()
          : <Categoria>[];

      return CategoriaPageResult(
        items: categorias,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? categorias.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener categorías $e');
      Logger.error('stacktrace $stacktrace');
      return CategoriaPageResult.empty(
        'No se pudieron cargar las categorías',
      );
    }
  }

  @Deprecated('Usar obtenerCategoriasPaginadas')
  Future<CategoriaPageResult> obtenerOcupacionesPaginadas({
    int page = 1,
    int limit = 20,
    String? filtro,
  }) => obtenerCategoriasPaginadas(page: page, limit: limit, filtro: filtro);

  @Deprecated('Usar obtenerCategorias')
  Future<List<Categoria>> obtenerOcupaciones() => obtenerCategorias();

  Future<List<Categoria>> obtenerCategorias() async {
    final result = await obtenerCategoriasPaginadas(page: 1, limit: 50);
    return result.items;
  }

  Future<ResponseApi> crearServicio(Map<String, dynamic> body) async {
    return fetch(
      '/servicios',
      type: HttpProtocol.post,
      body: body,
    );
  }

  Future<ResponseApi> actualizarServicio(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/servicios/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> eliminarServicio(String id) async {
    return fetch(
      '/servicios/$id',
      type: HttpProtocol.delete,
    );
  }

  Future<ResponseApi> cambiarEstadoServicio(String id) async {
    return fetch(
      '/servicios/$id/cambiar-estado',
      type: HttpProtocol.patch,
    );
  }

  @Deprecated('Usar crearServicio')
  Future<ResponseApi> crearEstudio(Map<String, dynamic> body) =>
      crearServicio(body);

  @Deprecated('Usar actualizarServicio')
  Future<ResponseApi> actualizarEstudio(String id, Map<String, dynamic> body) =>
      actualizarServicio(id, body);

  @Deprecated('Usar eliminarServicio')
  Future<ResponseApi> eliminarEstudio(String id) => eliminarServicio(id);

  @Deprecated('Usar cambiarEstadoServicio')
  Future<ResponseApi> cambiarEstadoEstudio(String id) =>
      cambiarEstadoServicio(id);
}
