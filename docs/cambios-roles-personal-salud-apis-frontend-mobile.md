# Cambios por redefinición de roles: guía para frontend web y aplicación móvil

## 1. Resumen ejecutivo

Se elimina el esquema anterior basado en:

- rol `PERSONAL_SALUD`
- bandera `esSupervisor`
- sujeto virtual `PERSONAL_SALUD_ADMIN`

Y se reemplaza por roles explícitos:

- `ADMINISTRADOR`
- `JEFE`
- `COORDINADOR`
- `PERSONAL`
- `PROFESIONAL_INVITADO`

## 2. Impacto principal para la app móvil

La app móvil ya **no debe** depender de `esSupervisor` para habilitar vistas o acciones.

### Antes

- La app interpretaba permisos con algo como:
  - `rol === 'PERSONAL_SALUD'`
  - `esSupervisor === true`

### Ahora

La app debe resolver capacidades por rol explícito:

- `ADMINISTRADOR`: administración global del sistema.
- `JEFE`: operación global, incluyendo gestión de personal.
- `COORDINADOR`: operación de citas/pacientes y consulta de personal.
- `PERSONAL`: trabajo sobre sus asignaciones propias.
- `PROFESIONAL_INVITADO`: trabajo sobre sus propias citas y únicamente pacientes que le fueron asignados.

## 3. Cambios de contrato que mobile debe asumir

### 3.1 Autenticación y refresh

Las respuestas autenticadas mantienen el rol activo, pero dejan de exponer `esSupervisor`.

#### Qué debe leer mobile de la sesión

- `id`
- `idRol`
- `idUsuarioRol`
- `rol`
- `roles`

#### Qué deja de existir

- `esSupervisor`

### 3.2 Gestión de usuarios

Los endpoints de usuarios ya no aceptan ni devuelven `esSupervisor`.

Esto afecta especialmente payloads de:

- creación de usuario
- actualización de usuario/roles
- refresco de sesión
- almacenamiento local de perfil/autenticación

### 3.3 Creación de personal

Cuando se crea personal desde el flujo de personal ahora debe enviarse explícitamente el
campo `rol`.

#### Reglas nuevas

- `ADMINISTRADOR` puede crear: `ADMINISTRADOR`, `JEFE`, `COORDINADOR`, `PERSONAL`, `PROFESIONAL_INVITADO`
- `JEFE` puede crear: `COORDINADOR`, `PERSONAL`, `PROFESIONAL_INVITADO`
- `JEFE` **no puede** crear: `JEFE`, `ADMINISTRADOR`

#### Impacto para frontend/mobile

- la pantalla de creación debe incluir selector de rol
- el selector debe filtrar opciones según el rol autenticado
- si el usuario autenticado es `JEFE`, no deben mostrarse `JEFE` ni `ADMINISTRADOR`
- el selector debe contemplar la opción `PROFESIONAL_INVITADO` cuando el backend permita crear ese perfil

## 4. Nueva lectura funcional de permisos en mobile

## 4.1 Rol `ADMINISTRADOR`

Puede acceder a configuración, usuarios, roles, catálogos y también intervenir sobre operación completa.

## 4.2 Rol `JEFE`

Puede operar de forma global:

- citas
- pacientes
- personal
- lugares operativos

## 4.3 Rol `COORDINADOR`

Puede operar:

- citas
- pacientes
- consulta de personal

Pero no debe ver funciones de:

- configuración
- usuarios
- roles
- administración estructural de personal

## 4.4 Rol `PERSONAL`

Debe quedar restringido a:

- sus citas
- sus pacientes
- sus notificaciones
- su perfil

## 4.5 Rol `PROFESIONAL_INVITADO`

Debe quedar restringido a:

- sus citas
- pacientes asignados específicamente al profesional invitado
- sus notificaciones
- su perfil

Notas operativas para frontend/mobile:

- puede ver el módulo/bandeja de pacientes, pero el backend solo devolverá pacientes relacionados en `pacientes_profesionales_invitados`
- si intenta abrir un paciente no asignado, el backend responderá como no encontrado
- no debe tener accesos de gestión de personal, configuración ni catálogos administrativos

## 5. Reglas de `scope` que mobile debe usar

El backend sigue usando alcance de consulta en citas mediante `scope`, pero ahora la habilitación depende del rol explícito.

Los valores vigentes son:

- `mine`
- `personal`
- `all`

### Comportamiento esperado por rol

#### `PERSONAL`

- usar `scope=mine`
- no mostrar selector de alcance global
- no enviar `scope=all`

#### `PROFESIONAL_INVITADO`

- usar `scope=mine`
- no mostrar selector de alcance global
- no enviar `scope=all`
- al consultar pacientes, asumir que la lista ya viene filtrada por asignación

#### `COORDINADOR`

- puede usar `scope=mine`
- puede usar `scope=personal`
- puede usar `scope=all` según la vista operativa permitida

#### `JEFE`

- puede usar `scope=mine`
- puede usar `scope=personal`
- puede usar `scope=all`

#### `ADMINISTRADOR`

- puede usar todos los scopes

## 6. Cambios concretos que debe hacer mobile

### 6.1 Modelo de sesión

Actualizar el modelo local y eliminar:

- `esSupervisor`

Agregar/usar correctamente:

- `rol`
- `idRol`
- `roles`

### 6.2 Guards / navegación

Reemplazar cualquier lógica del tipo:

```ts
if (user.rol === 'PERSONAL_SALUD' && user.esSupervisor) {
  // mostrar acciones administrativas
}
```

Por lógica explícita de roles:

```ts
const puedeAdministrarPersonal =
  user.rol === 'ADMINISTRADOR' || user.rol === 'JEFE'

const puedeCoordinarOperacion =
  user.rol === 'ADMINISTRADOR' ||
  user.rol === 'JEFE' ||
  user.rol === 'COORDINADOR'
```

### 6.3 UI

Ocultar o mostrar acciones según rol:

- gestión de usuarios: solo `ADMINISTRADOR`
- gestión de personal: `ADMINISTRADOR` y `JEFE`
- bandejas globales: `ADMINISTRADOR`, `JEFE`, `COORDINADOR`
- bandeja propia: todos
- gestión/listado de pacientes asignados: `PERSONAL` y `PROFESIONAL_INVITADO` con alcance propio; `PROFESIONAL_INVITADO` no debe mostrar acciones globales

## 7. Cambios concretos que debe hacer frontend web

Frontend web debe aplicar exactamente la misma regla que mobile:

- eliminar dependencia de `esSupervisor`
- usar roles explícitos
- ajustar menús por rol
- ajustar acciones por rol

## 8. Checklist de migración para móvil

- [ ] Eliminar `esSupervisor` del modelo de sesión.
- [ ] Eliminar `esSupervisor` del almacenamiento local/caché.
- [ ] Reemplazar validaciones `PERSONAL_SALUD + esSupervisor` por roles explícitos.
- [ ] Actualizar guards de navegación.
- [ ] Actualizar visibilidad de botones y acciones por rol.
- [ ] Validar consumo de endpoints de citas con `scope` según rol.
- [ ] Verificar que `PERSONAL` no intente usar vistas globales.
- [ ] Verificar que `PROFESIONAL_INVITADO` solo vea pacientes asignados.
- [ ] Verificar que `COORDINADOR` no intente administrar personal.
- [ ] Verificar que `PROFESIONAL_INVITADO` no vea menús de configuración/personal.
- [ ] Verificar que `JEFE` sí pueda operar vistas globales y personal.
- [ ] Agregar selector de rol en creación de personal.
- [ ] Restringir opciones del selector según el rol autenticado.
- [ ] Verificar compatibilidad de login y refresh sin `esSupervisor`.

## 9. Riesgos de compatibilidad si mobile no migra

Si la app móvil no aplica estos cambios puede ocurrir:

- ocultamiento incorrecto de acciones por seguir esperando `esSupervisor`
- error al deserializar sesión si el cliente espera ese campo
- menús mal habilitados
- uso incorrecto de `scope`
- navegación a vistas no permitidas para el nuevo rol real

## 10. Recomendación de despliegue

Desplegar backend y app móvil/web de forma coordinada.

Orden recomendado:

1. publicar backend con roles nuevos
2. publicar web/mobile con nueva lectura de roles
3. verificar login, refresh, home de citas, pantallas de personal y listado/detalle de pacientes asignados para `PROFESIONAL_INVITADO`
4. retirar cualquier lógica legacy basada en `PERSONAL_SALUD` y `esSupervisor`
