# Implementación móvil de notificaciones (actualizado)

Fecha: 2026-03-17

## Objetivo
Definir la integración de notificaciones para la app móvil con los cambios recientes del backend:

- **Se elimina** la consulta de resumen diario por endpoint.
- La **bandeja de notificaciones es personal por usuario autenticado**.

---

## 1) Endpoints vigentes para móvil

Base path asumido: `/api`

### Bandeja
1. `GET /notificaciones`
   - Lista paginada de notificaciones del usuario autenticado.
   - Query params:
     - `pagina` (default `1`)
     - `limite` (default `10`, min `10`, max `50`)
     - `noLeidasRaw=true|false`
     - `tipo=<NotificacionTipo>` (opcional)

2. `PATCH /notificaciones/:id/visto`
   - Marca una notificación como vista.
   - Solo si la notificación pertenece al usuario autenticado.

3. `PATCH /notificaciones/marcar-todas-vistas`
   - Marca todas las no vistas del usuario autenticado.

### Push token
4. `POST /dispositivos-push`
   - Registra/actualiza token push del dispositivo.

5. `DELETE /dispositivos-push/:token`
   - Inactiva token push en logout o baja de dispositivo.

### Operación interna
6. `POST /notificaciones/ejecutar-resumen-diario`
   - Ejecución manual interna/administrativa del proceso de resumen.
   - **No es endpoint de lectura para UI móvil**.

> Endpoint retirado para consulta móvil: `GET /notificaciones/resumen-diario`.

---

## 2) Contratos de datos relevantes

## Notificación (item de lista)

```json
{
  "id": "12345",
  "tipo": "CITA_PROGRAMADA",
  "mensaje": "Resumen diario: tienes 3 citas programadas para hoy.",
  "visto": false,
  "idCita": "987",
  "idPersonal": "456",
  "fechaCreacion": "2026-03-17T10:15:00.000Z"
}
```

Tipos conocidos (`tipo`):
- `CITA_PROXIMAMENTE`
- `CITA_CANCELADA`
- `CITA_PROGRAMADA`
- `CITA_REPROGRAMADA`
- `CITA_NO_ASISTIO`
- `CITA_SOLICITADA`
- `CITA_RECHAZADA`

---

## 3) Flujo recomendado en la app

1. Login exitoso.
2. Registrar token push (`POST /dispositivos-push`).
3. Cargar bandeja inicial (`GET /notificaciones?pagina=1&limite=10`).
4. Conectar socket para eventos de notificaciones/citas.
5. Al abrir detalle o tocar una notificación:
   - llamar `PATCH /notificaciones/:id/visto`
   - actualizar estado local a `visto=true` optimistamente.
6. Acción “Marcar todas como vistas”:
   - llamar `PATCH /notificaciones/marcar-todas-vistas`
   - limpiar badge local.
7. Logout:
   - `DELETE /dispositivos-push/:token`.

---

## 4) Reglas funcionales para UI

- La bandeja que llega desde backend ya está aislada por usuario autenticado.
- No construir pantallas basadas en `GET /notificaciones/resumen-diario` (ya no disponible).
- El resumen diario, si existe como notificación, debe mostrarse como un ítem más de la bandeja.
- Badge recomendado:
  - usar query `noLeidasRaw=true` para conteo por paginación,
  - o mantener conteo local sincronizado con acciones de marcado.

---

## 5) Casos de prueba móviles sugeridos

1. **Bandeja personal**
   - Usuario A no ve notificaciones de Usuario B.

2. **Marcar individual**
   - `PATCH /notificaciones/:id/visto` cambia estado visual y reduce badge.

3. **Marcar todas**
   - `PATCH /notificaciones/marcar-todas-vistas` deja la bandeja sin no leídas.

4. **Filtro no leídas**
   - `GET /notificaciones?noLeidasRaw=true` solo devuelve `visto=false`.

5. **Filtro por tipo**
   - `GET /notificaciones?tipo=CITA_CANCELADA` devuelve solo ese tipo.

6. **Ciclo de token push**
   - Registro al iniciar sesión y desactivación al cerrar sesión.

---

## 6) Checklist de implementación móvil

- [ ] Consumir únicamente endpoints vigentes listados en esta guía.
- [ ] Quitar dependencias de la pantalla/consulta de resumen diario por endpoint.
- [ ] Manejar paginación (`pagina`, `limite`) en bandeja.
- [ ] Implementar marcado individual y masivo como vistas.
- [ ] Integrar registro y baja de token push por sesión.
- [ ] Mantener sincronización UI por socket + actualización local.

