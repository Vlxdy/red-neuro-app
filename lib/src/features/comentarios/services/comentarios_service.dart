import 'dart:convert';
import 'package:alimenta_app/src/constants/network.dart';
import 'package:flutter/material.dart';
import '../../../models/comentario.dart';
import 'package:alimenta_app/src/config/service_config.dart';

class ComentariosService extends ServiceConfig {
  ComentariosService(super.urlBase, super.context);

  Future<List<Comentario>> obtenerComentarios(String idHistoriaClinica) async {
    final response = await fetch(
      '/historia-clinica/$idHistoriaClinica/comentarios',
      type: HttpProtocol.get,
    );
    // Uri.parse('$baseUrl/historia-clinica/$idHistoriaClinica/comentarios');
    // final res = await http.get(url);

    if (response.status != StatusNetwork.connected) {
      throw ErrorDescription(response.message);
    }

    final data = response.data;
    // final total = data['total'] is int
    // ? data['total'] as int
    // : int.tryParse(data['total']?.toString() ?? '0') ?? 0;
    final filas = (data['filas'] as List<dynamic>? ?? [])
        .map((item) => Comentario.fromJson(item as Map<String, dynamic>))
        .toList();

    return filas;
  }

  Future<Comentario> crearComentario(
      String idHistoriaClinica, Comentario nuevo) async {
    // final url =
    //     Uri.parse('$baseUrl/historia-clinica/$idHistoriaClinica/comentarios');
    // final res = await http.post(
    //   url,
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(nuevo.toJson()),
    // );

    final response = await fetch(
      '/historia-clinica/$idHistoriaClinica/comentarios',
      type: HttpProtocol.post,
      body: nuevo.toJson(),
    );

    if (response.status != StatusNetwork.connected) {
      throw ErrorDescription(response.message);
    }

    return Comentario.fromJson(json.decode(response.data.toString()));
  }
}
