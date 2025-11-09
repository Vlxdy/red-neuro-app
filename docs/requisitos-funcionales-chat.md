# Requisitos funcionales y criterios de aceptación - Chat de comentarios

## Requisitos funcionales
- **RF-01**: El sistema debe permitir a pacientes, nutricionistas asignados y administradores enviar y recibir mensajes en tiempo real dentro del historial clínico del paciente.
- **RF-02**: El backend debe validar que un nutricionista solo pueda interactuar en los historiales clínicos de los pacientes que tiene asignados activamente.
- **RF-03**: El administrador debe poder participar en cualquier sala de conversación sin restricciones de asignación.
- **RF-04**: Las actualizaciones, ediciones o eliminaciones de mensajes deben propagarse de forma inmediata a todos los participantes conectados mediante WebSockets.
- **RF-05**: El historial de mensajes debe mantenerse ordenado cronológicamente y disponible mediante los endpoints REST para respaldar el estado inicial del chat.
- **RF-06**: El sistema debe permitir adjuntar archivos multimedia (PDF, imágenes, audio y video) a los mensajes, almacenarlos de forma persistente y exponerlos a los participantes autorizados.
- **RF-07**: El canal WebSocket debe emitir un evento unificado (`comentario:cambio`) cada vez que se cree, actualice o elimine un mensaje para simplificar la sincronización del frontend.

## Criterios de aceptación
- **CA-01**: Dado un paciente autenticado, cuando accede a su historial clínico, entonces puede ver el listado de mensajes ordenados cronológicamente y enviar nuevos mensajes que quedan asociados a su usuario.
- **CA-02**: Dado un nutricionista autenticado, cuando intenta enviar un mensaje en el historial clínico de un paciente no asignado, entonces recibe un error de autorización y el mensaje no se registra.
- **CA-03**: Dado un administrador autenticado, cuando se une a cualquier historial clínico, entonces puede leer y enviar mensajes sin restricciones adicionales.
- **CA-04**: Dado un participante del chat que edita o elimina un mensaje propio, cuando la operación finaliza correctamente, entonces el resto de usuarios conectados recibe un evento por socket que refleja el cambio en tiempo real.
- **CA-05**: Dado un usuario que actualiza la vista del historial clínico, cuando el backend responde al listado de comentarios, entonces la información incluye los datos del emisor y las réplicas asociadas al hilo para reconstruir la conversación.
- **CA-06**: Dado un participante autorizado que adjunta un archivo soportado a su mensaje (respetando el límite de cantidad y tamaño), cuando el comentario se crea correctamente, entonces el adjunto se almacena y se expone en la respuesta REST y en el evento WebSocket junto con una URL autenticada para su descarga.
- **CA-07**: Dado un usuario con acceso a un historial clínico, cuando escucha el evento `comentario:cambio`, entonces puede identificar el tipo de operación (`creado`, `actualizado`, `eliminado`) y sincronizar la conversación sin suscribirse a eventos adicionales.
- **CA-08**: Dado un participante autorizado que cuenta con la URL contextual `/historia-clinica/{historiaId}/comentarios/{comentarioId}/archivos/{archivoId}`, cuando la solicita autenticado, entonces el backend devuelve el archivo correspondiente si pertenece a la historia indicada.
