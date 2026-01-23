# Propuesta: simplificación de roles y bandera de administrador

## Objetivo
Reducir la complejidad de roles eliminando el rol **SUPERVISOR** y dejando solo dos roles funcionales:

- **ADMINISTRADOR**
- **PERSONAL_SALUD** (reemplaza a PERSONAL_MEDICO)

La capacidad de “supervisor” se habilita mediante una **bandera de administrador** sobre el usuario del personal de salud, sin necesidad de asignar un rol adicional.

## Diseño funcional
1. **Roles únicos**
   - Administrador: acceso completo del sistema (sin cambios).
   - Personal de salud: acceso base de médico.

2. **Bandera de supervisor**
   - Nuevo atributo booleano `esSupervisor` asociado al registro `usuarios_roles` del personal de salud.
   - Este atributo habilita las acciones que hoy están asociadas a `SUPERVISOR`.

3. **Permisos (Casbin)**
   - Mantener las políticas actuales para ADMINISTRADOR.
   - Mover las políticas de `SUPERVISOR` a un sujeto interno `PERSONAL_SALUD_ADMIN`
     y evaluarlo solo cuando `PERSONAL_SALUD` tenga `esSupervisor = true`.
   - En el guard de autorización: si el rol es `PERSONAL_SALUD` y `esSupervisor = true`, permitir las acciones antes limitadas a supervisor.

## Cambios propuestos
### 1) Modelo de datos
- Crear columna `es_supervisor boolean NOT NULL DEFAULT false` en
  `usuarios_roles`.

### 2) Enumeraciones
- Eliminar `SUPERVISOR` del enum de roles.
- Renombrar `PERSONAL_MEDICO` a `PERSONAL_SALUD`.
- Actualizar `RolEnumId` para que solo incluya `ADMINISTRADOR = '1'` y
  `PERSONAL_SALUD = '2'`.
- Mantener `TODOS` como comodín de permisos públicos en Casbin.

### 3) Autenticación / JWT
- Incluir `esSupervisor` en el payload para el rol activo del usuario.
- Este dato se usará en el guard de autorización.

### 4) Autorización
- El guard evalúa:
  - `ADMINISTRADOR` → acceso total.
  - `PERSONAL_SALUD` → acceso base.
  - `PERSONAL_SALUD` con `esSupervisor = true` → acceso de supervisor.

### 5) Endpoints y listados
- Todos los listados de personal médico deben filtrar por `PERSONAL_SALUD`.
- No se requiere añadir “rol supervisor” a un médico.

## Validaciones
- Al crear/actualizar personal de salud:
  - Validar `esSupervisor` como boolean.
  - Si el usuario no es personal de salud, ignorar la bandera.

## Plan de migración sugerido
1. Crear o ajustar la columna/propiedad `esSupervisor`.
2. Migrar usuarios con rol `SUPERVISOR` a `PERSONAL_SALUD` con `esSupervisor = true`.
3. Eliminar el rol `SUPERVISOR` de seeds y catálogo de roles.
4. Actualizar reglas de Casbin usando el sujeto `PERSONAL_SALUD_ADMIN`.
5. Ajustar permisos de frontend/backoffice para personal de salud.

## Beneficios
- Menos roles por usuario.
- Un único rol de salud con privilegios escalables.
- Simplificación del flujo de asignación y mantenimiento de permisos.
