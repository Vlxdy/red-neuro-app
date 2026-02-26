# Flujo actual de citas (modelo con `servicio_cita`)

Este documento describe el **flujo funcional actual** del módulo de citas con el modelo unificado por servicio (`idServicio`).

---

## 1) Conceptos principales

- Una cita se crea con:
  - `tipoCita` (`CONSULTA` o `ESTUDIO`)
  - `idServicio` (obligatorio)
  - `idEspecialidad` (opcional)
- El servicio (`servicio`) define:
  - nombre
  - tipo (`CONSULTA` / `ESTUDIO`)
  - duración
  - costo
  - **0..n especialidades** mediante `servicio_especialidad`

### Reglas clave

1. El `idServicio` es obligatorio en creación y reprogramación.
2. El `servicio.tipo` debe coincidir con `tipoCita`.
3. Si la cita trae `idEspecialidad`, esa especialidad debe estar asociada al servicio (relación muchos-a-muchos).
4. La `fechaFin` siempre se calcula usando `duracionMinutos` del servicio.

---

## 2) Flujo de creación de cita (REST `POST /citas`)

### Entrada esperada

- `detalle` (opcional)
- `fechaInicio` (obligatorio)
- `idMedico` (opcional)
- `idPaciente` (opcional)
- `idConsultorio` (opcional)
- `idEspecialidad` (opcional)
- `tipoCita` (obligatorio)
- `idServicio` (obligatorio)

### Proceso interno

1. Se valida que exista `tipoCita`.
2. Se valida que exista `idServicio`.
3. Se resuelve el servicio por id.
4. Se valida compatibilidad tipo/servicio.
5. Se valida compatibilidad con especialidad (solo si se envía `idEspecialidad`).
6. Se calcula `fechaFin = fechaInicio + duracionServicio`.
7. Se define estado inicial:
   - con `idMedico` -> `SOLICITADA`
   - sin `idMedico` -> `CONFIRMADA`
8. Se guarda cita.
9. Se registra historial de creación.
10. Si quedó `SOLICITADA` y hay médico, se genera notificación.
11. Se retorna la cita completa con relaciones.

---

## 3) Flujo de actualización de cita (REST `PATCH /citas/:id`)

La actualización soporta cambios parciales de:
- datos generales (`detalle`, paciente, consultorio, especialidad, etc.)
- programación (`fechaInicio`, `tipoCita`, `idServicio`)

### Reglas de recalculo

Se recalcula `fechaFin` si cambia alguno de estos campos:
- `fechaInicio`
- `tipoCita`
- `idServicio`
- `idEspecialidad`

Cuando hay recalculo:
1. Se toma `tipoCita` nuevo o actual.
2. Se toma `idServicio` nuevo o actual.
3. Se valida servicio + tipo + especialidad.
4. Se recalcula `fechaFin` por duración del servicio.
5. Se actualizan `fechaInicio`, `fechaFin`, `idServicio`, `tipoCita`.

### Estado al reasignar médico

Si se actualiza `idMedico`, el estado pasa a `SOLICITADA`.

### Auditoría

- Se calculan diferencias (before/after).
- Se guarda historial de actualización con los campos cambiados.

---

## 4) Flujo de actualización de estado (REST `PATCH /citas/:id/estado`)

- Cambia únicamente el estado.
- Si el estado no cambia, la operación se considera exitosa sin modificación efectiva.
- Registra historial con cambio de estado (`before` / `after`).

---

## 5) Flujo de reprogramación (REST `PATCH /citas/:id/reprogramar`)

### Entrada esperada

- `fechaInicio` (obligatorio)
- `tipoCita` (obligatorio)
- `idServicio` (obligatorio en DTO)

### Proceso

1. Se valida `tipoCita`.
2. Se obtiene la cita actual.
3. Se usa `idServicio` recibido (o actual si internamente fuese necesario).
4. Se valida servicio contra tipo y especialidad de la cita.
5. Se recalcula `fechaFin` con duración del servicio.
6. En repositorio:
   - se actualiza fecha inicio/fin
   - si estaba en `RECHAZADA`, pasa a `SOLICITADA`
   - se registra historial de reprogramación

También se registran cambios de `tipoCita` e `idServicio` en el historial de reprogramación.

---

## 6) Flujo de cancelación (REST `PATCH /citas/:id/cancelar`)

- Cambia estado a `CANCELADA`.
- Permite `comentario` opcional.
- Si ya estaba cancelada, responde éxito sin cambios adicionales.
- Registra historial de cambio de estado.

---

## 7) Flujo automático diario: citas vencidas

Existe una tarea programada (cron) que:
1. toma el inicio del día como corte,
2. busca citas anteriores al corte en estados elegibles,
3. las marca como `NO_ASISTIO`,
4. crea historial por cada cita,
5. genera notificación al médico.

---

## 8) Consulta de historial (`GET /citas/:id/historial`)

El historial se devuelve paginado y enriquecido:
- ejecutor (usuario rol)
- médicos involucrados
- pacientes involucrados
- servicios involucrados (`idServicio`)

Cuando en `detalleCambios` aparece un `idServicio`, se adjunta `beforeDetalle` / `afterDetalle` con información del servicio para facilitar visualización.

---

## 9) Formato de respuesta de cita

La respuesta de cita incluye:
- ids: `medicoId`, `pacienteId`, `consultorioId`, `especialidadId`, `servicioId`
- `tipoCita`, `estado`, fechas
- objetos relacionados:
  - `medico`
  - `paciente`
  - `especialidad`
  - `servicio`
  - `consultorio`

`servicio` expone: `id`, `nombre`, `descripcion`, `tipo`, `duracionMinutos`, `costo`, `estado`.

---

## 10) Sockets (gateway)

Eventos de entrada soportados:
- `citas:create`
- `citas:actualizar`
- `citas:estado`
- `citas:reprogramar`
- `citas:cancelar`

Eventos de salida emitidos:
- `citas:created`
- `citas:actualizada`
- `citas:estado-actualizado`
- `citas:reprogramada`
- `citas:cancelada`

En todos los flujos de creación/actualización/reprogramación, el identificador funcional de servicio es `idServicio`.

---

## 11) Notas de integración

- No usar `idEstudio` en contratos actuales de citas.
- Si un frontend separa la UI por tipo, filtrar servicios por `tipo` (`CONSULTA` / `ESTUDIO`).
- Si se envía `idEspecialidad`, validar en UI que esa especialidad esté dentro de `servicio.especialidades[]`.
- Si la especialidad no aplica al flujo, se puede omitir `idEspecialidad` en la cita.
- Para consistencia de agenda, nunca calcular `fechaFin` en cliente; dejar que backend la derive por duración del servicio.
