import 'dart:collection';

class ComentarioArchivo {
  final String id;
  final String nombre;
  final String tipo;
  final int? pesoBytes;
  final String urlDescarga;
  final String? historiaClinicaId;
  final String? comentarioId;

  const ComentarioArchivo({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.urlDescarga,
    this.pesoBytes,
    this.historiaClinicaId,
    this.comentarioId,
  });

  bool get esTemporal => id.startsWith('temp-file-');

  ComentarioArchivo copyWith({
    String? id,
    String? nombre,
    String? tipo,
    int? pesoBytes,
    String? urlDescarga,
    String? historiaClinicaId,
    String? comentarioId,
  }) {
    return ComentarioArchivo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      pesoBytes: pesoBytes ?? this.pesoBytes,
      urlDescarga: urlDescarga ?? this.urlDescarga,
      historiaClinicaId: historiaClinicaId ?? this.historiaClinicaId,
      comentarioId: comentarioId ?? this.comentarioId,
    );
  }

  static String _sanitizeBaseUrl(String? url) {
    if (url == null) return '';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  factory ComentarioArchivo.fromJson(
    Map<String, dynamic> json, {
    String? historiaClinicaId,
    String? comentarioId,
    String? baseUrl,
  }) {
    final id = _resolveString(json, ['id', 'idArchivo', 'archivoId', 'uid']);
    final historiaId = historiaClinicaId ??
        _resolveString(json, [
          'historiaClinicaId',
          'historiaClinica',
          'historiaId',
          'idHistoriaClinica',
        ]);

    final comentario = comentarioId ??
        _resolveString(json, [
          'comentarioId',
          'idComentario',
          'comentario',
        ]);

    final peso = _resolveInt(json, ['pesoBytes', 'peso', 'tamano', 'tamanio', 'size']);
    final rawUrl = _resolveString(json, ['urlDescarga', 'url', 'enlace']);

    final sanitizedBase = _sanitizeBaseUrl(baseUrl);
    final effectiveUrl = _buildDownloadUrl(
      rawUrl: rawUrl,
      baseUrl: sanitizedBase,
      historiaId: historiaId,
      comentarioId: comentario,
      archivoId: id,
    );

    return ComentarioArchivo(
      id: id,
      nombre: _resolveString(json, ['nombre', 'nombreArchivo', 'titulo'], defaultValue: 'Archivo adjunto'),
      tipo: _resolveString(json, ['tipo', 'tipoMime', 'mime']),
      pesoBytes: peso,
      urlDescarga: effectiveUrl,
      historiaClinicaId: historiaId,
      comentarioId: comentario,
    );
  }

  static String _buildDownloadUrl({
    required String rawUrl,
    required String baseUrl,
    required String? historiaId,
    required String? comentarioId,
    required String archivoId,
  }) {
    if (rawUrl.isNotEmpty) {
      if (rawUrl.startsWith('http')) return rawUrl;
      if (baseUrl.isEmpty) return rawUrl;
      final prefix = rawUrl.startsWith('/') ? '' : '/';
      return '$baseUrl$prefix$rawUrl';
    }

    if (baseUrl.isEmpty) return '';

    if (historiaId != null && historiaId.isNotEmpty &&
        comentarioId != null && comentarioId.isNotEmpty) {
      return '$baseUrl/historia-clinica/$historiaId/comentarios/$comentarioId/archivos/$archivoId';
    }

    if (comentarioId != null && comentarioId.isNotEmpty) {
      return '$baseUrl/comentarios/$comentarioId/archivos/$archivoId';
    }

    return '';
  }
}

class ComentarioUsuario {
  final String idUsuario;
  final String? idUsuarioRol;
  final String? rol;
  final String nombres;
  final String primerApellido;
  final String? segundoApellido;
  final String? urlFoto;

  const ComentarioUsuario({
    required this.idUsuario,
    this.idUsuarioRol,
    this.rol,
    required this.nombres,
    required this.primerApellido,
    this.segundoApellido,
    this.urlFoto,
  });

  String get nombreCompleto =>
      [nombres, primerApellido, segundoApellido]
          .where((value) => value != null && value!.trim().isNotEmpty)
          .map((value) => value!.trim())
          .join(' ');

  factory ComentarioUsuario.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};
    return ComentarioUsuario(
      idUsuario: _resolveString(data, ['idUsuario', 'id']),
      idUsuarioRol: _resolveNullableString(data, ['idUsuarioRol', 'idRol']),
      rol: _resolveNullableString(data, ['rol', 'nombreRol']),
      nombres: _resolveString(data, ['nombres'], defaultValue: ''),
      primerApellido: _resolveString(data, ['primerApellido'], defaultValue: ''),
      segundoApellido: _resolveNullableString(data, ['segundoApellido']),
      urlFoto: _resolveNullableString(data, ['urlFoto', 'foto', 'fotoUrl']),
    );
  }
}

class ComentarioChat {
  final String id;
  final String contenido;
  final DateTime fechaCreacion;
  final DateTime? fechaModificacion;
  final String? idComentarioPadre;
  final ComentarioUsuario usuario;
  final List<ComentarioArchivo> archivos;
  final List<ComentarioChat> respuestas;
  final bool eliminado;

  const ComentarioChat({
    required this.id,
    required this.contenido,
    required this.fechaCreacion,
    required this.usuario,
    this.fechaModificacion,
    this.idComentarioPadre,
    this.archivos = const [],
    this.respuestas = const [],
    this.eliminado = false,
  });

  bool get esRespuesta => idComentarioPadre != null;

  bool get fueEditado => fechaModificacion != null;

  ComentarioChat copyWith({
    String? id,
    String? contenido,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    String? idComentarioPadre,
    ComentarioUsuario? usuario,
    List<ComentarioArchivo>? archivos,
    List<ComentarioChat>? respuestas,
    bool? eliminado,
  }) {
    return ComentarioChat(
      id: id ?? this.id,
      contenido: contenido ?? this.contenido,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      idComentarioPadre: idComentarioPadre ?? this.idComentarioPadre,
      usuario: usuario ?? this.usuario,
      archivos: archivos ?? this.archivos,
      respuestas: respuestas ?? this.respuestas,
      eliminado: eliminado ?? this.eliminado,
    );
  }

  factory ComentarioChat.fromJson(
    Map<String, dynamic> json, {
    String? historiaClinicaId,
    String? baseUrl,
  }) {
    final id = _resolveString(json, ['id', 'idComentario', 'comentarioId']);
    final historiaId = historiaClinicaId ??
        _resolveString(json, [
          'historiaClinicaId',
          'historiaClinica',
          'historiaId',
          'idHistoriaClinica',
        ],
            allowNull: true);

    final respuestasRaw = (json['respuestas'] as List<dynamic>?) ?? const [];

    return ComentarioChat(
      id: id,
      contenido: _resolveString(json, ['contenido', 'texto', 'comentario'],
          defaultValue: ''),
      fechaCreacion:
          _parseDateTime(json['fechaCreacion'] ?? json['createdAt']) ??
              DateTime.now(),
      fechaModificacion:
          _parseDateTime(json['fechaModificacion'] ?? json['updatedAt']),
      idComentarioPadre:
          _resolveNullableString(json, ['idComentarioPadre', 'comentarioPadreId']),
      usuario: ComentarioUsuario.fromJson(
        (json['usuario'] as Map<String, dynamic>?) ??
            (json['autor'] as Map<String, dynamic>?),
      ),
      archivos: (json['archivos'] as List<dynamic>? ?? [])
          .map(
            (archivo) => ComentarioArchivo.fromJson(
              archivo as Map<String, dynamic>,
              historiaClinicaId: historiaId,
              comentarioId: id,
              baseUrl: baseUrl,
            ),
          )
          .toList(),
      respuestas: respuestasRaw
          .map(
            (respuesta) => ComentarioChat.fromJson(
              respuesta as Map<String, dynamic>,
              historiaClinicaId: historiaId,
              baseUrl: baseUrl,
            ),
          )
          .toList(),
      eliminado: json['eliminado'] == true,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class ComentariosPaginados {
  final List<ComentarioChat> comentarios;
  final int total;
  final int pagina;
  final int limite;

  const ComentariosPaginados({
    required this.comentarios,
    required this.total,
    required this.pagina,
    required this.limite,
  });

  bool get esUltimaPagina => comentarios.length >= total;
}

class ComentarioArchivoLocal {
  final String id;
  final String nombre;
  final String? path;
  final int sizeBytes;
  final String? mimeType;

  ComentarioArchivoLocal({
    required this.id,
    required this.nombre,
    required this.path,
    required this.sizeBytes,
    required this.mimeType,
  });

  factory ComentarioArchivoLocal.fromPlatformFile(dynamic file) {
    final extension = (file.extension ?? '').toString().toLowerCase();
    return ComentarioArchivoLocal(
      id: 'temp-file-${DateTime.now().millisecondsSinceEpoch}-${file.name}',
      nombre: file.name,
      path: file.path,
      sizeBytes: file.size,
      mimeType: _inferMimeType(extension),
    );
  }
}

int _resolveInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      final value = json[key];
      if (value is int) return value;
      if (value is double) return value.round();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

String _resolveString(
  Map<String, dynamic> json,
  List<String> keys, {
  String defaultValue = '',
  bool allowNull = false,
}) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        final nestedId = _resolveString(value, ['id'], defaultValue: '');
        if (nestedId.isNotEmpty) return nestedId;
      }
      final stringValue = value.toString();
      if (stringValue.isNotEmpty) {
        return stringValue;
      }
    }
  }
  if (allowNull) return '';
  return defaultValue;
}

String? _resolveNullableString(Map<String, dynamic> json, List<String> keys) {
  final value = _resolveString(json, keys, allowNull: true);
  return value.isEmpty ? null : value;
}

List<ComentarioChat> mergeComentarios(
  List<ComentarioChat> existentes,
  List<ComentarioChat> nuevos,
) {
  final Map<String, ComentarioChat> mapa = {
    for (final comentario in existentes) comentario.id: comentario,
  };

  for (final comentario in nuevos) {
    mapa[comentario.id] = _mergeComentario(mapa[comentario.id], comentario);
  }

  final lista = mapa.values.toList();
  lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  return lista;
}

ComentarioChat _mergeComentario(
  ComentarioChat? existente,
  ComentarioChat entrante,
) {
  if (existente == null) {
    return entrante;
  }

  final respuestasActualizadas = entrante.respuestas.isEmpty
      ? existente.respuestas
      : mergeComentarios(existente.respuestas, entrante.respuestas);

  return existente.copyWith(
    contenido: entrante.contenido.isNotEmpty
        ? entrante.contenido
        : existente.contenido,
    fechaCreacion: entrante.fechaCreacion,
    fechaModificacion: entrante.fechaModificacion ?? existente.fechaModificacion,
    archivos: entrante.archivos.isNotEmpty
        ? List<ComentarioArchivo>.unmodifiable(entrante.archivos)
        : existente.archivos,
    respuestas: respuestasActualizadas,
    eliminado: entrante.eliminado,
  );
}

UnmodifiableListView<ComentarioArchivo> unmodifiableArchivos(
  List<ComentarioArchivo> archivos,
) => UnmodifiableListView(archivos);

String _inferMimeType(String extension) {
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'bmp':
      return 'image/bmp';
    case 'tiff':
      return 'image/tiff';
    case 'svg':
      return 'image/svg+xml';
    case 'pdf':
      return 'application/pdf';
    case 'mp3':
      return 'audio/mpeg';
    case 'aac':
      return 'audio/aac';
    case 'wav':
      return 'audio/wav';
    case 'ogg':
      return 'audio/ogg';
    case 'flac':
      return 'audio/flac';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'avi':
      return 'video/x-msvideo';
    case 'mpeg':
    case 'mpg':
      return 'video/mpeg';
    case 'webm':
      return 'video/webm';
    default:
      return 'application/octet-stream';
  }
}
