import 'package:flutter/foundation.dart';
import '../../../models/comentario.dart';
import '../services/comentarios_service.dart';

class ComentariosStore extends ChangeNotifier {
  final ComentariosService service;
  final String idHistoriaClinica;

  List<Comentario> comentarios = [];
  bool cargando = false;
  bool enviando = false;

  ComentariosStore({
    required this.service,
    required this.idHistoriaClinica,
  });

  Future<void> cargarComentarios() async {
    cargando = true;
    notifyListeners();
    try {
      comentarios = await service.obtenerComentarios(idHistoriaClinica);
    } catch (e) {
      debugPrint('Error al cargar comentarios: $e');
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> agregarComentario(String autor, String texto) async {
    if (texto.trim().isEmpty) return;
    enviando = true;
    notifyListeners();

    final nuevo = Comentario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      autor: autor,
      texto: texto,
      fecha: DateTime.now(),
    );

    try {
      final creado = await service.crearComentario(idHistoriaClinica, nuevo);
      comentarios.insert(0, creado);
    } catch (e) {
      debugPrint('Error al crear comentario: $e');
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
