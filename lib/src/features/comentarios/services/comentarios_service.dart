import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/comentario.dart';

class ComentariosService {
  final String baseUrl;

  ComentariosService(this.baseUrl);

  Future<List<Comentario>> obtenerComentarios(String idHistoriaClinica) async {
    final url =
        Uri.parse('$baseUrl/historia-clinica/$idHistoriaClinica/comentarios');
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('Error al obtener comentarios');
    }

    final List data = json.decode(res.body);
    return data.map((e) => Comentario.fromJson(e)).toList();
  }

  Future<Comentario> crearComentario(
      String idHistoriaClinica, Comentario nuevo) async {
    final url =
        Uri.parse('$baseUrl/historia-clinica/$idHistoriaClinica/comentarios');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(nuevo.toJson()),
    );

    if (res.statusCode != 201) {
      throw Exception('Error al crear comentario');
    }

    return Comentario.fromJson(json.decode(res.body));
  }
}
