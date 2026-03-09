# Funcionamiento de notificaciones móviles (versión breve)

## 1) Alcance

- Solo hay usuarios con acceso de **personal de salud** y **administrativo**.
- El paciente se registra en backend, pero **no entra al sistema**.
- No se usa Redis/RabbitMQ en esta etapa.

---

## 2) Regla principal de notificación

Para evitar exceso de notificaciones, se enviará **resumen por cantidad de citas del día** (no detalle por cada cita):

- **Personal de salud**: cantidad de citas confirmadas asignadas a ese personal.
- **Administrador**:
  - cantidad de citas con personal asignado,
  - cantidad de citas sin personal asignado.

Esto se enviará a una hora programada por variables de entorno.

---

## 3) Push y socket

- Se mantiene socket para sincronización de datos en tiempo real.
- Se enviará push **incluso si la app está abierta** para no perder avisos visibles del sistema operativo.
- La app debe deduplicar por `fecha + tipo + usuario` para evitar doble render visual.

---

## 4) Regla opcional NO_ASISTIO (por entorno)

Si está habilitado por variable de entorno:

- Cuando una cita no fue completada dentro de la ventana de control definida,
- se marca automáticamente en estado `NO_ASISTIO`.

Si está deshabilitado, ese cambio queda manual.

---

## 5) Variables de entorno requeridas

- `NOTIF_DAILY_SUMMARY_ENABLED=true|false`
- `NOTIF_DAILY_SUMMARY_HOUR=HH:mm`
- `NOTIF_PUSH_ALWAYS=true|false` (enviar push incluso con app abierta)
- `CITAS_AUTO_NO_ASISTIO_ENABLED=true|false`
- `CITAS_AUTO_NO_ASISTIO_CRON="0 1 * * *"` (ventana/horario de evaluación)

---

## 6) Casbin: módulo y permisos a adicionar

Se debe añadir módulo funcional:

- `notificaciones`

Permisos mínimos:

- `GET /notificaciones`
- `PATCH /notificaciones/:id/visto`
- `PATCH /notificaciones/marcar-todas-vistas`
- `GET /notificaciones/resumen-diario`

Y para gestión de token push:

- `POST /dispositivos-push`
- `DELETE /dispositivos-push/:token`

> Estos permisos deben ser asignables por rol en Casbin para personal de salud y administrador.

---

## 7) Endpoints para implementación

### Bandeja

1. `GET /notificaciones`
   - Lista paginada de bandeja.
2. `PATCH /notificaciones/:id/visto`
   - Marca una notificación como vista.
3. `PATCH /notificaciones/marcar-todas-vistas`
   - Marca todas como vistas.

### Resumen diario

4. `GET /notificaciones/resumen-diario`
   - Devuelve conteo del día según rol:
   - personal: `citasConfirmadasAsignadas`.
   - admin: `citasConPersonal`, `citasSinPersonal`.

### Dispositivos push

5. `POST /dispositivos-push`
   - Registra/actualiza token del dispositivo.
6. `DELETE /dispositivos-push/:token`
   - Inactiva token en logout o baja de dispositivo.

### Operación automática

7. `POST /notificaciones/ejecutar-resumen-diario` (interno/admin)
   - Ejecuta envío manual del resumen del día.
8. `POST /citas/ejecutar-auto-no-asistio` (interno/admin)
   - Ejecuta proceso de cambio automático a `NO_ASISTIO`.

---

## 8) Resultado esperado

- Menos ruido de notificaciones.
- Cada usuario recibe un resumen claro de carga diaria.
- Admin visualiza rápidamente citas con y sin asignación.
- Se evita pérdida de avisos usando push incluso con app abierta.
- Regla de `NO_ASISTIO` queda controlada por configuración.
