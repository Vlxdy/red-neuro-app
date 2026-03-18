# Migración mobile de citas: impacto en consumo de APIs al usar `idUsuario` en lugar de `idUsuarioRol`

Esta guía está orientada al equipo mobile y describe el **impacto en endpoints, DTOs de request, DTOs de response y sockets** del módulo de citas. El objetivo es evitar que la app siga usando `idUsuarioRol` como si fuera la identidad principal del usuario cuando el consumo correcto de estas APIs debe basarse en `idUsuario`.

> Regla práctica para mobile: cuando una API o socket necesite identificar al usuario autenticado, debe usarse `idUsuario` (campo `id` de la sesión autenticada). `idUsuarioRol` sigue existiendo como contexto del rol activo, pero ya no debe tratarse como el identificador principal para consumo de notificaciones, Home de citas, push ni suscripciones en tiempo real.

---

## 1. Qué debe leer mobile de autenticación y refresh

Para esta migración, lo importante no es cambiar cómo inicia sesión la app, sino **qué campos toma de la respuesta para luego consumir las APIs de citas**.

### Campos relevantes del response autenticado

El response autenticado expone al menos estos campos útiles para mobile:

- `id`: identificador del usuario autenticado. **Este es el `idUsuario` que mobile debe usar**.
- `access_token`: token Bearer para las APIs protegidas.
- `idUsuarioRol`: identificador del rol activo.
- `idRol`: id del rol activo.
- `rol`: nombre del rol activo.
- `esSupervisor`: bandera funcional para permisos del personal de salud.
- `roles`: lista de roles disponibles para el usuario, cada uno con su propio `idUsuarioRol`, `idRol`, `rol`, `modulos` y `esSupervisor`.

### Recomendación para mapear la sesión en mobile

En vez de asumir una forma propia del payload, la app debería mapear explícitamente la respuesta autenticada a un estado interno similar a este:

```ts
const session = {
  idUsuario: response.data.id,
  accessToken: response.data.access_token,
  idUsuarioRolActivo: response.data.idUsuarioRol,
  idRolActivo: response.data.idRol,
  rolActivo: response.data.rol,
  esSupervisor: response.data.esSupervisor,
  roles: response.data.roles,
}
```

### Qué significan estos campos para consumo de APIs

- `idUsuario`: identidad base del usuario para sockets, notificaciones, cache y trazabilidad local.
- `idUsuarioRol`: contexto del rol activo. Sirve para UX, cambio de rol o visualización de permisos, pero **no** para reemplazar la identidad del usuario en consumo del módulo de citas.
- `rol` + `esSupervisor`: determinan qué variantes de consulta puede usar mobile, por ejemplo `scope=mine`, `scope=personal` o `scope=all`.

---

## 2. Impacto en requests: qué deja de enviar mobile

En general, mobile debe dejar de hacer cualquiera de estas prácticas:

- enviar `idUsuarioRol` en payloads o metadata auxiliar para “identificar al usuario actual”;
- derivar claves de cache de notificaciones/home/push con `idUsuarioRol`;
- usar `idUsuarioRol` como valor del campo `idUsuario` en sockets;
- asumir que los endpoints “mis-*” necesitan un id del usuario en query o body.

### No cambia

En esta migración **no se agrega** un nuevo campo `idUsuario` a los bodies de las APIs de citas para que mobile lo envíe manualmente.

El cambio correcto es:

- mobile envía el Bearer token;
- backend resuelve al usuario autenticado;
- mobile usa `idUsuario` solo en su estado local y en los casos donde el contrato sí lo pide explícitamente, como la suscripción socket.

---

## 3. Endpoints de notificaciones: impacto en request/response

## 3.1 `GET /notificaciones`

### Request DTO

Usa `FiltroNotificacionDto`, cuyos query params vigentes son:

- `noLeidasRaw?: 'true' | 'false'`
- `tipo?: string`
- además de los params heredados de paginación

### Qué cambia para mobile

- **No** debe enviar `idUsuario` ni `idUsuarioRol` en query.
- La bandeja corresponde al usuario autenticado por token.
- Si la app guarda la bandeja en cache, la clave debe quedar asociada a `idUsuario`, no a `idUsuarioRol`.

### Response DTO

Responde items `NotificacionResponseDto` con campos como:

- `id`
- `tipo`
- `mensaje`
- `visto`
- `idCita?`
- `idPersonal?`
- `fechaCreacion`

### Impacto en parsing

No aparece `idUsuarioRol` en cada item. Si la app antes asumía ownership por rol activo, debe cambiar a ownership por usuario autenticado (`idUsuario`).

## 3.2 `PATCH /notificaciones/:id/visto`

### Request DTO

- no tiene body funcional para identificar al usuario.
- solo recibe `:id` por path.

### Qué cambia para mobile

- no enviar `idUsuarioRol` en body auxiliar ni metadata redundante.
- actualizar el estado local de la notificación dentro del espacio del `idUsuario` autenticado.

## 3.3 `PATCH /notificaciones/marcar-todas-vistas`

### Request DTO

- no tiene body.

### Qué cambia para mobile

- la operación aplica a todas las notificaciones del usuario autenticado;
- si la app mantiene contador por usuario, ese contador debe agruparse por `idUsuario`.

---

## 4. Endpoints de dispositivos push: impacto en request/response

## 4.1 `POST /dispositivos-push`

### Request DTO

Usa `RegistrarDispositivoPushDto`:

```json
{
  "plataforma": "android | ios",
  "token": "<push-token>",
  "versionApp": "<opcional>"
}
```

### Qué cambia para mobile

- el body **no** recibe `idUsuario` ni `idUsuarioRol`;
- el token se registra para el usuario autenticado por Bearer token;
- cualquier asociación local como `push-token-owner` debe quedar ligada a `idUsuario`.

### Response

- retorna un boolean exitoso envuelto en la respuesta base.

## 4.2 `DELETE /dispositivos-push/:token`

### Request DTO

- el identificador relevante es `:token`.
- no hay body.

### Qué cambia para mobile

- al cerrar sesión o revocar token, la app debe limpiar estado del push para el `idUsuario` autenticado;
- cambiar de rol activo no debería generar un nuevo owner local del token si el usuario base es el mismo.

---

## 5. Endpoints “mis citas”: impacto en request/response

Estos endpoints se resuelven sobre el usuario autenticado. Por eso el impacto principal está en **qué NO manda mobile** y en cómo interpreta el resultado.

## 5.1 `GET /citas/mis-resumen`

### Request DTO

Usa `MisResumenCitasDto`, que hereda estos query params opcionales:

- `desde?: string`
- `hasta?: string`
- `idLugar?: string`
- `scope?: 'mine' | 'all' | 'personal'`
- `idPersonal?: string`

### Qué cambia para mobile

- no debe enviar `idUsuarioRol` para pedir “mis” datos;
- el token ya identifica al usuario;
- si el rol lo permite, `scope` e `idPersonal` son los mecanismos válidos para ampliar el alcance.

### Response DTO

`MisResumenResponseDto` contiene:

- `solicitadasPendientesConfirmacion`
- `proximasProgramadas`
- `totalDesdeHoy`
- `primeraFechaConCitas?`

## 5.2 `GET /citas/mis-solicitadas`

### Request DTO

Usa `MisSolicitadasQueryDto`:

- `desde?`
- `hasta?`
- `idLugar?`
- `scope?`
- `idPersonal?`
- `cursor?`
- `limite?`
- `ocultas?: 'true' | 'false'`

### Qué cambia para mobile

- no agregar `idUsuarioRol` a query;
- si se guarda preferencia local de ocultas, esa preferencia debería persistirse por `idUsuario`.

### Response DTO

`MisSolicitadasResponseDto` contiene:

- `items: CitaResponseDto[]`
- `nextCursor?`
- `hasMore`
- `totalAprox`

## 5.3 `GET /citas/mis-timeline`

### Request DTO

Usa `MisTimelineQueryDto`:

- `desde?`
- `hasta?`
- `idLugar?`
- `scope?`
- `idPersonal?`
- `cursorFechaHora?`
- `cursorId?`
- `limite?`
- `incluirSolicitadas?: 'true' | 'false'`

### Qué cambia para mobile

- no usar `idUsuarioRol` para construir el concepto de “mi timeline”;
- si se guarda cache del timeline por usuario, la clave debe ser `idUsuario`.

### Response DTO

`MisTimelineResponseDto` contiene:

- `grupos`
- `nextCursor`
- `hasMore`

## 5.4 `GET /citas/mis-citas` (deprecated)

- Sigue siendo una vista personal.
- Si aún se consume desde mobile, tampoco necesita `idUsuarioRol` en request.

---

## 6. Endpoints Home de citas: impacto en request/response

## 6.1 `GET /citas/home/bandeja`

### Request DTO

Usa `HomeBandejaQueryDto`:

- `scope?: 'mine' | 'all' | 'personal'`
- `idPersonal?: string`
- `idLugar?: string`
- `fechaBase?: string`
- `limitPreview?: number`

### Qué cambia para mobile

- no enviar `idUsuarioRol` para representar al usuario actual;
- para la bandeja propia, basta el token y opcionalmente `scope=mine`;
- para vistas administrativas, usar `scope` + `idPersonal`, no `idUsuarioRol`.

### Response DTO

`HomeBandejaResponseDto` contiene:

- `scopeAplicado`
- `idPersonalAplicado?`
- `fechaBase`
- `contadores`
- `preview`
- `updatedAt`

### Impacto en parsing

- los datos de respuesta ya vienen listos para UI;
- mobile no necesita resolver ownership con `idUsuarioRol`.

## 6.2 `GET /citas/home/pendientes-aprobacion`
## 6.3 `GET /citas/home/rechazadas-solicitadas`
## 6.4 `GET /citas/home/borradores`

### Request DTO

Usan `HomeListadoQueryDto`:

- `scope?`
- `idPersonal?`
- `idLugar?`
- `fechaBase?`
- params de paginación heredados

### Response DTO

Devuelven listados paginados con filas `CitaResponseDto`.

### Qué cambia para mobile

- la segmentación “mis datos / datos de otro personal / todos” se controla con `scope` e `idPersonal`;
- no con `idUsuarioRol`.

## 6.5 `GET /citas/home/programadas-asignadas`

### Request DTO

Usa `HomeProgramadasListadoQueryDto`:

- todo lo anterior, más `dia?: string`

### Response DTO

Devuelve filas agrupadas por día (`HomeGrupoDiaResponseDto`):

- `dia`
- `items: CitaResponseDto[]`

### Qué cambia para mobile

- la agrupación por día no cambia;
- el criterio de usuario autenticado sigue viniendo del token, no del `idUsuarioRol`.

---

## 7. Endpoints operativos de citas: impacto en request/response

Las operaciones de creación/edición/confirmación/rechazo/reprogramación/cancelación **no requieren que mobile envíe `idUsuario` ni `idUsuarioRol` en el body para identificar al ejecutor**.

## 7.1 Request DTOs vigentes

### Crear / editar borrador

- `POST /citas` usa `CrearCitaDto`
- `PATCH /citas/:id/editar-borrador` usa `EditarBorradorCitaDto`

Campos principales del body:

- `accion`
- `detalle?`
- `fechaInicio`
- `idPersonal?`
- `idPaciente?`
- `idConsultorio?`
- `idLugar?`
- `tipoCita`
- `idServicio`

### Enviar

- `PATCH /citas/:id/enviar` usa `EnviarCitaDto`
- campo relevante: `idPersonal?`

### Confirmar

- `PATCH /citas/:id/confirmar` usa `ConfirmarCitaDto`
- campos relevantes: `fechaInicio?`, `detalle?`

### Rechazar

- `PATCH /citas/:id/rechazar` usa `RechazarCitaDto`
- campo relevante: `motivoRechazo?`

### Cancelar / no asistió

- `PATCH /citas/:id/cancelar` usa `CancelarCitaDto`
- `PATCH /citas/:id/no-asistio` usa `MarcarNoAsistioCitaDto`
- campo relevante: `comentario?`

### Reprogramar

- `PATCH /citas/:id/reprogramar` usa `ReprogramarCitaDto`
- campos relevantes: `fechaInicio`, `tipoCita`, `idServicio`

## 7.2 Qué cambia para mobile

- si la app estaba agregando `idUsuarioRol` como metadata extra del ejecutor, debe dejar de hacerlo;
- el ejecutor se determina con el token;
- `idPersonal` en los DTOs de cita **no representa al usuario autenticado**, sino al personal asignado/filtrado de la cita.

## 7.3 Impacto en response DTO

`CitaResponseDto` contiene campos relevantes para mobile como:

- `id`, `detalle`, `fechaInicio`, `fechaFin`, `tipoCita`, `estado`
- `usuarioProgramoId`, `usuarioProgramo`
- `usuarioEnvioId`, `usuarioEnvio`
- `idPersonal`, `personal`
- `pacienteId`, `paciente`
- `consultorioId`, `consultorio`
- `lugarId`, `lugar`
- `servicioId`, `servicio`

### Qué observar en parsing

- `usuarioProgramoId` y `usuarioEnvioId` son ids de usuario expuestos en la respuesta;
- mobile no debería reinterpretarlos como `idUsuarioRol`.

---

## 8. Historial y DTOs relacionados

## 8.1 Historial de citas

En respuestas de historial, `HistorialCitaResponseDto` contiene:

- `id`
- `citaId`
- `historialCitaId?`
- `idEjecutor`
- `comentario?`
- `detalleCambios?`
- `ejecutor?`
- `fechaCreacion`

### Impacto para mobile

- `idEjecutor` debe tratarse como identificador del usuario ejecutor expuesto por la API;
- no asumir que representa `idUsuarioRol`.

---

## 9. Socket y tiempo real: contrato que sí usa `idUsuario`

Aquí sí existe un contrato explícito en el payload y por eso este punto es crítico para mobile.

## 9.1 Namespace

- `'/realtime'`

## 9.2 Evento de entrada

### `notificaciones:subscribe`

Payload correcto:

```json
{ "idUsuario": "<idUsuario>" }
```

### Qué debe cambiar mobile

Si hoy la app hace esto:

```json
{ "idUsuario": "<idUsuarioRol>" }
```

está suscribiéndose con el identificador incorrecto.

## 9.3 Eventos de salida relevantes

- `notificaciones:nueva`
- `notificaciones:vista`
- `notificaciones:todas-vistas`
- `citas:created`
- `citas:actualizada`
- `citas:estado-actualizado`
- `citas:reprogramada`
- `citas:cancelada`
- `citas:home-actualizada`

## 9.4 Evento `citas:home-actualizada`

Payload conceptual:

```json
{
  "id": "<idCita>",
  "estado": "PROGRAMADA",
  "fechaInicio": "2026-03-18T10:00:00.000Z",
  "idPersonal": "<idPersonalAsignado>",
  "idUsuarioProgramo": "<idUsuarioQueProgramo>",
  "timestamp": "2026-03-18T10:05:00.000Z"
}
```

### Impacto para mobile

- `idUsuarioProgramo` debe tratarse como id de usuario expuesto por el backend;
- no usar `idUsuarioRol` para comparar ownership del evento.

---

## 10. Cambios concretos recomendados en la app móvil

## 10.1 Estado de sesión

Cambiar cualquier patrón similar a:

- `currentUserId = auth.idUsuarioRol`
- `socketUserId = session.idUsuarioRol`
- `notificationsOwner = activeRole.idUsuarioRol`

Por:

- `currentUserId = session.idUsuario`
- `socketUserId = session.idUsuario`
- `notificationsOwner = session.idUsuario`

## 10.2 Cache y almacenamiento local

Migrar o invalidar claves como:

- `notifications:${idUsuarioRol}` → `notifications:${idUsuario}`
- `home-citas:${idUsuarioRol}` → `home-citas:${idUsuario}`
- `push-token-owner:${idUsuarioRol}` → `push-token-owner:${idUsuario}`

## 10.3 Parsing de responses

Revisar mappers donde la app:

- compare `usuarioProgramoId`, `usuarioEnvioId` o `idEjecutor` contra el usuario actual;
- use `idUsuarioRol` como identidad local;
- derive ownership de notificaciones o citas con el rol activo en vez del usuario.

---

## 11. Checklist de migración para mobile

### Obligatorio

- [ ] Guardar `response.data.id` como `idUsuario` en sesión.
- [ ] Mantener `idUsuarioRol` solo como dato del rol activo.
- [ ] Dejar de usar `idUsuarioRol` en `notificaciones:subscribe`.
- [ ] No enviar `idUsuarioRol` en query/body auxiliar de endpoints personales.
- [ ] Revisar caches y storage local del módulo de citas/notificaciones/push.
- [ ] Validar mappers de `CitaResponseDto`, `NotificacionResponseDto` y `HistorialCitaResponseDto`.

### Recomendado

- [ ] Re-sincronizar Home y notificaciones al abrir sesión con la nueva versión.
- [ ] Mantener separados en dominio mobile: `idUsuario` (identidad) y `idUsuarioRol` (contexto de rol).
- [ ] Revisar analytics/logs para no registrar `idUsuarioRol` como id primario del usuario.

---

## 12. Plan de pruebas sugerido

1. **Autenticación**
   - Verificar que la app tome `response.data.id` como `idUsuario`.
   - Verificar que `idUsuarioRol` quede solo como contexto del rol activo.

2. **Notificaciones REST**
   - Consumir `GET /notificaciones`.
   - Marcar una notificación con `PATCH /notificaciones/:id/visto`.
   - Marcar todas con `PATCH /notificaciones/marcar-todas-vistas`.

3. **Push**
   - Registrar token con `POST /dispositivos-push`.
   - Eliminar token con `DELETE /dispositivos-push/:token`.
   - Verificar asociación local por `idUsuario`.

4. **Home de citas**
   - Consumir `GET /citas/home/bandeja` y los listados derivados.
   - Validar que `scope` e `idPersonal` sigan funcionando sin usar `idUsuarioRol`.

5. **Mis citas**
   - Consumir `GET /citas/mis-resumen`, `GET /citas/mis-solicitadas` y `GET /citas/mis-timeline`.
   - Confirmar que no hace falta enviar id de usuario en query.

6. **Socket**
   - Conectar a `'/realtime'`.
   - Suscribirse con `{ idUsuario }`.
   - Verificar recepción de `notificaciones:nueva` y `citas:home-actualizada`.

7. **Cambio de rol activo**
   - Si la app soporta cambio de rol, verificar que al cambiar `idUsuarioRol` no se dupliquen caches ni se pierda la suscripción socket del mismo usuario.
