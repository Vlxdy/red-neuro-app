import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/ocupacion.dart';
import 'package:red_neuro_app/src/models/personal_salud.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

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
        '/personal-salud',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          'incluirInactivos': 'true',
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

  Future<OcupacionPageResult> obtenerOcupacionesPaginadas({
    int page = 1,
    int limit = 20,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/ocupaciones',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );
      if (response.status != StatusNetwork.connected) {
        return OcupacionPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final ocupaciones = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Ocupacion.fromJson)
              .toList()
          : <Ocupacion>[];

      return OcupacionPageResult(
        items: ocupaciones,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? ocupaciones.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al obtener ocupaciones $e');
      Logger.error('stacktrace $stacktrace');
      return OcupacionPageResult.empty(
        'No se pudieron cargar las ocupaciones',
      );
    }
  }

  Future<ResponseApi> crearPersonalSalud(Map<String, dynamic> body) async {
    return fetch(
      '/personal-salud',
      type: HttpProtocol.post,
      body: body,
    );
  }

  Future<ResponseApi> actualizarPersonalSalud(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/personal-salud/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> inactivarPersonalSalud(String id) async {
    return fetch(
      '/personal-salud/$id/inactivacion',
      type: HttpProtocol.patch,
    );
  }

  Future<ResponseApi> activarPersonalSalud(String id) async {
    return fetch(
      '/personal-salud/$id/activacion',
      type: HttpProtocol.patch,
    );
  }
}

class OcupacionPageResult {
  final List<Ocupacion> items;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const OcupacionPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory OcupacionPageResult.empty(String message) =>
      OcupacionPageResult(
        items: const [],
        total: 0,
        page: 1,
        limit: 20,
        message: message,
        status: StatusNetwork.noContent,
      );
}
