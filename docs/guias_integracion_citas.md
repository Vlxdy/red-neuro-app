# Guía de integración de citas médicas

Este documento resume cómo consumir los endpoints y eventos de sockets para citas médicas desde **Next.js + MUI** y **Flutter**.

## Endpoints REST

Base URL: `/api`

| Ruta | Método | Descripción |
| --- | --- | --- |
| `/citas` | GET | Listado con filtros (`fechaInicio`, `fechaFin`, `idMedico`, `estado`). |
| `/citas/paginado` | GET | Listado paginado con filtros. |
| `/citas/mis-citas` | GET | Listado filtrado automáticamente por el médico autenticado. |
| `/citas/:id` | GET | Detalle de cita. |
| `/citas` | POST | Crea cita (`detalle`, `fechaInicio`, `idMedico?`, `idPaciente?`, `idConsultorio?`, `idEspecialidad?`, `tipoCita`, `idServicio`). |
| `/citas/:id` | PATCH | Actualiza datos generales. |
| `/citas/:id/estado` | PATCH | Cambia el estado. |
| `/citas/:id/reprogramar` | PATCH | Reprograma fecha y hora. |
| `/citas/:id/cancelar` | PATCH | Cancela la cita. |

> Los endpoints están protegidos con JWT + Casbin, por lo que debes enviar el token en `Authorization: Bearer <token>`.

**Forma de las respuestas**

- Las respuestas devuelven el formato `CitaResponseDto`, que incluye `medico`, `paciente`, `especialidad`, `servicio` y `consultorio` en formato enriquecido.
- La `fechaFin` se calcula automáticamente en base a la duración configurada (consulta) o la duración del servicio asociado.

### Ejemplo en Next.js (fetch)

```ts
const token = session.accessToken
const response = await fetch('/api/citas?estado=CONFIRMADA', {
  headers: {
    Authorization: `Bearer ${token}`,
  },
})
const { datos } = await response.json()
```

### Ejemplo en Flutter (Dio)

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://api.tu-dominio.com/api'))
dio.options.headers['Authorization'] = 'Bearer $token';
final response = await dio.get('/citas', queryParameters: {'estado': 'CONFIRMADA'});
final citas = response.data['datos'];
```

## WebSockets (Socket.IO)

Namespace: `/citas`

Eventos principales:

- **Emitir** `citas:create` → payload `MensajeCitaDto` (mismo shape que `POST /citas`). El servidor responde y además emite `citas:created` a todos los clientes.
- **Emitir** `citas:actualizar` → payload `MensajeActualizarCitaDto` (mismo shape que `PATCH /citas/:id`). El servidor responde y además emite `citas:actualizada`.
- **Emitir** `citas:estado` → `{ id, estado }` → broadcast `citas:estado-actualizado`.
- **Emitir** `citas:reprogramar` → `{ id, fechaInicio, tipoCita, idServicio }` → broadcast `citas:reprogramada`.
- **Emitir** `citas:cancelar` → `{ id, comentario? }` → broadcast `citas:cancelada`.

> Todos estos eventos se emiten tanto cuando la acción se realiza vía **Socket.IO** como cuando se ejecuta mediante **REST**. De esta forma el frontend puede mantenerse sincronizado ante cualquier cambio.

### Next.js + MUI (cliente Socket.IO)

```ts
import { io } from 'socket.io-client'

const socket = io('https://api.tu-dominio.com/citas', {
  auth: { token: session.accessToken },
})

socket.on('connect', () => console.log('conectado'))
socket.on('citas:created', (cita) => console.log('nueva cita', cita))

socket.emit('citas:create', {
  detalle: 'Consulta de control',
  fechaInicio: new Date().toISOString(),
  idMedico: '42',
  idPaciente: '105',
  idConsultorio: '8',
  idEspecialidad: '12',
  tipoCita: 'CONSULTA',
  idServicio: '2',
})
```

### Flutter (socket_io_client)

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io(
  'https://api.tu-dominio.com/citas',
  IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build(),
);

socket.onConnect((_) => print('conectado'));
socket.on('citas:reprogramada', (data) => print('Reprogramada: $data'));

socket.emit('citas:estado', {'id': 'cita-001', 'estado': 'EN_CURSO'});
```

## UI Tips

- **MUI**: reutiliza `Table` para listados y `Dialog` para flujos de reprogramación/cancelación.
- **Flutter**: usa `Chip` en `Wrap` para especialidades y `showModalBottomSheet` para acciones rápidas (reprogramar/cancelar).
- Considera suscribirte a `citas:estado-actualizado` y `citas:created` para refrescar listados en tiempo real.
