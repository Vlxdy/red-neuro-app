# Guía de integración de citas médicas

Este documento resume cómo consumir los nuevos endpoints y eventos de sockets desde **Next.js + MUI** y **Flutter**.

## Endpoints REST

Base URL: `/api`

| Ruta | Método | Descripción |
| --- | --- | --- |
| `/citas` | GET | Listado con filtros (`fechaInicio`, `fechaFin`, `medicoId`, `estado`, `etiquetaId`, `agrupadorId`). |
| `/citas/mis-citas` | GET | Listado filtrado automáticamente por el médico autenticado. |
| `/citas/:id` | GET | Detalle de cita. |
| `/citas` | POST | Crea cita (`detalle`, `fechaInicio`, `fechaFin`, `medicoId`, `agrupadorId?`, `etiquetas?`). Las etiquetas aceptan ids o `{ nombre, colorHex }` y se crean en caliente si no existen. |
| `/citas/:id` | PATCH | Actualiza campos generales. |
| `/citas/:id/estado` | PATCH | Cambia el estado. |
| `/citas/:id/reprogramar` | PATCH | Reprograma fecha y hora. |
| `/citas/:id/cancelar` | PATCH | Cancela la cita. |
| `/citas/:id/etiquetas` | PATCH | Reemplaza el set de etiquetas (crea las nuevas si solo envías `nombre` y `colorHex`). |
| `/citas/:id/agrupador` | PATCH | Define agrupador/ambiente. |
| `/etiquetas` | GET/POST | Listar y crear etiquetas. |
| `/etiquetas/:id` | GET/PATCH/DELETE | Gestionar etiquetas. |
| `/agrupadores` | GET/POST | Listar y crear ambientes/agrupadores (requiere `nombre` y `colorHex`). |
| `/agrupadores/:id` | GET/PATCH/DELETE | Gestionar ambientes/agrupadores. |

> Los endpoints están protegidos con JWT + Casbin, por lo que debes enviar el token en `Authorization: Bearer <token>`.

**Forma de las respuestas**

- Los `datos` de una cita incluyen `etiquetas` como objetos `{ id, nombre, colorHex, estado }` y el campo `agrupadorId` (ambiente) como string.
- Los ambientes devueltos por `/agrupadores` están listos para filtros: `{ id, nombre, descripcion?, colorHex, estado }`.
- Los listados de etiquetas y ambientes pueden usarse directamente para filtros de UI porque no están paginados en esta versión in-memory.

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
- **Emitir** `citas:estado` → `{ id, estado, comentario? }` → broadcast `citas:estado-actualizado`.
- **Emitir** `citas:reprogramar` → `{ id, fechaInicio, fechaFin, comentario? }` → broadcast `citas:reprogramada`.
- **Emitir** `citas:cancelar` → `{ id, comentario? }` → broadcast `citas:cancelada`.

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
  fechaFin: new Date(Date.now() + 3600000).toISOString(),
  medicoId: '42',
  agrupadorId: 'grp-consultorio-1',
  etiquetas: [
    { id: 'tag-urgente' },
    { nombre: 'Pediatría', colorHex: '#1976d2' }, // se crea si no existe
  ],
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

- **MUI**: reutiliza `Table` para listados y `Dialog` para flujos de reprogramación/cancelación. Aprovecha el colorHex de las etiquetas para chips (`<Chip color="primary" sx={{ backgroundColor: etiqueta.colorHex }} />`).
- **Flutter**: usa `Chip` en `Wrap` para etiquetas y `showModalBottomSheet` para acciones rápidas (reprogramar/cancelar).
- Considera suscribirte a `citas:estado-actualizado` y `citas:created` para refrescar listados en tiempo real.

