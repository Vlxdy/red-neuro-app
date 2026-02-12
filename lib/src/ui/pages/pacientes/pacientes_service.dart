import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/paciente.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class PacientesPageResult {
  final List<Paciente> pacientes;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const PacientesPageResult({
    required this.pacientes,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory PacientesPageResult.empty(String message) => PacientesPageResult(
        pacientes: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class PacientesService extends ServiceConfig {
  PacientesService(BuildContext context) : super('', context);

  Future<PacientesPageResult> obtenerPacientes({
    int page = 1,
    int limit = 10,
    String? filtro,
  }) async {
    try {
      final response = await fetch(
        '/pacientes',
        params: {
          'pagina': '$page',
          'limite': '$limit',
          if (filtro != null && filtro.isNotEmpty) 'filtro': filtro,
        },
      );

      if (response.status != StatusNetwork.connected) {
        return PacientesPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw = (datos is Map ? datos['filas'] : null) ??
          data['list'] ??
          data['data'] ??
          data['items'] ??
          [];

      final pacientes = (filasRaw is List)
          ? filasRaw
              .whereType<Map<String, dynamic>>()
              .map(Paciente.fromJson)
              .toList()
          : <Paciente>[];

      return PacientesPageResult(
        pacientes: pacientes,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? pacientes.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, stacktrace) {
      Logger.error('Error al listar pacientes $e');
      Logger.error('stacktrace $stacktrace');
      return PacientesPageResult.empty('No se pudieron cargar los pacientes');
    }
  }

  Future<ResponseApi> obtenerPaciente(String id) async {
    return fetch('/pacientes/$id');
  }

  Future<ResponseApi> crearPaciente(Map<String, dynamic> body) async {
    return fetch(
      '/pacientes',
      type: HttpProtocol.post,
      body: body,
    );
  }

  Future<ResponseApi> actualizarPaciente(
    String id,
    Map<String, dynamic> body,
  ) async {
    return fetch(
      '/pacientes/$id',
      type: HttpProtocol.patch,
      body: body,
    );
  }

  Future<ResponseApi> eliminarPaciente(String id) async {
    return fetch(
      '/pacientes/$id',
      type: HttpProtocol.delete,
      body: const {},
    );
  }

  Future<ResponseApi> cambiarEstadoPaciente(String id) async {
    return fetch(
      '/pacientes/$id/cambiar-estado',
      type: HttpProtocol.patch,
      body: const {},
    );
  }
}
