# Informe técnico: estado de endpoints de notificaciones

Fecha: 2026-03-17

## 1) Resumen ejecutivo

Los endpoints de notificaciones **están implementados y expuestos** en API (`/notificaciones` y `/dispositivos-push`), pero encontré **riesgos funcionales importantes** que pueden explicar comportamiento inconsistente en producción.

### Hallazgos críticos

1. **El resumen diario programado puede no ejecutarse nunca con la configuración por defecto.**
   - El cron corre cada 10 minutos (`*/10 * * * *`) pero la hora por defecto es `06:45`.
   - Esa combinación es incompatible (el cron solo dispara en minutos `00,10,20,30,40,50`).

2. **Un administrador puede marcar como vistas notificaciones de todos los usuarios.**
   - Para admin no se filtra por usuario en consultas de `obtenerPendientes` ni `obtenerPorId`.
   - `PATCH /notificaciones/marcar-todas-vistas` para admin termina actualizando todas las notificaciones pendientes globales.

3. **El envío push de resumen ignora el mensaje personalizado por destinatario.**
   - Se construye `destinatarios` con `title/body` específicos, pero al enviar se usa un body fijo único para todos.

## 2) Cobertura funcional actual (sí existe)

- `GET /notificaciones`
- `PATCH /notificaciones/:id/visto`
- `PATCH /notificaciones/marcar-todas-vistas`
- `GET /notificaciones/validar-config-push`
- `GET /notificaciones/resumen-diario`
- `POST /notificaciones/ejecutar-resumen-diario`
- `POST /dispositivos-push`
- `DELETE /dispositivos-push/:token`

Además, los endpoints están protegidos con `JwtAuthGuard` y `CasbinGuard`.

## 3) Detalle de hallazgos

### Hallazgo A — Resumen diario programado no dispara a `06:45` (crítico)

- Implementación actual:
  - Cron: `@Cron('*/10 * * * *')`
  - Hora esperada por env: `NOTIF_DAILY_SUMMARY_HOUR` (default `06:45`)
  - Condición: `if (hora !== dayjs().format('HH:mm')) return`

**Impacto:** el envío automático diario puede quedar inactivo silenciosamente aun con `NOTIF_DAILY_SUMMARY_ENABLED=true`.

**Recomendación:**
- Opción 1: cambiar cron a cada minuto (`* * * * *`) y mantener comparación exacta de `HH:mm`.
- Opción 2: mantener cron cada 10 min y ajustar default a múltiplos de 10 (ej. `06:40` o `06:50`) + validación de config.

### Hallazgo B — Alcance de notificaciones para admin es global (alto)

- En repositorio:
  - `listar`: solo filtra por `idPersonal` si rol = personal de salud.
  - `obtenerPorId`: admin consulta por `{ id }` sin filtro de dueño.
  - `obtenerPendientes`: admin consulta por `{ visto: false }` sin filtro de dueño.

**Impacto:**
- `PATCH /notificaciones/:id/visto` para admin puede afectar cualquier notificación.
- `PATCH /notificaciones/marcar-todas-vistas` para admin marca pendientes de todos, alterando la bandeja global.

**Recomendación:**
- Definir explícitamente la regla de negocio:
  - Si admin debe ver/gestionar solo sus notificaciones, filtrar por `idPersonal = idUsuarioRol`.
  - Si admin operativo necesita vista global, separar endpoint global de administración y evitar mezclar con bandeja personal.

### Hallazgo C — Push de resumen no usa contenido por usuario (medio)

- El método `enviarPushResumenDiario` recibe `destinatarios` con `title/body`, pero al enviar usa:
  - title fijo: `'Resumen diario de citas'`
  - body fijo: `'Tienes un nuevo resumen diario de citas disponible.'`

**Impacto:** se pierde contexto útil para usuario (cantidad real de citas) aunque fue calculado.

**Recomendación:**
- Enviar por lote por plantilla (usuarios con mismo mensaje), o individual por destinatario para preservar `body` dinámico.

## 4) Validaciones sugeridas (operación)

1. Probar `POST /notificaciones/ejecutar-resumen-diario` en staging y verificar:
   - creación de notificaciones por personal/admin,
   - evento socket emitido,
   - push recibido con contenido esperado.

2. Probar `PATCH /notificaciones/marcar-todas-vistas` con usuario admin y confirmar si modifica solo su bandeja o global.

3. Verificar configuración de entorno real:
   - `NOTIF_DAILY_SUMMARY_ENABLED`
   - `NOTIF_DAILY_SUMMARY_HOUR`
   - ruta de `FCM_CREDENTIALS_FILE`.

## 5) Prioridad de corrección sugerida

1. **P1:** Corregir scheduling (Hallazgo A).
2. **P1:** Definir/asegurar aislamiento por usuario para admin en bandeja (Hallazgo B).
3. **P2:** Mejorar payload push para usar mensaje contextual (Hallazgo C).
4. **P3:** Añadir pruebas automatizadas para estos flujos (hoy no encontré specs de notificaciones).
