# Propuesta de flujo para reservas de citas por pacientes

## Objetivos

- Permitir que los pacientes gestionen sus propias citas dentro de la disponibilidad del nutricionista asignado.
- Mantener el control del nutricionista sobre las citas aprobadas y evitar modificaciones una vez confirmadas.
- Registrar un historial de cambios que permita auditar la evolución de cada cita.

## Roles involucrados

| Rol           | Permisos clave                                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------------------------------- |
| Paciente      | Crear, editar, reprogramar o cancelar citas mientras no estén aprobadas. Consultar historial propio.                |
| Nutricionista | Crear citas confirmadas para pacientes asignados, aprobar, rechazar o comentar solicitudes y gestionar historiales. |
| Administrador | Crear citas confirmadas para cualquier paciente, intervenir en casos especiales y acceder a todos los historiales.  |

## Estados propuestos para una cita

| Estado       | Descripción                                                                                                             | Transiciones permitidas                                                                                                         |
| ------------ | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `BORRADOR`   | Cita creada por el paciente sin enviar para revisión.                                                                   | `BORRADOR` → `SOLICITADA` (paciente envía), `BORRADOR` → `CANCELADA` (paciente cancela).                                        |
| `SOLICITADA` | Cita enviada para revisión del nutricionista.                                                                           | `SOLICITADA` → `CONFIRMADA` (nutricionista), `SOLICITADA` → `RECHAZADA` (nutricionista), `SOLICITADA` → `CANCELADA` (paciente). |
| `CONFIRMADA` | Cita confirmada por el nutricionista o creada directamente por nutricionista/administrador. Inmutable para el paciente. | `CONFIRMADA` → `COMPLETADA` (automático/post consulta), `CONFIRMADA` → `CANCELADA` (nutricionista/paciente vía soporte).        |
| `RECHAZADA`  | Cita rechazada por el nutricionista con comentario obligatorio.                                                         | `RECHAZADA` → `BORRADOR` (paciente reabre y ajusta), `RECHAZADA` → `CANCELADA` (paciente decide no continuar).                  |
| `CANCELADA`  | Cita anulada por el paciente (antes de aprobación) o por el nutricionista.                                              | Estado final; se conserva solo para historial.                                                                                  |
| `COMPLETADA` | Cita realizada.                                                                                                         | Estado final; se conserva solo para historial.                                                                                  |

> Nota: Los estados actuales del dominio deben mapearse o ampliarse con los anteriores. Si ya existe un estado equivalente, reutilizarlo para evitar migraciones innecesarias.

## Flujo de alto nivel

1. **Creación**
   - El paciente consulta disponibilidad y registra una cita en estado `BORRADOR`.
   - Puede ajustar fecha, horario y notas mientras permanezca en `BORRADOR`, sujeto a las políticas de modificación.
   - Nutricionistas y administradores pueden crear citas directamente en `CONFIRMADA` cuando coordinan la agenda por otros canales.
2. **Solicitud de revisión**
   - El paciente envía la cita (`BORRADOR` → `SOLICITADA`).
   - Se notifica al nutricionista.
3. **Revisión del nutricionista**
   - El nutricionista acepta (`SOLICITADA` → `CONFIRMADA`) o rechaza (`SOLICITADA` → `RECHAZADA`).
   - En caso de rechazo, debe registrar un comentario indicando sugerencias u observaciones.
4. **Ajustes posteriores al rechazo**
   - El paciente revisa el comentario y decide:
     - Ajustar y reenviar (`RECHAZADA` → `BORRADOR` → `SOLICITADA`).
     - Cancelar definitivamente (`RECHAZADA` → `CANCELADA`).
5. **Post aprobación**
   - Mientras la cita esté `CONFIRMADA`, el paciente solo puede consultar y cancelar (si las políticas lo permiten). No puede modificar la fecha.
   - Una vez atendida, el sistema la marca como `COMPLETADA`.
   - Los cambios que impliquen mover o cancelar una cita `CONFIRMADA` deben ser gestionados por el nutricionista o soporte administrativo.
6. **Historial**
   - Cada transición se registra con: estado previo, estado nuevo, usuario que realizó el cambio, marca de tiempo y comentario opcional.
   - El historial es visible para el paciente y el nutricionista.

## Requerimientos de backend

### Cambios de dominio

- Ampliar el enumerado de estados o validar que existan los estados propuestos.
- Añadir columnas opcionales si no existen:
  - `comentarioNutricionista` (texto) en la entidad de cita o en la tabla de historial.
  - `lockedAt` (datetime) para indicar cuándo la cita se volvió inmutable (al ser aprobada).
- Tabla de historial (si no existe) con los campos: `citaId`, `estadoAnterior`, `estadoNuevo`, `comentario`, `usuarioId`, `rol`, `createdAt`.

### Políticas de modificación

Para reducir la reprogramación excesiva sin bloquear casos legítimos:

- **Pacientes**
  - Pueden editar libremente mientras la cita esté en `BORRADOR`.
  - Una vez enviada (`SOLICITADA`), los cambios implican volver a `BORRADOR`; limitar a **2 reversiones** por cita dentro de una ventana de **7 días**.
  - Tras un rechazo (`RECHAZADA`), se permiten hasta **2 reprogramaciones adicionales** antes de obligar a cancelar y crear una cita nueva.
  - Solo pueden cancelar hasta **24 horas antes** de la hora agendada cuando la cita esté `CONFIRMADA`; después de ese límite deben contactar al nutricionista.
- **Nutricionistas**
  - Pueden mover o cancelar citas `CONFIRMADA` hasta 2 horas antes de la cita; se recomienda registrar el motivo en historial.
  - No tienen límite de modificaciones mientras la cita permanezca en `SOLICITADA` o `RECHAZADA`.
- **Administradores**
  - Pueden crear y reprogramar citas en cualquier estado cuando medien contingencias, siempre dejando comentario obligatorio.

Cada regla debe validarse en backend (guards y rate-limits) y reflejarse en los mensajes del frontend.

### Endpoints para pacientes

| Acción            | Método y ruta                       | Notas                                                                                            |
| ----------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| Crear cita        | `POST /pacientes/:pacienteId/citas` | Requiere validar disponibilidad. Devuelve estado `BORRADOR` o `SOLICITADA` según el flujo de UX. |
| Editar cita       | `PATCH /citas/:id`                  | Solo permitido para estados `BORRADOR` o `RECHAZADA`. Requiere auditoría.                        |
| Enviar a revisión | `POST /citas/:id/enviar`            | Cambia de `BORRADOR` a `SOLICITADA`. Validar límite de reversiones semanales.                    |
| Cancelar cita     | `POST /citas/:id/cancelar`          | Permitido en `BORRADOR`, `SOLICITADA` y `RECHAZADA`.                                             |
| Ver historial     | `GET /citas/:id/historial`          | Respuesta paginada con eventos ordenados por fecha descendente.                                  |

### Endpoints para nutricionistas

| Acción                  | Método y ruta                                     | Notas                                                                                          |
| ----------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Listar citas pendientes | `GET /nutricionistas/:id/citas?estado=SOLICITADA` | Permite filtrar por rango de fechas.                                                           |
| Aprobar cita            | `POST /citas/:id/aprobar`                         | Cambia a `CONFIRMADA`. Dispara confirmación vía correo y push al paciente.                     |
| Rechazar cita           | `POST /citas/:id/rechazar`                        | Requiere `comentario`. Cambia a `RECHAZADA`, registra motivo y envía notificación al paciente. |
| Ver historial           | `GET /citas/:id/historial`                        | Misma respuesta que para pacientes.                                                            |

### Endpoints para nutricionistas y administradores (creación directa)

| Acción                    | Método y ruta                              | Notas                                                                                                                        |
| ------------------------- | ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| Crear cita confirmada     | `POST /profesionales/:id/citas/confirmada` | Disponible para nutricionistas y administradores. La cita nace en `CONFIRMADA` y dispara notificación inmediata al paciente. |
| Reprogramar cita aprobada | `POST /citas/:id/reprogramar`              | Permite mover fecha/hora manteniendo estado `CONFIRMADA`. Requiere comentario y notifica a las partes.                       |

### Consideraciones de seguridad

- Validar que el paciente solo interactúe con sus propias citas.
- Validar que el nutricionista solo administre citas de pacientes asignados.
- Aplicar guardas de estado en el servicio de dominio para impedir modificaciones fuera de las transiciones permitidas.

## Notificaciones

- Notificar por correo y push (aprovechando la infraestructura existente) en cada transición relevante:
  - Creación de cita `BORRADOR` (resumen al paciente).
  - Envío a revisión (`BORRADOR` → `SOLICITADA`) al nutricionista.
  - Aprobación (`SOLICITADA` → `CONFIRMADA`) al paciente.
  - Rechazo (`SOLICITADA` → `RECHAZADA`) al paciente con el comentario incluido.
  - Reprogramación o cancelación en cualquier estado a todos los involucrados.
  - Creación directa `CONFIRMADA` por nutricionista/administrador al paciente.
- Sincronizar estas notificaciones con el historial para mostrar la misma información en la UI.

## Auditoría e historial

- Cada endpoint que cambie el estado debe registrar un evento en historial.
- Se debe incluir la información del usuario ejecutor y un mensaje (por ejemplo, comentario del nutricionista o motivo de cancelación del paciente).
- El endpoint de historial debe soportar filtros por rango de fechas y paginación para historiales extensos.

## KPIs y métricas sugeridas

- Tiempo promedio desde `SOLICITADA` hasta `CONFIRMADA` o `RECHAZADA`.
- Número de rechazos por paciente para identificar problemas de coordinación.
- Porcentaje de citas que se cancelan después de ser aprobadas.

## Próximos pasos

1. Validar con negocio los estados requeridos y políticas de cancelación.
2. Ajustar entidades y migraciones (si son necesarias).
3. Implementar endpoints con sus guardas y pruebas unitarias.
4. Actualizar la documentación de API y el contrato con frontend.
5. Coordinar implementación en frontend siguiendo las indicaciones descritas en `docs/frontend-citas.md`.
