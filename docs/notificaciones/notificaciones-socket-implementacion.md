# Implementación simple de socket para notificaciones

Este documento describe una implementación simple usando **un solo canal genérico** para tiempo real: `'/realtime'`.

## 1) Diseño

- Namespace único: `'/realtime'`.
- Gateway backend: `CitasGateway` (maneja eventos de citas y notificaciones).
- Segmentación por eventos:
  - `citas:*`
  - `notificaciones:*`
- Entrega dirigida por room: `usuario-rol:{idUsuarioRol}`.

## 2) Eventos

### Cliente -> Servidor

- `notificaciones:subscribe`
  - payload:
  ```json
  { "idUsuarioRol": "1234" }
  ```

### Servidor -> Cliente

- `notificaciones:nueva`
- `notificaciones:vista`
- `notificaciones:todas-vistas`

## 3) Flujo backend

1. Cliente conecta a `'/realtime'`.
2. Cliente envía `notificaciones:subscribe`.
3. Servidor registra al socket en room `usuario-rol:{id}`.
4. Servicios de negocio emiten eventos solo a esa room.

## 4) Checklist rápido

- [x] Namespace genérico unificado.
- [x] Suscripción por room por usuario.
- [x] Eventos de notificaciones separados por prefijo.
- [x] Emisiones desde flujo de creación y marcado de notificaciones.

## 5) Ejemplo rápido de cliente

```ts
import { io } from 'socket.io-client'

const socket = io('https://api.mi-dominio.com/realtime', {
  transports: ['websocket'],
})

socket.on('connect', () => {
  socket.emit('notificaciones:subscribe', { idUsuarioRol: '1234' })
})

socket.on('notificaciones:nueva', (n) => console.log('nueva', n))
socket.on('notificaciones:vista', ({ id }) => console.log('vista', id))
socket.on('notificaciones:todas-vistas', ({ total }) => console.log(total))
```
