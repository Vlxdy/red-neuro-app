import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/service_config.dart';
import 'package:red_neuro_app/src/constants/network.dart';

class CajaSesion {
  final String id;
  final String estado;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;
  final double montoApertura;
  final double? montoCierreDeclarado;
  final double montoRecaudado;

  const CajaSesion({
    required this.id,
    required this.estado,
    required this.fechaApertura,
    required this.fechaCierre,
    required this.montoApertura,
    required this.montoCierreDeclarado,
    required this.montoRecaudado,
  });

  bool get estaAbierta => estado.toUpperCase() == 'ABIERTA';

  factory CajaSesion.fromJson(Map<String, dynamic> json) {
    double parseMonto(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? parseFecha(dynamic value) {
      if (value is! String || value.trim().isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return CajaSesion(
      id: '${json['id'] ?? ''}',
      estado: '${json['estado'] ?? 'CERRADA'}',
      fechaApertura: parseFecha(json['fechaApertura']),
      fechaCierre: parseFecha(json['fechaCierre']),
      montoApertura: parseMonto(json['montoApertura']),
      montoCierreDeclarado: json['montoCierreDeclarado'] == null
          ? null
          : parseMonto(json['montoCierreDeclarado']),
      montoRecaudado: parseMonto(json['montoRecaudado']),
    );
  }
}

class CajaResponse {
  final StatusNetwork status;
  final String message;
  final CajaSesion? caja;

  const CajaResponse({
    required this.status,
    required this.message,
    required this.caja,
  });
}

class CajasService extends ServiceConfig {
  CajasService(BuildContext context) : super('', context);

  Future<CajaResponse> obtenerCajaActual() async {
    final response = await fetch('/caja/actual');
    final caja = _parseCaja(response.data);
    return CajaResponse(
      status: response.status,
      message: response.message,
      caja: caja,
    );
  }

  Future<CajaResponse> abrirCaja({double? montoApertura}) async {
    final response = await fetch(
      '/caja/apertura',
      type: HttpProtocol.post,
      body: {
        if (montoApertura != null) 'montoApertura': montoApertura,
      },
    );
    return CajaResponse(
      status: response.status,
      message: response.message,
      caja: _parseCaja(response.data),
    );
  }

  Future<CajaResponse> cerrarCaja({double? montoCierreDeclarado}) async {
    final response = await fetch(
      '/caja/cierre',
      type: HttpProtocol.post,
      body: {
        if (montoCierreDeclarado != null)
          'montoCierreDeclarado': montoCierreDeclarado,
      },
    );
    return CajaResponse(
      status: response.status,
      message: response.message,
      caja: _parseCaja(response.data),
    );
  }

  CajaSesion? _parseCaja(Map<String, dynamic> data) {
    final payload = (data['datos'] ?? data['data'] ?? data);
    if (payload is! Map<String, dynamic>) return null;
    if (payload.isEmpty) return null;
    return CajaSesion.fromJson(payload);
  }
}
