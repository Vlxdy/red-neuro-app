import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/notificacion.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificacionesPagina {
  NotificacionesPagina({
    required this.notificaciones,
    required this.total,
    required this.totalNoVistas,
  });

  final List<Notificacion> notificaciones;
  final int total;
  final int totalNoVistas;
}

class NotificacionesService extends ServiceConfig {
  NotificacionesService(BuildContext context) : super('', context);

  Future<NotificacionesPagina> obtenerNotificaciones({
    required int pagina,
    required int limite,
  }) async {
    final response = await fetch(
      '/notificacion',
      params: {
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      },
      type: HttpProtocol.get,
    );

    if (response.status != StatusNetwork.connected) {
      throw ErrorDescription(response.message);
    }

    final data = response.data;
    final filasRaw = data['filas'] ?? data['list'] ?? data['data'];
    final filas = (filasRaw as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Notificacion.fromJson)
        .toList();

    final total = _parseEntero(data['total']);
    int totalNoVistas = _parseEntero(
          data['totalNoVistas'] ??
              data['noVistas'] ??
              data['totalNoLeidas'] ??
              data['totalNoLeidos'],
        ) ??
        filas.where((notificacion) => !notificacion.visto).length;

    return NotificacionesPagina(
      notificaciones: filas,
      total: total ?? filas.length,
      totalNoVistas: totalNoVistas,
    );
  }

  Future<void> marcarComoVistas(List<String> ids) async {
    final response = await fetch(
      '/notificacion',
      type: HttpProtocol.patch,
      body: {'idNotificaciones': ids},
    );

    if (response.status != StatusNetwork.connected) {
      throw ErrorDescription(response.message);
    }
  }

  int? _parseEntero(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
