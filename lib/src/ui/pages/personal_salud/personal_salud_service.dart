import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/especialidad.dart';
import 'package:red_neuro_app/src/models/personal_salud.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';
import 'package:red_neuro_app/src/ui/pages/usuarios/usuarios_service.dart';

class PersonalSaludPageResult {
  final List<PersonalSalud> personal;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const PersonalSaludPageResult({
    required this.personal,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory PersonalSaludPageResult.empty(String message) =>
      PersonalSaludPageResult(
        personal: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class PersonalSaludService extends ServiceConfig {
  PersonalSaludService(BuildContext context) : super('', context);

  Future<PersonalSaludPageResult> obtenerPersonalSalud({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/personal-medico',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );

      if (response.status != StatusNetwork.connected) {
        return PersonalSaludPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final personal = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(PersonalSalud.fromJson)
              .toList()
          : <PersonalSalud>[];

      return PersonalSaludPageResult(
        personal: personal,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? personal.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar personal de salud $e');
      Logger.error('stacktrace $stacktrace');
      return PersonalSaludPageResult.empty(
        'No se pudo cargar el personal de salud',
      );
    }
  }

  Future<EspecialidadPageResult> obtenerEspecialidadesPaginadas({
    int page = 1,
    int limit = 20,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/especialidades',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );
      if (response.status != StatusNetwork.connected) {
        return EspecialidadPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final especialidades = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Especialidad.fromJson)
              .toList()
          : <Especialidad>[];

      return EspecialidadPageResult(
        items: especialidades,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? especialidades.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener especialidades $e');
      Logger.error('stacktrace $stacktrace');
      return EspecialidadPageResult.empty(
        'No se pudieron cargar las especialidades',
      );
    }
  }

  Future<String?> obtenerRolPersonalSalud() async {
    try {
      final response = await fetch('/autorizacion/roles');
      if (response.status != StatusNetwork.connected) {
        return null;
      }

      final raw = response.data['list'] ??
          response.data['data'] ??
          response.data['roles'] ??
          response.data['items'] ??
          [];

      if (raw is List) {
        final roles = raw
            .whereType<Map<String, dynamic>>()
            .map(RolOption.fromJson);
        final match = roles.firstWhere(
          (rol) => rol.codigo == 'PERSONAL_SALUD',
          orElse: () => const RolOption(id: '', codigo: '', nombre: ''),
        );
        return match.codigo.isEmpty ? null : match.codigo;
      }
    } catch (e, stacktrace) {
      Logger.error('Error al obtener rol de personal de salud $e');
      Logger.error('stacktrace $stacktrace');
    }
    return null;
  }

  Future<ResponseApi> crearPersonalSalud(Map<String, dynamic> body) async {
    return fetch(
      '/usuarios',
      type: HttpProtocol.post,
      body: body,
    );
  }

  Future<ResponseApi> actualizarPersonalSalud(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/usuarios/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> eliminarPersonalSalud(String id) async {
    return fetch(
      '/usuarios/$id/inactivacion',
      type: HttpProtocol.patch,
    );
  }
}

class EspecialidadPageResult {
  final List<Especialidad> items;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const EspecialidadPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory EspecialidadPageResult.empty(String message) =>
      EspecialidadPageResult(
        items: const [],
        total: 0,
        page: 1,
        limit: 20,
        message: message,
        status: StatusNetwork.noContent,
      );
}
