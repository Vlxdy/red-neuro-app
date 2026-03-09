# Guía de implementación móvil: notificaciones

## Objetivo
Implementar notificaciones con bajo ruido usando resumen diario por cantidad de citas.

## 1. Endpoints a consumir

### Bandeja
- `GET /api/notificaciones`
- `PATCH /api/notificaciones/:id/visto`
- `PATCH /api/notificaciones/marcar-todas-vistas`

### Resumen diario
- `GET /api/notificaciones/resumen-diario`
- `POST /api/notificaciones/ejecutar-resumen-diario` (solo admin)
- `GET /api/notificaciones/validar-config-push` (solo admin, valida JSON Firebase en backend)

### Push token
- `POST /api/dispositivos-push`
- `DELETE /api/dispositivos-push/:token`

### Operación automática
- `POST /api/citas/ejecutar-auto-no-asistio` (solo admin)

## 2. Flujo recomendado en la app

1. Login exitoso.
2. Registrar token push con `POST /api/dispositivos-push`.
3. Cargar bandeja inicial (`GET /api/notificaciones`).
4. Conectar socket de citas para sincronización UI.
5. Mostrar push siempre (aunque app abierta) y deduplicar por `fecha+tipo+usuario`.
6. Al abrir notificación: marcar `visto`.

## 3. UX mínima

- Badge global por no leídas.
- Lista por fecha: hoy / semana / anteriores.
- Acción “Marcar todas como vistas”.
- Vista de resumen diario:
  - Personal: `citasConfirmadasAsignadas`.
  - Admin: `citasConPersonal`, `citasSinPersonal`.

## 4. Comportamiento por rol

### PERSONAL_SALUD
- Ve su bandeja.
- Ve resumen diario de citas confirmadas asignadas.

### ADMINISTRADOR
- Ve bandeja global.
- Ve resumen con y sin asignación.
- Puede disparar procesos manuales de resumen y auto no-asistió.

## 5. Configuración (backend)

- `NOTIF_DAILY_SUMMARY_ENABLED`
- `NOTIF_DAILY_SUMMARY_HOUR`
- `NOTIF_PUSH_ALWAYS`
- `CITAS_AUTO_NO_ASISTIO_ENABLED`
- `CITAS_AUTO_NO_ASISTIO_CRON`

## 6. Casos de prueba móvil sugeridos

1. Registro de token y recepción de push.
2. Bandeja paginada y marcado individual.
3. Marcar todas vistas.
4. Resumen diario correcto por rol.
5. Push visible con app en foreground.
6. Dedupe local para evitar doble visualización.
