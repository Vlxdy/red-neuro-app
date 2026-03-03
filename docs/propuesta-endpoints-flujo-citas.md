# Propuesta de endpoints explícitos para el flujo de citas

Este documento redefine la API con endpoints **explícitos y diferenciados por intención**.

> Criterio: evitar endpoints genéricos ambiguos (por ejemplo, `PATCH /citas/:id/estado`) para mejorar legibilidad, trazabilidad y control de reglas de negocio.

---

## 1) Principio de diseño

- Cada transición importante debe tener un endpoint propio.
- Cada endpoint valida:
  1. estado origen permitido,
  2. rol/actor permitido,
  3. campos permitidos para ese caso.
- Las operaciones inválidas deben fallar con error de negocio claro.

---

## 2) Endpoints a mantener (con ajustes)

## 2.1 `POST /citas`

Crea una cita en `BORRADOR`.

- No envía automáticamente a flujo operativo.
- Registra `idUsuarioProgramo` (idUsuarioRol del creador).

## 2.2 `GET /citas` y `GET /citas/:id`

Consulta de citas con reglas:

- `INACTIVO` no se lista por defecto.
- Deben incluir en respuesta:
  - `idUsuarioProgramo`
  - `idUsuarioEnvio`
  - `idCitaNueva`
  - `idHistorialCita`

---

## 3) Endpoints existentes a reemplazar / deprecados

## 3.1 Deprecar `PATCH /citas/:id/estado`

Motivo: es genérico y permite semántica ambigua.

## 3.2 Deprecar `PATCH /citas/:id` como endpoint multiuso

Motivo: mezcla edición de borrador y cambios operativos.

> Se reemplaza por endpoints explícitos según caso de uso.

---

## 4) Endpoints nuevos explícitos (recomendados)

## 4.1 Edición y ciclo de borrador

### `PATCH /citas/:id/editar-borrador`
- Solo si estado = `BORRADOR`.
- Solo creador o admin.
- Edita campos de borrador.

### `POST /citas/:id/enviar`
- Desde `BORRADOR` o `RECHAZADA`.
- Transiciones:
  - con `idMedico` -> `SOLICITADA`
  - sin `idMedico` -> `CONFIRMADA`
- Registra `idUsuarioEnvio` (idUsuarioRol de quien envía).
- Si pasa a `SOLICITADA`, envía notificación al médico asignado.

### `DELETE /citas/:id`
- Solo si estado = `BORRADOR`.
- No borra físicamente.
- Hace eliminación lógica: `estado = INACTIVO`.

---

## 4.2 Gestión de cita solicitada (por médico asignado/admin)

### `PATCH /citas/:id/ajustar-solicitada`
- Solo si estado = `SOLICITADA`.
- Solo médico asignado o admin.
- Solo permite cambiar `fechaInicio` (hora) y `detalle`.

### `POST /citas/:id/confirmar`
- Solo si estado = `SOLICITADA`.
- Solo médico asignado o admin.
- Transición: `SOLICITADA -> CONFIRMADA`.

### `POST /citas/:id/rechazar`
- Solo si estado = `SOLICITADA`.
- Solo médico asignado o admin.
- Transición: `SOLICITADA -> RECHAZADA`.
- Requiere `motivoRechazo`.

---

## 4.3 Gestión de cita confirmada

### `POST /citas/:id/cancelar`
- Solo si estado = `CONFIRMADA`.
- Transición: `CONFIRMADA -> CANCELADA`.

### `POST /citas/:id/completar`
- Solo si estado = `CONFIRMADA`.
- Transición: `CONFIRMADA -> COMPLETADA`.

### `POST /citas/:id/reprogramar`
- Solo si estado = `CONFIRMADA`, `CANCELADA` o `NO_ASISTIO`.
- Reprogramación por clonación transaccional:
  1. original -> `REPROGRAMADA`
  2. crear nueva cita
  3. original.`idCitaNueva` = nueva.id
  4. ambas comparten `idHistorialCita`

---

## 4.4 Trazabilidad y consultas especializadas

### `GET /citas/:id/cadena-reprogramacion`
- Retorna toda la cadena por `idHistorialCita`.

### `GET /citas/:id/historial`
- Debe incluir eventos de:
  - programación,
  - envío,
  - confirmación/rechazo,
  - cancelación,
  - reprogramación,
  - eliminación lógica (`INACTIVO`).

---

## 5) Contratos sugeridos

## 5.1 Request DTO

- `EnviarCitaDto`:
  - `idMedico?`
  - metadatos mínimos de envío
- `AjustarSolicitadaDto`:
  - `fechaInicio`
  - `detalle`
- `RechazarCitaDto`:
  - `motivoRechazo`
- `ReprogramarCitaDto`:
  - nueva fecha/servicio/datos permitidos

## 5.2 Response DTO

Agregar en respuestas de cita:
- `idCitaNueva`
- `idHistorialCita`
- `idUsuarioProgramo`
- `idUsuarioEnvio`

---

## 6) Matriz de transición soportada por endpoints explícitos

- `BORRADOR` -> `SOLICITADA` (`POST /:id/enviar` con médico)
- `BORRADOR` -> `CONFIRMADA` (`POST /:id/enviar` sin médico)
- `BORRADOR` -> `INACTIVO` (`DELETE /:id` lógico)
- `SOLICITADA` -> `CONFIRMADA` (`POST /:id/confirmar`)
- `SOLICITADA` -> `RECHAZADA` (`POST /:id/rechazar`)
- `RECHAZADA` -> `SOLICITADA|CONFIRMADA` (`POST /:id/enviar`)
- `CONFIRMADA` -> `CANCELADA` (`POST /:id/cancelar`)
- `CONFIRMADA` -> `COMPLETADA` (`POST /:id/completar`)
- `CONFIRMADA|CANCELADA|NO_ASISTIO` -> `REPROGRAMADA` + nueva cita (`POST /:id/reprogramar`)

---

## 7) Beneficio de esta estrategia

- Flujo más entendible para frontend/mobile.
- Menor ambigüedad que con endpoints genéricos.
- Auditoría más clara por intención de negocio.
- Menos riesgo de transiciones inválidas.
