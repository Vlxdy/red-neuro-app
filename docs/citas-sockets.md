# Sockets de citas médicas

Esta guía complementa la integración de sockets para las **citas médicas** y documenta el payload de cada evento, lo que recibe el servidor y lo que emite a los clientes.

## Conexión

- **Namespace:** `/citas`
- **Transporte recomendado:** `websocket`
- **Autenticación:** enviar el JWT en `auth.token`

### Ejemplo de conexión (Socket.IO)

```ts
import { io } from 'socket.io-client'

const socket = io('https://api.tu-dominio.com/citas', {
  transports: ['websocket'],
  auth: { token: session.accessToken },
})
```

---

## Eventos disponibles

> Los eventos descritos se emiten cuando la acción ocurre por Socket.IO **o** por REST. Así los clientes conectados reciben cambios aunque otra app haya modificado la cita.

### 1) Crear cita

**Cliente → Servidor**

Evento: `citas:create`

| Campo | Tipo | Requerido | Descripción |
| --- | --- | --- | --- |
| `detalle` | string | ✅ | Motivo o detalle de la cita. |
| `fechaInicio` | string (ISO) | ✅ | Fecha/hora de inicio. |
| `idMedico` | string | ✅ | Identificador del médico. |
| `idPaciente` | string | ❌ | Identificador del paciente. |
| `idConsultorio` | string | ❌ | Identificador del consultorio. |
| `idEspecialidad` | string | ✅ | Identificador de la especialidad. |
| `tipoCita` | `CONSULTA` / `ESTUDIO` | ✅ | Tipo de cita. |
| `idEstudio` | string | ❌ | Requerido si `tipoCita` es `ESTUDIO`. |

**Servidor → Todos los clientes**

Evento: `citas:created`

Payload: `CitaResponseDto` (detalle completo de la cita, con relaciones).  
El cliente debe **reemplazar o insertar** la cita en su estado local usando el `id`.

---

### 2) Actualizar cita

**Cliente → Servidor**

Evento: `citas:actualizar`

| Campo | Tipo | Requerido | Descripción |
| --- | --- | --- | --- |
| `id` | string | ✅ | Identificador de la cita a actualizar. |
| `detalle` | string | ✅ | Motivo o detalle de la cita. |
| `fechaInicio` | string (ISO) | ✅ | Fecha/hora de inicio. |
| `idMedico` | string | ✅ | Identificador del médico. |
| `idPaciente` | string | ❌ | Identificador del paciente. |
| `idConsultorio` | string | ❌ | Identificador del consultorio. |
| `idEspecialidad` | string | ✅ | Identificador de la especialidad. |
| `tipoCita` | `CONSULTA` / `ESTUDIO` | ✅ | Tipo de cita. |
| `idEstudio` | string | ❌ | Requerido si `tipoCita` es `ESTUDIO`. |

**Servidor → Todos los clientes**

Evento: `citas:actualizada`

Payload: `CitaResponseDto`.  
El cliente debe **reemplazar** la cita existente por `id`.

---

### 3) Actualizar estado

**Cliente → Servidor**

Evento: `citas:estado`

| Campo | Tipo | Requerido | Descripción |
| --- | --- | --- | --- |
| `id` | string | ✅ | Identificador de la cita. |
| `estado` | string | ✅ | Estado de la cita (ej. `CONFIRMADA`, `EN_CURSO`). |

**Servidor → Todos los clientes**

Evento: `citas:estado-actualizado`

Payload: `CitaResponseDto`.  
El cliente debe **reemplazar** la cita existente por `id`.

---

### 4) Reprogramar cita

**Cliente → Servidor**

Evento: `citas:reprogramar`

| Campo | Tipo | Requerido | Descripción |
| --- | --- | --- | --- |
| `id` | string | ✅ | Identificador de la cita. |
| `fechaInicio` | string (ISO) | ✅ | Nueva fecha/hora de inicio. |
| `tipoCita` | `CONSULTA` / `ESTUDIO` | ✅ | Tipo de cita. |
| `idEstudio` | string | ❌ | Requerido si `tipoCita` es `ESTUDIO`. |

**Servidor → Todos los clientes**

Evento: `citas:reprogramada`

Payload: `CitaResponseDto`.  
El cliente debe **reemplazar** la cita existente por `id`.

---

### 5) Cancelar cita

**Cliente → Servidor**

Evento: `citas:cancelar`

| Campo | Tipo | Requerido | Descripción |
| --- | --- | --- | --- |
| `id` | string | ✅ | Identificador de la cita. |
| `comentario` | string | ❌ | Nota opcional asociada a la cancelación. |

**Servidor → Todos los clientes**

Evento: `citas:cancelada`

Payload: `CitaResponseDto`.  
El cliente debe **reemplazar** la cita existente por `id` y aplicar lógica de UI (ej. ocultar si no se muestran canceladas).

---

## Estructura del payload de respuesta (`CitaResponseDto`)

El backend responde con los datos de la cita y sus relaciones principales. Campos principales:

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `id` | string | Identificador de la cita. |
| `detalle` | string | Motivo o detalle. |
| `fechaInicio` | string (ISO) | Fecha/hora de inicio. |
| `fechaFin` | string (ISO) | Fecha/hora de fin (calculada). |
| `tipoCita` | `CONSULTA` / `ESTUDIO` | Tipo de cita. |
| `estado` | string | Estado actual. |
| `medicoId` | string | Identificador del médico. |
| `pacienteId` | string | Identificador del paciente. |
| `consultorioId` | string | Identificador del consultorio. |
| `especialidadId` | string | Identificador de especialidad. |
| `estudioId` | string | Identificador del estudio (si aplica). |
| `medico` | objeto | Información del profesional asignado. |
| `paciente` | objeto | Información del paciente. |
| `especialidad` | objeto | Información de la especialidad. |
| `estudio` | objeto | Información del estudio (si aplica). |
| `consultorio` | objeto | Información del consultorio. |

> Los campos `medico`, `paciente`, `especialidad`, `estudio` y `consultorio` se envían como objetos enriquecidos cuando existen relaciones disponibles.

## Cómo mantener el estado del cliente sincronizado

1. **Carga inicial**: obtener el listado con `GET /citas` (o `/citas/paginado`) para construir el estado base.
2. **Suscribirse a eventos**: escuchar los eventos del namespace `/citas`.
3. **Aplicar actualizaciones**: usar siempre el `id` para hacer **upsert** del `CitaResponseDto` en la lista local.
4. **Estados filtrados**: si tu UI filtra por estado, re-evalúa la cita recibida y muévela entre listas según su `estado`.
5. **Cancelaciones**: no existe eliminación; una cancelación llega como `citas:cancelada` con la cita en estado `CANCELADA`.

> Con este flujo, el cliente queda completamente actualizado con el backend sin necesidad de realizar polling.

## Nota sobre eliminación

Actualmente no existe un endpoint ni evento para eliminar citas; la acción soportada para retirar una cita del flujo es **cancelarla**, lo que dispara `citas:cancelada`.
