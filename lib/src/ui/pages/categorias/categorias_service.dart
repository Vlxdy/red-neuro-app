import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/categoria.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class CategoriaPageResult {
  final List<Categoria> categorias;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const CategoriaPageResult({
    required this.categorias,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory CategoriaPageResult.empty(String message) => CategoriaPageResult(
        categorias: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class CategoriasService extends ServiceConfig {
  CategoriasService(BuildContext context) : super('', context);

  Future<CategoriaPageResult> obtenerCategorias({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/categorias',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
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
        categorias: categorias,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? categorias.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar categorías $e');
      Logger.error('stacktrace $stacktrace');
      return CategoriaPageResult.empty('No se pudieron cargar las categorías');
    }
  }

  Future<ResponseApi> crearCategoria(Map<String, dynamic> body) async {
    return fetch('/categorias', type: HttpProtocol.post, body: body);
  }

  Future<ResponseApi> actualizarCategoria(String id, Map<String, dynamic> body) async {
    return fetch('/categorias/$id', type: HttpProtocol.patch, body: body);
  }

  Future<ResponseApi> cambiarEstadoCategoria(String id) async {
    return fetch('/categorias/$id/cambiar-estado', type: HttpProtocol.patch);
  }
}
