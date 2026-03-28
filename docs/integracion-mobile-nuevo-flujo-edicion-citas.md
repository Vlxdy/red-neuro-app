# Integración mobile: nuevo flujo de edición de citas (BORRADOR/PROGRAMADA)

## Objetivo

Documentar el **nuevo comportamiento backend** para citas, con foco en:

- Reglas de edición por estado.
- Reglas de permisos por rol.
- Nuevo endpoint de edición para citas programadas.
- Reglas de notificación asociadas a modificaciones.
- Consideraciones para actualizar aplicaciones móviles sin romper flujo actual.

---

## 1) Resumen de cambios funcionales

### 1.1 Edición de citas en BORRADOR

- Solo el **creador** de la cita puede editarla.
- Se mantiene la edición completa de campos en este estado (flujo privado de preparación).
- En **todas las consultas** (listados, detalle, bandejas y filtros), las citas `BORRADOR` solo son visibles para su creador.
- Ningún otro rol/usuario debe ver citas en estado `BORRADOR`.

### 1.2 Edición de citas en PROGRAMADA

- Solo usuarios con rol **JEFE** o **COORDINADOR** pueden editar.
- En este estado se permite modificar:
  - `detalle`
  - `fechaInicio` (solo cuando el cambio es dentro del mismo día)
  - `idConsultorio`
  - `idLugar`
  - `idPersonal`
- En este estado **NO** se permite modificar:
  - `idPaciente`
- Si cambia `idServicio`, `tipoCita` o el día de `fechaInicio`, backend convierte la operación en **reprogramación**.

### 1.2.1 Regla de decisión exacta: ¿modificación o reprogramación?

Para eliminar confusión en mobile, usar esta regla cerrada:

- **MODIFICACIÓN (`PATCH /editar-programada`)**
  - cuando el cambio se mantiene en el **mismo día** y no se intenta tocar `idServicio` ni `tipoCita`.
- **REPROGRAMACIÓN AUTOMÁTICA (disparada desde `PATCH /editar-programada`)**
  - cuando cambia el **día** de `fechaInicio`,
  - o cuando se necesita cambiar `idServicio`,
  - o cuando se necesita cambiar `tipoCita`.

> En resumen: en estado `PROGRAMADA` siempre se usa `/editar-programada`; si cambia día/servicio/tipo, backend convierte la operación en reprogramación.

### 1.3 Estado al asignar personal

La resolución del estado al asignar personal ahora depende del rol activo del personal asignado:

- Si el personal asignado tiene rol `PROFESIONAL_INVITADO` => estado `SOLICITADA`.
- En cualquier otro caso (incluyendo sin personal asignado) => estado `PROGRAMADA`.

> Nota operativa: el estado `SOLICITADA` queda reservado para el flujo con profesional invitado.

### 1.4 Notificaciones por edición de PROGRAMADA

Al editar una cita `PROGRAMADA` se generan notificaciones internas para usuarios relacionados:

- personal anterior (si existía),
- personal actual,
- usuario que programó,
- usuario que envió.

---

## 2) Endpoint nuevo para mobile

## `PATCH /api/citas/:id/editar-programada`

Editar una cita en estado `PROGRAMADA` bajo reglas de rol y campos permitidos.

### 2.1 Permisos

- Permitido: `JEFE`, `COORDINADOR`.
- Denegado: otros roles (incluye `PERSONAL`, `PROFESIONAL_INVITADO`, `ADMINISTRADOR` por política solicitada).

### 2.2 Body permitido

Todos los campos son opcionales.

```json
{
  "detalle": "Control ajustado por cambio de turno",
  "fechaInicio": "2026-04-10T14:00:00Z",
  "idConsultorio": "12",
  "idLugar": "2",
  "idPersonal": "42"
}
```

### 2.3 Body NO permitido para PROGRAMADA

Si el cliente envía alguno de estos campos, el backend responde error:

- `idPaciente`

Cambios de `idServicio`, `tipoCita` o cambio de día en `fechaInicio` se aceptan por
`/editar-programada`, pero backend los tratará como reprogramación.

### 2.4 Respuestas de error esperadas

- `403 Forbidden`
  - `"Solo jefes y coordinadores pueden modificar citas programadas"`
- `400 Bad Request`
  - `"En estado PROGRAMADA no se permite modificar paciente"`
  - `"La cita en estado X no permite edición"`

---

## 3) Endpoint existente (sin cambio de URL) para BORRADOR

## `PATCH /api/citas/:id/editar-borrador`

### Regla importante para mobile

- Si la cita BORRADOR no pertenece al usuario autenticado (no es creador), backend devuelve `403`.
- Recomendación UI: ocultar acciones de edición si `idUsuarioProgramo !== usuarioSesion.id`.

---

## 4) Impacto para apps móviles

## 4.1 Cambios de cliente recomendados

1. Separar acciones de edición:
   - **Editar borrador** => `PATCH /editar-borrador`
   - **Editar programada** => `PATCH /editar-programada`

2. En formularios de cita `PROGRAMADA`:
   - ocultar/bloquear solo `paciente`.
   - permitir cambios en `servicio` y `tipo` (backend los procesa como reprogramación).
   - habilitar `fecha`, `detalle`, `consultorio`, `lugar`, `personal`.

3. En control de permisos:
   - mostrar botón “Editar programada” solo a `JEFE`/`COORDINADOR`.

4. Manejar errores de negocio explícitos:
   - `403` de rol.
   - `400` por campos no permitidos.

5. Actualizar copy/UI:
   - “Estado SOLICITADA solo aplica para profesional invitado”.

## 4.2 Compatibilidad hacia atrás

- El endpoint de borrador se mantiene.
- Se agrega endpoint específico para programada sin romper rutas previas.
- El socket de actualización (`citas:actualizar`) puede mantenerse para refresh visual, pero la edición operativa debe migrar a endpoints HTTP con validación de rol.

---

## 5) Notificaciones y sincronización en mobile

- Al editar una `PROGRAMADA`, backend emite actualización de cita y notificaciones internas a los usuarios relacionados.
- Recomendación mobile:
  - refrescar detalle de cita tras `PATCH` exitoso;
  - actualizar badges/bandeja de notificaciones;
  - mostrar mensaje resumido tipo “La cita fue modificada”.

---

## 5.1 Reprogramación (nuevo contrato de payload)

La reprogramación usa contrato completo de nueva cita
(igual a creación, **excepto paciente**):

- `detalle` (opcional)
- `fechaInicio`
- `idPersonal`
- `idConsultorio` (opcional)
- `idLugar`
- `tipoCita`
- `idServicio`

> `idPaciente` no se recibe porque la reprogramación conserva el paciente de la cita origen.

### 5.1.1 ¿Qué endpoint usar según estado?

- Si la cita está en `PROGRAMADA`:
  - usar **solo** `PATCH /api/citas/:id/editar-programada`.
  - si cambia día/servicio/tipo, backend hace reprogramación automática.
- Si la cita está en `NO_ASISTIO` o `CANCELADA`:
  - usar `PATCH /api/citas/:id/reprogramar`.

### 5.1.2 Alerta recomendada en UI antes de enviar cambios

Cuando el usuario cambie día/servicio/tipo desde una cita programada, mostrar:

> “Este cambio se registrará como **reprogramación**: se creará una nueva cita y la actual quedará en historial como reprogramada.”

Botones sugeridos:

- `Cancelar`
- `Continuar`

---

## 6) Checklist de implementación mobile

- [ ] Agregar acción `editarProgramada`.
- [ ] Restringir UI por rol (`JEFE`, `COORDINADOR`).
- [ ] Ajustar formulario de `PROGRAMADA` (bloquear solo paciente).
- [ ] Mantener edición completa para `BORRADOR` del creador.
- [ ] Mapear errores `400/403` a mensajes de negocio amigables.
- [ ] Probar cambio de `idPersonal` con:
  - [ ] usuario normal (resultado `PROGRAMADA`),
  - [ ] profesional invitado (resultado `SOLICITADA`).

---

## 7) Casos de prueba recomendados (QA mobile + backend)

1. **BORRADOR propio**
   - editar todo => OK.
2. **BORRADOR ajeno**
   - editar => `403`.
3. **PROGRAMADA como JEFE**
   - editar `fechaInicio` dentro del mismo día => modificación OK.
4. **PROGRAMADA como COORDINADOR**
   - reasignar `idPersonal` => OK.
5. **PROGRAMADA intentando cambiar `idPaciente`**
   - => `400`.
6. **PROGRAMADA cambiando a otro día**
   - => usar `/editar-programada` y backend debe convertir a reprogramación.
7. **PROGRAMADA cambiando `idServicio` o `tipoCita`**
   - => usar `/editar-programada` y backend debe convertir a reprogramación.
8. **PROGRAMADA como PERSONAL**
   - => `403`.
9. **Asignación a PROFESIONAL_INVITADO**
   - estado final `SOLICITADA`.
10. **NO_ASISTIO/CANCELADA**
    - reprogramar por `/reprogramar` => OK.

---

## 8) Decisiones de negocio documentadas

- Pacientes son **registros clínico-administrativos**, no usuarios autenticados del sistema.
- Solo **JEFE** y **COORDINADOR** pueden modificar citas `PROGRAMADA`.
- `BORRADOR` es edición privada del creador.
- `SOLICITADA` se reserva para flujo con `PROFESIONAL_INVITADO`.
