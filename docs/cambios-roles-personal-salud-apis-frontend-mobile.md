# Cambios por simplificación de roles: APIs y ajustes en frontend/móvil

## Contexto
Se reemplaza el modelo de roles **SUPERVISOR** y **PERSONAL_MEDICO** por un único rol **PERSONAL_SALUD**, con una bandera `esSupervisor` que habilita las acciones administrativas antes reservadas al supervisor.

## APIs modificadas o con nuevos campos

> Nota: `esSupervisor` ahora se guarda en la columna `es_supervisor` de
> `usuarios_roles` (ya no se usa el JSON de configuración para este dato).

### Autenticación y perfil
- **Respuesta de autenticación** (`AuthResponseDto`) ahora incluye `esSupervisor`.
- **Payload JWT** incorpora `esSupervisor` para el rol activo.
- **Refresh token** retorna `esSupervisor` en la data del usuario.

**Impacto:** el frontend/móvil debe leer `esSupervisor` para habilitar acciones de supervisor sin cambiar de rol.

### Gestión de usuarios
- **Crear usuario** (`POST /usuarios`) admite `esSupervisor?: boolean` cuando el rol asignado es `PERSONAL_SALUD`.
- **Actualizar usuario** (`PATCH /usuarios/:id`) admite `esSupervisor?: boolean` para activar/desactivar permisos administrativos del personal de salud.

**Validación:** si `esSupervisor` se envía pero el usuario no tiene rol `PERSONAL_SALUD`, el backend responde con error de validación.

### Listado de personal de salud
- **Personal médico** (`GET /personal-medico`) ahora retorna `esSupervisor` en cada registro.

**Nota:** el endpoint mantiene el nombre por compatibilidad, pero la data corresponde a **personal de salud**.

## Autorización y permisos

### Casbin
- Se introduce el sujeto **`PERSONAL_SALUD_ADMIN`** para las políticas administrativas.
- El backend valida `PERSONAL_SALUD` + `esSupervisor = true` para habilitar dichas políticas.

### Endpoints con permisos administrativos condicionados
Los siguientes endpoints ahora requieren `PERSONAL_SALUD` con `esSupervisor = true` (además de ADMINISTRADOR):
- `POST /citas`
- `GET /citas`
- `PATCH /citas/:id`
- `PATCH /citas/:id/cancelar`

## Cambios necesarios en Frontend

### Roles y permisos
- Remover referencias a `SUPERVISOR` y `PERSONAL_MEDICO`.
- Usar solo `ADMINISTRADOR` y `PERSONAL_SALUD`.
- Para habilitar funciones de supervisor, validar:
  - `rol === 'PERSONAL_SALUD'` **y** `esSupervisor === true`.

### UI/UX
- Mostrar el estado administrativo del personal de salud (por ejemplo, etiqueta “Admin” o toggle).
- Reutilizar las pantallas de supervisor, pero condicionarlas a `esSupervisor`.

### Navegación
- Las rutas protegidas de supervisor deben validarse con la nueva bandera.

## Cambios necesarios en App Móvil

### Roles y permisos
- Consumir `esSupervisor` desde la autenticación y refresco de sesión.
- Actualizar lógica de permisos para habilitar funciones administrativas solo con la bandera activa.

### UI/UX
- Si el usuario es `PERSONAL_SALUD` sin bandera, ocultar acciones administrativas.
- Si `esSupervisor === true`, habilitar funciones adicionales (p. ej. gestión completa de citas).

## Migración y compatibilidad
- Migrar usuarios con rol `SUPERVISOR` a `PERSONAL_SALUD` y marcar `esSupervisor = true`.
- Ajustar permisos en frontend/móvil para no depender de `SUPERVISOR`.
