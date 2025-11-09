# Cambios recientes en el canal de comentarios (modificación 1)

## Actualizaciones principales
- Se añadió el evento unificado `comentario:cambio` en el gateway de comentarios para notificar en tiempo real cualquier creación, actualización o eliminación sin necesidad de escuchar múltiples eventos.
- Se reforzó la validación al descargar adjuntos verificando que el comentario pertenezca a la historia clínica solicitada.
- Se habilitó un nuevo endpoint contextual de descarga: `GET /historia-clinica/{historiaId}/comentarios/{comentarioId}/archivos/{archivoId}`.
- Se factorizaron las respuestas de descarga de archivos para reutilizar la misma lógica en los controladores REST.

## Impacto esperado
- Los clientes pueden sincronizar la conversación suscribiéndose únicamente a `comentario:cambio`.
- Pacientes y nutricionistas reciben confirmación inmediata de cambios sin depender de la fuente que originó la acción.
- Las descargas de adjuntos funcionan tanto desde el contexto del comentario como del historial clínico, manteniendo controles de acceso consistentes.
