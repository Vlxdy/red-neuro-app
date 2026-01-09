import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/user.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class RolOption {
  final String id;
  final String codigo;
  final String nombre;

  const RolOption({
    required this.id,
    required this.codigo,
    required this.nombre,
  });

  factory RolOption.fromJson(Map<String, dynamic> json) => RolOption(
        id: (json['id'] ?? json['idRol'] ?? '').toString(),
        codigo: (json['rol'] ?? json['codigo'] ?? json['nombre'] ?? '')
            .toString()
            .toUpperCase(),
        nombre: (json['nombre'] ?? json['rol'] ?? '').toString(),
      );
}

class UsuarioPageResult {
  final List<Usuario> usuarios;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const UsuarioPageResult({
    required this.usuarios,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory UsuarioPageResult.empty(String message) => UsuarioPageResult(
        usuarios: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class UsuariosService extends ServiceConfig {
  UsuariosService(BuildContext context) : super('', context);

  Future<List<RolOption>> obtenerRoles() async {
    try {
      final response = await fetch('/autorizacion/roles');
      if (response.status != StatusNetwork.connected) {
        return [];
      }

      final raw = response.data['list'] ??
          response.data['data'] ??
          response.data['roles'] ??
          response.data['items'] ??
          [];

      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(RolOption.fromJson)
            .toList();
      }
    } catch (e, stacktrace) {
      Logger.error('Error al obtener roles $e');
      Logger.error('stacktrace $stacktrace');
    }
    return [];
  }

  Future<UsuarioPageResult> obtenerUsuarios({
    int page = 1,
    int limit = 10,
    String? filtro,
    String? rol,
  }) async {
    try {
      final response = await fetch(
        '/usuarios',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
          if (rol != null && rol.isNotEmpty) 'rol': rol,
        },
      );

      final status = response.status;
      final message = response.message;

      final data = response.data;
      final meta = data['meta'] ?? data['paginacion'] ?? {};
      final total = meta['totalRegistros'] ?? meta['total'] ?? data['total'] ?? 0;
      final resolvedPage = meta['pagina'] ?? page;
      final resolvedLimit = meta['limite'] ?? limit;

      final listRaw = data['list'] ??
          data['data'] ??
          data['usuarios'] ??
          data['result'] ??
          meta['data'];

      final usuarios = (listRaw is List)
          ? listRaw
              .whereType<Map<String, dynamic>>()
              .map(Usuario.fromJson)
              .toList()
          : <Usuario>[];

      return UsuarioPageResult(
        usuarios: usuarios,
        total: total is int ? total : int.tryParse('$total') ?? usuarios.length,
        page: resolvedPage is int
            ? resolvedPage
            : int.tryParse('$resolvedPage') ?? page,
        limit: resolvedLimit is int
            ? resolvedLimit
            : int.tryParse('$resolvedLimit') ?? limit,
        message: message,
        status: status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar usuarios $e');
      Logger.error('stacktrace $stacktrace');
      return UsuarioPageResult.empty('No se pudieron cargar los usuarios');
    }
  }

  Future<ResponseApi> crearUsuario(Map<String, dynamic> body) async {
    return fetch(
      '/usuarios',
      type: HttpProtocol.post,
      body: body,
    );
  }

  Future<ResponseApi> actualizarUsuario(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/usuarios/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> activarUsuario(String id) async {
    return fetch(
      '/usuarios/$id/activacion',
      type: HttpProtocol.patch,
    );
  }

  Future<ResponseApi> inactivarUsuario(String id) async {
    return fetch(
      '/usuarios/$id/inactivacion',
      type: HttpProtocol.patch,
    );
  }
}
