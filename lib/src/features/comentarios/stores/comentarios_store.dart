import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:alimenta_app/src/constants/constants.dart';
import 'package:alimenta_app/src/features/comentarios/models/comentario_chat_models.dart';
import 'package:alimenta_app/src/features/comentarios/services/comentarios_service.dart';
import 'package:alimenta_app/src/features/comentarios/services/comentarios_socket_service.dart';
import 'package:alimenta_app/src/plugins/auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ComentariosStore extends ChangeNotifier {
  ComentariosStore({
    required this.service,
    required this.idHistoriaClinica,
    this.limite = 20,
  });

  final ComentariosService service;
  final String idHistoriaClinica;
  final int limite;

  final List<ComentarioChat> _comentarios = [];
  final Map<String, ComentarioChat> _comentariosIndex = {};

  bool _cargando = false;
  bool _cargandoMas = false;
  bool _enviando = false;
  bool _initialized = false;
  bool _error = false;
  bool _isLastPage = false;
  int _pagina = 1;
  int _total = 0;

  ComentarioChat? _comentarioEnEdicion;
  ComentarioChat? _comentarioEnRespuesta;

  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get enviando => _enviando;
  bool get initialized => _initialized;
  bool get isLastPage => _isLastPage;
  int get total => _total;
  bool get hayError => _error;

  ComentarioChat? get comentarioEnEdicion => _comentarioEnEdicion;
  ComentarioChat? get comentarioEnRespuesta => _comentarioEnRespuesta;

  UnmodifiableListView<ComentarioChat> get comentarios =>
      UnmodifiableListView(_comentarios);

  Future<void> inicializar() async {
    if (_initialized) return;
    _initialized = true;
    await cargarComentarios(reset: true);
    await _conectarSocket();
  }

  Future<void> cargarComentarios({bool reset = false}) async {
    if (_cargando || _cargandoMas) return;
    if (reset) {
      _pagina = 1;
      _isLastPage = false;
    } else if (_isLastPage) {
      return;
    }

    _setLoading(reset ? true : false, !reset);

    try {
      final response = await service.obtenerComentarios(
        idHistoriaClinica,
        pagina: _pagina,
        limite: limite,
      );

      _total = response.total;
      _isLastPage = _comentarios.length + response.comentarios.length >= _total;

      if (reset) {
        _comentarios
          ..clear()
          ..addAll(response.comentarios);
      } else {
        _mergeComentarios(response.comentarios);
      }

      _reconstruirIndice();
      _ordenarComentarios();
      _pagina = min(_pagina + 1, (_total / limite).ceil() + 1);
      _error = false;
    } catch (error) {
      _error = true;
      rethrow;
    } finally {
      _setLoading(false, false);
      notifyListeners();
    }
  }

  void _setLoading(bool cargando, bool cargandoMas) {
    _cargando = cargando;
    _cargandoMas = cargandoMas;
    notifyListeners();
  }

  Future<void> _conectarSocket() async {
    try {
      await ComentariosSocketService.instance.connect();
      ComentariosSocketService.instance.joinHistoriaClinica(idHistoriaClinica);
      ComentariosSocketService.instance.onCambio(_handleSocketCambio);
    } catch (_) {
      // Ignorar errores de conexión inicial; se intentará en llamadas futuras
    }
  }

  void disposeSocket() {
    ComentariosSocketService.instance.offCambio(_handleSocketCambio);
    ComentariosSocketService.instance.leaveHistoriaClinica(idHistoriaClinica);
    ComentariosSocketService.instance.disconnect();
  }

  Future<void> enviarComentario({
    required String contenido,
    List<ComentarioArchivoLocal> archivos = const [],
  }) async {
    if (contenido.trim().isEmpty) return;
    _enviando = true;
    notifyListeners();

    final temporalId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final comentarioTemporal = ComentarioChat(
      id: temporalId,
      contenido: contenido,
      fechaCreacion: DateTime.now(),
      usuario: _usuarioActual(),
      archivos: archivos
          .map((archivo) => ComentarioArchivo(
                id: archivo.id,
                nombre: archivo.nombre,
                tipo: archivo.mimeType ?? 'application/octet-stream',
                urlDescarga: '',
                historiaClinicaId: idHistoriaClinica,
                comentarioId: temporalId,
                pesoBytes: archivo.sizeBytes,
              ))
          .toList(),
    );

    _insertarComentario(comentarioTemporal);

    try {
      final comentario = await service.crearComentario(
        idHistoriaClinica: idHistoriaClinica,
        contenido: contenido,
        archivos: archivos,
      );
      _actualizarComentario(comentarioTemporal.id, comentario);
    } catch (_) {
      _eliminarComentario(comentarioTemporal.id);
      rethrow;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  Future<void> responderComentario({
    required ComentarioChat padre,
    required String contenido,
    List<ComentarioArchivoLocal> archivos = const [],
  }) async {
    if (contenido.trim().isEmpty) return;
    _enviando = true;
    notifyListeners();

    final temporalId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final respuestaTemporal = ComentarioChat(
      id: temporalId,
      contenido: contenido,
      fechaCreacion: DateTime.now(),
      usuario: _usuarioActual(),
      idComentarioPadre: padre.id,
      archivos: archivos
          .map((archivo) => ComentarioArchivo(
                id: archivo.id,
                nombre: archivo.nombre,
                tipo: archivo.mimeType ?? 'application/octet-stream',
                urlDescarga: '',
                historiaClinicaId: idHistoriaClinica,
                comentarioId: padre.id,
                pesoBytes: archivo.sizeBytes,
              ))
          .toList(),
    );

    _insertarRespuesta(padre.id, respuestaTemporal);

    try {
      final respuesta = await service.responderComentario(
        idComentario: padre.id,
        contenido: contenido,
        archivos: archivos,
        historiaClinicaId: idHistoriaClinica,
      );
      _actualizarComentario(respuestaTemporal.id, respuesta);
    } catch (_) {
      _eliminarComentario(respuestaTemporal.id);
      rethrow;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  Future<void> editarComentario({
    required ComentarioChat comentario,
    required String contenido,
  }) async {
    if (contenido.trim().isEmpty) return;

    final actualizado = await service.actualizarComentario(
      idComentario: comentario.id,
      contenido: contenido,
      historiaClinicaId: idHistoriaClinica,
    );

    _actualizarComentario(comentario.id, actualizado);
    notifyListeners();
  }

  Future<void> eliminarComentario(String idComentario) async {
    await service.eliminarComentario(idComentario);
    _eliminarComentario(idComentario);
    notifyListeners();
  }

  void seleccionarEdicion(ComentarioChat? comentario) {
    _comentarioEnEdicion = comentario;
    notifyListeners();
  }

  void seleccionarRespuesta(ComentarioChat? comentario) {
    _comentarioEnRespuesta = comentario;
    notifyListeners();
  }

  Future<void> descargarArchivo(ComentarioArchivo archivo) async {
    if (archivo.urlDescarga.isEmpty) return;
    final bytes = await service.descargarArchivo(url: archivo.urlDescarga);
    final tempDir = await getTemporaryDirectory();
    final sanitizedName = archivo.nombre
        .replaceAll(RegExp(r'[\\/:]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final filePath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
  }

  void _handleSocketCambio(dynamic payload) {
    if (payload == null) return;
    final data = payload is Map<String, dynamic>
        ? payload
        : Map<String, dynamic>.from(payload as Map);

    final historia = data['historiaClinicaId']?.toString() ??
        data['historiaId']?.toString() ??
        data['idHistoriaClinica']?.toString() ??
        '';

    if (historia.isNotEmpty && historia != idHistoriaClinica) {
      return;
    }

    final tipo = (data['tipo'] ?? '').toString().toLowerCase();
    final comentarioPayload =
        data['comentario'] ?? data['dato'] ?? data['payload'] ?? data;

    if (tipo == 'eliminado') {
      final id = (data['comentarioId'] ??
              data['id'] ??
              comentarioPayload['id'] ??
              comentarioPayload['comentarioId'])
          .toString();
      _eliminarComentario(id);
      notifyListeners();
      return;
    }

    if (comentarioPayload is! Map) {
      return;
    }

    final comentarioMap = Map<String, dynamic>.from(
      comentarioPayload,
    );

    if (comentarioMap.isEmpty) {
      return;
    }

    final comentario = ComentarioChat.fromJson(
      comentarioMap,
      historiaClinicaId: historia.isNotEmpty ? historia : idHistoriaClinica,
      baseUrl: Constantes.apiUrl,
    );

    if (comentario.eliminado) {
      _eliminarComentario(comentario.id);
      notifyListeners();
      return;
    }

    _actualizarComentario(comentario.id, comentario);
    notifyListeners();
  }

  void _insertarComentario(ComentarioChat comentario) {
    _comentarios.removeWhere((element) => element.id == comentario.id);
    _comentarios.insert(0, comentario);
    _comentariosIndex[comentario.id] = comentario;
  }

  void _insertarRespuesta(String padreId, ComentarioChat respuesta) {
    final indice = _comentarios.indexWhere((element) => element.id == padreId);
    if (indice == -1) return;
    final comentarioPadre = _comentarios[indice];
    final respuestas = [...comentarioPadre.respuestas, respuesta];
    final actualizado = comentarioPadre.copyWith(respuestas: respuestas);
    _comentarios[indice] = actualizado;
    _comentariosIndex[padreId] = actualizado;
    _comentariosIndex[respuesta.id] = respuesta;
  }

  void _actualizarComentario(String idTemporal, ComentarioChat comentario) {
    if (comentario.idComentarioPadre == null) {
      _comentarios.removeWhere(
        (item) => item.id == idTemporal || item.id == comentario.id,
      );
      _comentarios.add(comentario);
    } else {
      final padreId = comentario.idComentarioPadre!;
      final idxPadre = _comentarios.indexWhere((item) => item.id == padreId);
      if (idxPadre != -1) {
        final padre = _comentarios[idxPadre];
        final respuestas = padre.respuestas
            .where(
              (res) => res.id != idTemporal && res.id != comentario.id,
            )
            .toList()
          ..add(comentario);
        respuestas.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        _comentarios[idxPadre] = padre.copyWith(respuestas: respuestas);
      } else {
        _mergeComentarios([comentario]);
      }
    }

    _reconstruirIndice();
    _ordenarComentarios();
  }

  void _mergeComentarios(List<ComentarioChat> nuevos) {
    for (final comentario in nuevos) {
      final existenteIndex =
          _comentarios.indexWhere((item) => item.id == comentario.id);
      if (existenteIndex == -1) {
        _comentarios.add(comentario);
      } else {
        _comentarios[existenteIndex] = comentario;
      }
    }
  }

  void _ordenarComentarios() {
    _comentarios.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  void _reconstruirIndice() {
    _comentariosIndex
      ..clear()
      ..addEntries(
        _comentarios.map((comentario) => MapEntry(comentario.id, comentario)),
      );
    for (final comentario in _comentarios) {
      for (final respuesta in comentario.respuestas) {
        _comentariosIndex[respuesta.id] = respuesta;
      }
    }
  }

  ComentarioUsuario _usuarioActual() {
    final profile = Auth.instance.profile;
    return ComentarioUsuario(
      idUsuario: profile.id ?? '',
      idUsuarioRol: profile.idUsuarioRol,
      rol: profile.rol,
      nombres: profile.nombres,
      primerApellido: profile.primerApellido,
      segundoApellido: profile.segundoApellido,
      urlFoto: profile.urlFoto,
    );
  }

  void _eliminarComentario(String idComentario) {
    final indice =
        _comentarios.indexWhere((element) => element.id == idComentario);
    if (indice != -1) {
      _comentarios.removeAt(indice);
      _comentariosIndex.remove(idComentario);
      _total = max(0, _total - 1);
      return;
    }

    for (var i = 0; i < _comentarios.length; i++) {
      final comentario = _comentarios[i];
      final respuestas = comentario.respuestas
          .where((respuesta) => respuesta.id != idComentario)
          .toList();
      if (respuestas.length != comentario.respuestas.length) {
        _comentarios[i] = comentario.copyWith(respuestas: respuestas);
        _comentariosIndex.remove(idComentario);
        break;
      }
    }
  }

  @override
  void dispose() {
    disposeSocket();
    super.dispose();
  }
}
