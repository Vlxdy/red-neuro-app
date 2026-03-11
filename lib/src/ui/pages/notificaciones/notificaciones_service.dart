import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/notificacion.dart';
import 'package:red_neuro_app/src/plugins/utils/logger.dart';

class NotificacionesPageResult {
  final List<NotificacionItem> notificaciones;
  final int total;
  final int page;
  final int limit;
  final String message;
  final StatusNetwork status;

  const NotificacionesPageResult({
    required this.notificaciones,
    required this.total,
    required this.page,
    required this.limit,
    required this.message,
    required this.status,
  });

  factory NotificacionesPageResult.empty(String message) =>
      NotificacionesPageResult(
        notificaciones: const [],
        total: 0,
        page: 1,
        limit: 10,
        message: message,
        status: StatusNetwork.noContent,
      );
}

class NotificacionesService extends ServiceConfig {
  NotificacionesService(BuildContext context) : super('', context);

  Future<NotificacionesPageResult> obtenerNotificaciones({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await fetch(
        '/notificaciones',
        params: {'pagina': '$page', 'limite': '$limit'},
      );

      if (response.status != StatusNetwork.connected) {
        return NotificacionesPageResult.empty(response.message);
      }

      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      final totalRaw = (datos is Map ? datos['total'] : null) ?? data['total'];
      final filasRaw =
          (datos is Map ? datos['filas'] : null) ?? data['list'] ?? [];

      final notificaciones = (filasRaw is List)
          ? filasRaw
                .whereType<Map<String, dynamic>>()
                .map(NotificacionItem.fromJson)
                .toList()
          : <NotificacionItem>[];

      return NotificacionesPageResult(
        notificaciones: notificaciones,
        total: totalRaw is int
            ? totalRaw
            : int.tryParse('$totalRaw') ?? notificaciones.length,
        page: page,
        limit: limit,
        message: response.message,
        status: response.status,
      );
    } catch (e, st) {
      Logger.error('Error al listar notificaciones $e');
      Logger.error('stacktrace $st');
      return NotificacionesPageResult.empty(
        'No se pudieron cargar las notificaciones',
      );
    }
  }

  Future<ResumenDiario?> obtenerResumenDiario() async {
    try {
      final response = await fetch('/notificaciones/resumen-diario');
      if (response.status != StatusNetwork.connected) return null;
      final data = response.data;
      final datos = data['datos'] ?? data['data'] ?? data;
      if (datos is Map<String, dynamic>) {
        return ResumenDiario.fromJson(datos);
      }
    } catch (e) {
      Logger.error('Error al obtener resumen diario $e');
    }
    return null;
  }

  Future<bool> marcarVista(String id) async {
    final response = await fetch(
      '/notificaciones/$id/visto',
      type: HttpProtocol.patch,
      body: const {},
    );
    return response.status == StatusNetwork.connected;
  }

  Future<bool> marcarTodasVistas() async {
    final response = await fetch(
      '/notificaciones/marcar-todas-vistas',
      type: HttpProtocol.patch,
      body: const {},
    );
    return response.status == StatusNetwork.connected;
  }

  Future<bool> registrarTokenPush(String token, {String? plataforma}) async {
    final response = await fetch(
      '/dispositivos-push',
      type: HttpProtocol.post,
      body: {
        'token': token,
        if (plataforma != null && plataforma.isNotEmpty) 'plataforma': plataforma,
      },
    );
    return response.status == StatusNetwork.connected;
  }

  Future<bool> eliminarTokenPush(String token) async {
    final response = await fetch(
      '/dispositivos-push/$token',
      type: HttpProtocol.delete,
    );
    return response.status == StatusNetwork.connected;
  }
}
