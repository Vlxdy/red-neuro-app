import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';
import 'package:red_neuro_app/src/models/pago_con_cita_resumen.dart';

class CajaDetalle {
  final String id;
  final String estado;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;
  final double montoApertura;
  final double? montoCierreDeclarado;
  final double montoRecaudado;
  final int pagosPendientes;

  const CajaDetalle({
    required this.id,
    required this.estado,
    required this.fechaApertura,
    required this.fechaCierre,
    required this.montoApertura,
    required this.montoCierreDeclarado,
    required this.montoRecaudado,
    required this.pagosPendientes,
  });

  bool get estaAbierta => estado.toUpperCase() == 'ABIERTA';

  factory CajaDetalle.fromJson(Map<String, dynamic> json) {
    double parseMonto(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? parseFecha(dynamic value) {
      if (value is! String || value.trim().isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return CajaDetalle(
      id: '${json['id'] ?? ''}',
      estado: '${json['estado'] ?? 'CERRADA'}',
      fechaApertura: parseFecha(json['fechaApertura']),
      fechaCierre: parseFecha(json['fechaCierre']),
      montoApertura: parseMonto(json['montoApertura']),
      montoCierreDeclarado: json['montoCierreDeclarado'] == null
          ? null
          : parseMonto(json['montoCierreDeclarado']),
      montoRecaudado: parseMonto(json['montoRecaudado']),
      pagosPendientes: parseInt(json['pagosPendientes']),
    );
  }
}

class CajaListadoResult {
  final List<CajaDetalle> rows;
  final int total;
  final String? defaultCajaId;
  final StatusNetwork status;
  final String message;

  const CajaListadoResult({
    required this.rows,
    required this.total,
    required this.defaultCajaId,
    required this.status,
    required this.message,
  });
}

class CajaMovimientosResult {
  final List<PagoConCitaResumen> rows;
  final int total;
  final StatusNetwork status;
  final String message;

  const CajaMovimientosResult({
    required this.rows,
    required this.total,
    required this.status,
    required this.message,
  });
}

class CajaResponse {
  final StatusNetwork status;
  final String message;
  final CajaDetalle? caja;

  const CajaResponse({
    required this.status,
    required this.message,
    required this.caja,
  });
}

class CajasService extends ServiceConfig {
  CajasService(BuildContext context) : super('', context);

  Future<CajaListadoResult> listarCajas({
    int pagina = 1,
    int limite = 10,
    String? estado,
    String? gestion,
    String? mes,
  }) async {
    final limiteSanitizado = limite.clamp(1, 50);
    final response = await fetch(
      '/caja',
      params: {
        'pagina': '$pagina',
        'limite': '$limiteSanitizado',
        if (estado != null && estado.trim().isNotEmpty) 'estado': estado.trim(),
        if (gestion != null && gestion.trim().isNotEmpty) 'gestion': gestion.trim(),
        if (mes != null && mes.trim().isNotEmpty) 'mes': mes.trim(),
      },
    );
    final payload = _parsePayload(response.data);
    final rowsRaw = payload['rows'];
    final rows = (rowsRaw is List)
        ? rowsRaw
              .whereType<Map<String, dynamic>>()
              .map(CajaDetalle.fromJson)
              .toList()
        : <CajaDetalle>[];

    return CajaListadoResult(
      rows: rows,
      total: _parseInt(payload['total']),
      defaultCajaId: payload['defaultCajaId']?.toString(),
      status: response.status,
      message: response.message,
    );
  }

  Future<CajaResponse> obtenerCaja(String idCaja) async {
    final response = await fetch('/caja/$idCaja');
    return CajaResponse(
      status: response.status,
      message: response.message,
      caja: _parseCaja(response.data),
    );
  }

  Future<CajaMovimientosResult> obtenerMovimientos(
    String idCaja, {
    int pagina = 1,
    int limite = 20,
    String? estadoPago,
  }) async {
    final response = await fetch(
      '/caja/$idCaja/movimientos',
      params: {
        'pagina': '$pagina',
        'limite': '$limite',
        if (estadoPago != null && estadoPago.isNotEmpty) 'estadoPago': estadoPago,
      },
    );

    final payload = _parsePayload(response.data);
    final rowsRaw = payload['rows'] ?? payload['filas'];
    final rows = (rowsRaw is List)
        ? rowsRaw
              .whereType<Map<String, dynamic>>()
              .map(PagoConCitaResumen.fromJson)
              .toList()
        : <PagoConCitaResumen>[];

    return CajaMovimientosResult(
      rows: rows,
      total: _parseInt(payload['total']),
      status: response.status,
      message: response.message,
    );
  }

  Future<CajaResponse> abrirCaja({double? montoApertura}) async {
    final response = await fetch(
      '/caja/apertura',
      type: HttpProtocol.post,
      body: {if (montoApertura != null) 'montoApertura': montoApertura},
    );

    return CajaResponse(
      status: response.status,
      message: response.message,
      caja: _parseCaja(response.data),
    );
  }

  Future<CajaResponse> cerrarCaja(String idCaja, {double? montoCierreDeclarado}) async {
    final response = await fetch(
      '/caja/$idCaja/cierre',
      type: HttpProtocol.post,
      body: {
        if (montoCierreDeclarado != null) 'montoCierreDeclarado': montoCierreDeclarado,
      },
    );

    return CajaResponse(
      status: response.status,
      message: response.message,
      caja: _parseCaja(response.data),
    );
  }

  Map<String, dynamic> _parsePayload(Map<String, dynamic> data) {
    final payload = data['datos'] ?? data['data'] ?? data;
    if (payload is Map<String, dynamic>) return payload;
    return <String, dynamic>{};
  }

  CajaDetalle? _parseCaja(Map<String, dynamic> data) {
    final payload = _parsePayload(data);
    if (payload.isEmpty) return null;
    return CajaDetalle.fromJson(payload);
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
