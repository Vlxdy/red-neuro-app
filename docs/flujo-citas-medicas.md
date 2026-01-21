# Propuesta de flujo para citas médicas

## Objetivo

Definir un flujo claro para el ciclo de vida de una cita médica, estableciendo estados, transiciones y visibilidad por rol, además de documentar la implementación del historial de cambios (auditoría) expuesto vía API.

## Estados propuestos y significado

Los estados están alineados con los valores ya definidos en el backend:

- **INACTIVO**: registro no operativo o depurado del flujo (no visible para la operación diaria).
- **SOLICITADA**: cita enviada para revisión/confirmación por el personal.
- **CONFIRMADA**: cita validada y bloqueada; se reserva el slot para el paciente.
- **EN_CURSO**: la atención ya inició.
- **COMPLETADA**: consulta/estudio finalizado.
- **NO_ASISTIO**: el paciente no se presentó.
- **CANCELADA**: anulada por paciente o personal.
- **RECHAZADA**: solicitud descartada por el personal (por incompatibilidad, horarios, etc.).

## Visibilidad sugerida por rol (solo personal interno)

El sistema está dirigido únicamente a personal interno (sin acceso de pacientes). Se propone la siguiente visibilidad:

| Estado     | Personal médico | Supervisor                    | Administrador       |
| ---------- | --------------- | ----------------------------- | ------------------- |
| INACTIVO   | ❌              | ⚠️ (solo auditoría)           | ⚠️ (solo auditoría) |
| SOLICITADA | ✅              | ⚠️ (solo en casos necesarios) | ❌                  |
| CONFIRMADA | ✅              | ⚠️ (solo en casos necesarios) | ❌                  |
| EN_CURSO   | ✅              | ⚠️ (solo en casos necesarios) | ❌                  |
| COMPLETADA | ✅              | ⚠️ (solo en casos necesarios) | ❌                  |
| NO_ASISTIO | ✅              | ⚠️ (solo en casos necesarios) | ❌                  |
| CANCELADA  | ✅              | ⚠️ (solo en casos necesarios) | ❌                  |
| RECHAZADA  | ✅              | ⚠️ (solo en casos necesarios) | ❌                  |

> Nota: El personal médico es el rol operativo principal para crear, editar y cancelar citas. El supervisor solo interviene excepcionalmente. El administrador se limita a configuraciones base y auditoría.

## Flujo propuesto (alto nivel)

1. **Creación (SOLICITADA o CONFIRMADA)**
   - Si la cita **se asigna a un médico**, se crea en **SOLICITADA** y se notifica al médico asignado para su confirmación.
   - Si la cita **no se asigna a un médico**, se crea directamente en **CONFIRMADA**.
2. **Confirmación por médico (CONFIRMADA)**
   - El médico asignado confirma la cita solicitada.
   - Se bloquea el horario.
3. **Atención (EN_CURSO)**
   - Al iniciar la consulta/estudio, se marca en curso.
4. **Cierre (COMPLETADA / NO_ASISTIO)**
   - Completa si se realizó la atención.
   - No asistió si el paciente no se presentó.
5. **Cancelación / Rechazo (CANCELADA / RECHAZADA)**
   - Cancelación por personal médico/supervisor.
   - Rechazo cuando la solicitud no es viable.

## Flujo propuesto de reprogramación

1. **Solicitud de reprogramación**
   - El personal médico solicita nueva fecha/hora.
2. **Validación**
   - Si la cita estaba asignada a un médico, se notifica al médico asignado.
   - Se valida disponibilidad de consultorio y tipo de cita.
3. **Actualización**
   - Se actualizan `fecha_inicio` y `fecha_fin`.
   - Si la cita estaba **RECHAZADA**, vuelve a **SOLICITADA**; en otros casos conserva su estado operativo.
4. **Historial y notificación**
   - Se registra historial de la transición.
   - Se notifica al médico asignado si aplica.

## Historial de la cita (auditoría)

### Qué se registra

Para cada transición de estado o evento relevante, se recomienda guardar:

- **Estado anterior**
- **Rol del ejecutor**
- **Usuario ejecutor**
- **Comentario** (opcional)
- **Fecha de creación**

### Cuándo se registra

- Se genera historial automáticamente al crear, actualizar o cancelar una cita.
- Se registra de forma automática cuando una cita vencida se marca como **NO_ASISTIO** vía proceso diario.
- Recomendación: extender la misma lógica para cambios de estado (confirmar, reprogramar, completar, etc.) para contar con trazabilidad completa.

## Implementación API (historial)

Se expone un endpoint para consultar el historial asociado a una cita:

```
GET /citas/{id}/historial
```

### Respuesta

Devuelve una lista paginada ordenada por fecha de creación (más reciente primero) con:

- `id`
- `citaId`
- `estadoAnterior`
- `rolEjecutor`
- `idEjecutor`
- `comentario`
- `detalleCambios`
- `ejecutor`
- `fechaCreacion`

### Filtros soportados

- `fechaInicio`, `fechaFin` (rango por fecha de creación)
- `estadoAnterior`
- `rolEjecutor`
- `idEjecutor`

## Consideraciones de seguridad

- El historial se protege con autenticación JWT y autorización por roles.
- La visibilidad se filtra por rol interno (médico, supervisor, administrador).

## Automatización diaria (citas vencidas)

Existe un proceso programado que se ejecuta diariamente para revisar citas con fecha anterior al día actual. Si la cita **no cambió de estado** y pertenece a estados operativos (SOLICITADA, CONFIRMADA o EN_CURSO), se marca automáticamente como **NO_ASISTIO**, se genera historial y se crea una notificación asociada.

- **Cron**: `CITAS_REVISION_DIARIA_CRON` (por defecto `0 1 * * *`, 01:00 AM).
- **Criterio de vencimiento**: `fecha_inicio < inicio_del_día_actual` (no afecta citas del mismo día).
- **Notificación**: tipo `CITA_NO_ASISTIO` con mensaje de actualización automática.

## Beneficios

- Auditoría completa de cambios en la cita.
- Mayor transparencia para el personal médico.
- Facilidad para reportes y seguimiento de incidencias.
