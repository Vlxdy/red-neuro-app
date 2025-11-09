# Guía para la implementación del chat en el frontend

## 1. Preparar la capa de datos
1. **Obtener el historial inicial**
   - Consumir `GET /historia-clinica/{id}/comentarios` para recuperar los mensajes ordenados.
   - Mapear cada entrada usando los atributos `usuario`, `idComentarioPadre` y `respuestas` para reconstruir los hilos.
2. **Enviar mensajes y adjuntos**
   - Utilizar `POST /historia-clinica/{id}/comentarios` para mensajes nuevos.
   - Para responder dentro de un hilo, llamar a `POST /comentarios/{id}/reply` enviando el `contenido`.
   - Ambos endpoints aceptan `multipart/form-data` con el campo opcional `archivos[]` (hasta `CHAT_MAX_FILES`, por defecto 5) donde cada item es un binario.
   - Tipos soportados: PDF, imágenes (`jpeg`, `png`, `webp`, `gif`, `bmp`, `tiff`, `svg`), audio (`mp3`, `aac`, `wav`, `ogg`, `webm`, `flac`) y video (`mp4`, `webm`, `ogg`, `mov`, `avi`, `mpeg`).
   - El tamaño máximo individual es `CHAT_MAX_FILE_MB` (25 MB por defecto); excederlo genera un `400 Bad Request`.
3. **Actualizar o eliminar**
   - Las ediciones se realizan con `PATCH /comentarios/{id}` y las eliminaciones lógicas con `PATCH /comentarios/{id}/inactivar`.

## 2. Configurar el canal WebSocket
1. **Conexión**
   - Conectar a `wss://<backend>/comentarios` enviando el JWT en `auth.token` o encabezado `Authorization`.
2. **Gestión de salas**
   - Emitir `joinHistoriaClinica` con `{ historiaClinicaId }` al entrar a un historial.
   - Emitir `leaveHistoriaClinica` al abandonar la vista para liberar recursos.
3. **Eventos disponibles**
   - `comentario:creado`: contiene un `ComentarioChatDto` para insertar el nuevo mensaje (incluye `archivos[]` cuando existan adjuntos).
   - `comentario:actualizado`: sustituye el contenido del mensaje indicado.
   - `comentario:eliminado`: incluye `{ id }` para ocultar el mensaje en la interfaz.
   - `comentario:cambio`: evento unificado que envía `{ tipo, historiaClinicaId, comentario | comentarioId }` para reaccionar ante cualquier modificación sin tener que escuchar los eventos anteriores de forma individual.

## 3. Actualización del estado del chat
1. **Sincronización inicial**
   - Cargar el listado REST y después suscribirse a los eventos del socket para mantener el estado actualizado.
2. **Optimistic UI**
   - Mostrar el mensaje inmediatamente en la interfaz y reconciliarlo con la respuesta del backend (REST o socket) usando el `id` definitivo.
3. **Gestión de permisos**
   - Bloquear acciones de edición/eliminación cuando `usuario.idUsuarioRol` no coincida con el del mensaje, salvo que el usuario tenga rol administrador.
4. **Manejo de adjuntos**
   - Renderizar la colección `archivos` de cada mensaje mostrando nombre, tamaño y un enlace a `urlDescarga` (`/comentarios/{id}/archivos/{archivoId}`) autenticado.
   - Alternativamente, se puede construir la URL contextual al historial: `/historia-clinica/{historiaId}/comentarios/{comentarioId}/archivos/{archivoId}`.
   - Para previsualizaciones rápidas limitarse a imágenes o PDF; otros tipos pueden descargarse o abrirse en una pestaña nueva.
   - Considerar subir de forma optimista los archivos mostrando progreso y deshabilitando la acción hasta completar la subida.

## 4. Experiencia de usuario sugerida
- Mostrar avatar y nombre usando los campos `usuario.urlFoto`, `nombres` y `primerApellido`.
- Destacar los mensajes del usuario autenticado para diferenciar quién habla.
- Notificar visualmente cuando un mensaje sea editado o eliminado tras recibir los eventos correspondientes.
