# Propuesta recomendada del flujo de citas (backend)

Este documento deja **únicamente** la propuesta objetivo del flujo de citas, eliminando la descripción del funcionamiento actual.

---

## 1. Objetivo

Definir un flujo de citas con reglas claras de transición, trazabilidad completa y restricciones por estado/rol para evitar inconsistencias operativas.

---

## 2. Estados propuestos

- `BORRADOR`: cita guardada, aún no enviada.
- `SOLICITADA`: cita enviada con personal de salud asignado.
- `CONFIRMADA`: cita validada para atención.
- `RECHAZADA`: cita rechazada por el profesional asignado.
- `CANCELADA`: cita cancelada.
- `NO_ASISTIO`: cita vencida sin atención efectiva.
- `REPROGRAMADA`: cita cerrada por reprogramación.
- `COMPLETADA`: cita atendida correctamente.
- `INACTIVO`: cita eliminada lógicamente (estado interno de backend, no visible en listados operativos).

---

## 3. Reglas de creación (guardar vs enviar)

Toda creación debe indicar intención:

1. `GUARDAR` -> crea en `BORRADOR`.
2. `ENVIAR`:
   - con `idMedico` -> pasa a `SOLICITADA`.
   - sin `idMedico` -> pasa a `CONFIRMADA`.

### Notificación

La notificación al médico asignado se envía **solo** cuando la cita entra a estado `SOLICITADA`.

---

## 4. Reglas por estado

- `BORRADOR`
  - Editable solo por **creador** o **administrador**.
  - Puede enviarse (`SOLICITADA` o `CONFIRMADA`).
  - Puede cancelarse.
  - Puede eliminarse de forma lógica (nunca física), para evitar confusión con citas activas.
  - Solo la visualiza quien la creó y el administrador.

- `SOLICITADA`
  - Solo el profesional asignado o el administrador puede gestionarla.
  - Acciones permitidas: confirmar, rechazar o modificar **solo hora y detalle**.
  - Tras una modificación, el siguiente paso operativo es confirmar o rechazar (sin guardar intermedio adicional).
  - No se cancela directamente en este estado.

- `CONFIRMADA`
  - No editable.
  - Permite cancelar o reprogramar.

- `CANCELADA`
  - No editable.
  - Solo permite reprogramar.

- `NO_ASISTIO`
  - No editable.
  - Solo permite reprogramar.

- `REPROGRAMADA`
  - No editable.
  - Estado terminal histórico.

- `COMPLETADA`
  - Estado terminal funcional cuando la atención finalizó correctamente.

### Regla global de borrado

No se permite borrado físico de citas en ningún estado.

---

## 5. Reprogramación y trazabilidad

Cuando se reprograma una cita (`CONFIRMADA`, `CANCELADA` o `NO_ASISTIO`):

1. La cita original pasa a `REPROGRAMADA`.
2. Se crea una nueva cita con fecha/datos nuevos.
3. La cita original guarda `idCitaNueva` para apuntar a la nueva cita.
4. Toda la cadena de reprogramaciones comparte `idHistorialCita` para trazabilidad padre/hijas múltiples.

---

## 6. Matriz de transiciones recomendada

- `BORRADOR` -> `SOLICITADA` | `CONFIRMADA` | `CANCELADA` | `INACTIVO` (eliminación lógica)
- `SOLICITADA` -> `CONFIRMADA` | `RECHAZADA` | `SOLICITADA` (modificación sin cambiar estado)
- `CONFIRMADA` -> `REPROGRAMADA` | `CANCELADA` | `COMPLETADA`
- `RECHAZADA` -> `SOLICITADA` (al modificar y reenviar)
- `CANCELADA` -> `REPROGRAMADA`
- `NO_ASISTIO` -> `REPROGRAMADA`
- `COMPLETADA` -> _(sin salida)_
- `REPROGRAMADA` -> _(sin salida)_

---

## 7. Auditoría: quién programó y quién envió

Para cumplir el requerimiento de trazabilidad de actores, la cita debe registrar explícitamente:

- `idUsuarioProgramo`: usuario que creó/programó inicialmente la cita (acción de guardado o creación).
- `idUsuarioEnvio`: usuario que ejecutó la acción de envío de cita a flujo operativo.

> Ambos identificadores deben registrar `idUsuarioRol` (no solo id de usuario), ya que ese es el identificador operativo de autorización/auditoría.

### Reglas sugeridas

1. Si la cita se crea directamente con `ENVIAR`, se registran ambos campos con el mismo usuario (si aplica).
2. Si primero se guarda en `BORRADOR` y luego otro usuario la envía:
   - `idUsuarioProgramo` = quien guardó/creó borrador.
   - `idUsuarioEnvio` = quien la envió.
3. Las citas en `BORRADOR` y `RECHAZADA` solo deben listarse para su creador y administrador.
4. Ambos campos deben exponerse en GET detalle, listado e historial.
5. Todo cambio de estos campos debe quedar auditado en historial de cita.

---

## 8. Implementación técnica recomendada

1. Extender/ajustar enum de estados con `BORRADOR`, `REPROGRAMADA`, `INACTIVO` y asegurar `COMPLETADA` como estado terminal de atención.
2. Añadir columnas:
   - `id_cita_nueva` (FK nullable a `citas.id`)
   - `id_historial_cita` (agrupador de cadena)
   - `id_usuario_programo`
   - `id_usuario_envio`
3. Exponer en DTO/API:
   - `idCitaNueva`
   - `idHistorialCita`
   - `idUsuarioProgramo`
   - `idUsuarioEnvio`
4. Implementar máquina de estados estricta en backend.
5. Restringir edición de `BORRADOR` a creador/admin (Casbin + validación de dominio).
6. Restringir gestión de `SOLICITADA` a profesional asignado o administrador.
7. Restringir visibilidad de `BORRADOR` y `RECHAZADA` a creador/admin.
8. Reprogramar en transacción: cerrar original + crear nueva + actualizar vínculos.
9. Para `RECHAZADA`, habilitar flujo de corrección y reenvío (`RECHAZADA -> SOLICITADA`) sin reprogramación.
10. Permitir cancelación solo desde `CONFIRMADA`.
11. Permitir `COMPLETADA` desde `CONFIRMADA` cuando se registre atención efectiva.
12. Mantener notificación al médico únicamente al entrar en `SOLICITADA`.
13. SLA de notificaciones: pendiente de definición funcional.
14. Inhabilitar borrado físico de citas en repositorio.
15. Implementar eliminación lógica como transición a `INACTIVO` y excluir `INACTIVO` de listados operativos por defecto.

---

## 9. Resultado esperado

Con esta propuesta:

- se unifica el flujo operativo de citas con reglas claras.
- se controla quién puede editar en cada estado.
- se diferencia claramente eliminación lógica (solo en borrador, hacia `INACTIVO`) vs cancelación.
- se asegura trazabilidad completa de reprogramaciones.
- se identifica claramente **quién programó** y **quién envió** cada cita usando `idUsuarioRol`.
- se preserva la integridad histórica al no permitir borrado físico.


## 10. Observaciones para implementación en código actual

1. `INACTIVO` debe tratarse como estado técnico de backend:
   - no se muestra en listados funcionales estándar,
   - se usa para baja lógica de borradores.
2. La operación de "eliminar borrador" no debe usar `delete` físico; debe actualizar `estado = INACTIVO` y auditoría.
3. En `SOLICITADA`, validar por backend que los únicos campos editables sean `fechaInicio`/hora y `detalle`; cualquier otro campo debe rechazarse.
4. Para mantener consistencia, centralizar la validación de transiciones en una máquina de estados (servicio de dominio) y reutilizarla en REST y sockets.
5. En consultas, aplicar filtros por defecto que excluyan `INACTIVO`, salvo endpoints administrativos de auditoría.
