# Implementación móvil (Android/iOS) - Notificaciones por Socket

Guía práctica para integrar notificaciones en tiempo real en la app móvil usando Socket.IO sobre el namespace `'/realtime'`.

## 1. Requisitos

- Usuario autenticado.
- `idUsuarioRol` disponible en sesión.
- Librería Socket.IO client en la app.

## 2. Conexión recomendada

1. Crear una sola instancia de socket por sesión.
2. Conectar a: `https://<api>/realtime`.
3. Al evento `connect`, emitir:

```json
{ "event": "notificaciones:subscribe", "payload": { "idUsuarioRol": "<id>" } }
```

4. Al reconectar (`reconnect`), volver a suscribirse.

## 3. Eventos a escuchar

### `notificaciones:nueva`

Acción en app:
- Insertar la notificación al inicio de la bandeja local.
- Incrementar contador de no leídas.
- Mostrar badge/toast si la pantalla está activa.

### `notificaciones:vista`

Acción en app:
- Buscar notificación por `id` y marcar `visto=true`.
- Recalcular contador de no leídas.

### `notificaciones:todas-vistas`

Acción en app:
- Marcar todas las notificaciones locales como vistas.
- Reiniciar contador de no leídas.

## 4. Estrategia offline/foreground/background

- **Foreground**: aplicar eventos directo al estado local.
- **Background**: re-sincronizar al volver a foreground (GET bandeja REST).
- **Offline**: al reconectar, re-suscribirse y hacer sincronización inicial por REST.

## 5. Buenas prácticas

- Evitar duplicados por `id` (upsert en vez de append ciego).
- Mantener un `lastSyncAt` para auditoría de sincronización.
- No confiar en datos de cliente para seguridad; backend debe validar identidad.

## 6. Ejemplo (React Native / TypeScript)

```ts
import { io, Socket } from 'socket.io-client'

let socket: Socket | null = null

export const connectRealtime = (idUsuarioRol: string) => {
  if (socket?.connected) return socket

  socket = io('https://api.mi-dominio.com/realtime', {
    transports: ['websocket'],
    reconnection: true,
    reconnectionAttempts: 10,
  })

  const subscribe = () => {
    socket?.emit('notificaciones:subscribe', { idUsuarioRol })
  }

  socket.on('connect', subscribe)
  socket.on('reconnect', subscribe)

  socket.on('notificaciones:nueva', (payload) => {
    // upsert(payload)
  })

  socket.on('notificaciones:vista', ({ id }) => {
    // marcarVista(id)
  })

  socket.on('notificaciones:todas-vistas', ({ total }) => {
    // marcarTodasVistas(total)
  })

  return socket
}

export const disconnectRealtime = () => {
  socket?.disconnect()
  socket = null
}
```

## 7. Pruebas mínimas en móvil

1. Login -> conexión establecida.
2. Suscripción correcta y recepción de `notificaciones:nueva`.
3. Marcar una vista y recibir `notificaciones:vista`.
4. Marcar todas y recibir `notificaciones:todas-vistas`.
5. Cambiar red (wifi/datos) y verificar reconexión + resuscripción.
