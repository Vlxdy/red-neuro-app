# Módulo Personal de Salud

## Objetivo
Este módulo expone operaciones para gestionar el personal de salud y sus especialidades asociadas. **No existe eliminación física**: el personal médico se administra mediante activación e inactivación (baja lógica).

## Componentes principales
- **DTOs**: Definen la estructura de entrada para crear/actualizar profesionales y recibir IDs de especialidades.
- **Servicio**: Orquesta la creación y actualización de usuarios con rol `PERSONAL_SALUD`, y vincula especialidades.
- **Repositorio**: Consulta el personal de salud con paginación, obtiene detalles, y crea/reemplaza asociaciones de especialidades.

## Endpoints
Base URL: `/personal-salud`

> Todos los endpoints requieren autenticación con `Bearer` token y están protegidos por `JwtAuthGuard` + `CasbinGuard`.

### 1) Listar personal de salud
- **Método**: `GET /personal-salud`
- **Descripción**: Retorna un listado paginado de personal de salud.
- **Query params** (estándar):
  - `limite`: número de registros por página.
  - `saltar`: offset.
  - `filtro`: texto libre para búsqueda por nombre, documento o teléfono.
  - `orden`: campo por el cual ordenar.
  - `sentido`: `ASC` o `DESC`.

**Ejemplo**
```http
GET /personal-salud?limite=10&saltar=0&filtro=ana&orden=nombres&sentido=ASC
Authorization: Bearer <token>
```

### 2) Obtener detalle de un profesional
- **Método**: `GET /personal-salud/:id`
- **Descripción**: Retorna el detalle de un profesional de salud por ID de `usuarioRol`.

**Ejemplo**
```http
GET /personal-salud/123
Authorization: Bearer <token>
```

### 3) Crear profesional de salud
- **Método**: `POST /personal-salud`
- **Descripción**: Crea un nuevo usuario con rol `PERSONAL_SALUD` y opcionalmente asigna especialidades.

**Body (JSON)**
```json
{
  "contrasena": "Ejemplo123",
  "repetirContrasena": "Ejemplo123",
  "correoElectronico": "profesional@clinica.com",
  "persona": {
    "nroDocumento": "4192299",
    "nombres": "MARIELA",
    "primerApellido": "ALCAZAR",
    "segundoApellido": "ALMARAZ",
    "fechaNacimiento": "2002-05-04",
    "telefono": "71234567",
    "genero": "F"
  },
  "esSupervisor": false,
  "idEspecialidades": ["1", "2"]
}
```

**Notas**
- `idEspecialidades` es opcional. Si se omite, el profesional se crea sin especialidades.

### 4) Actualizar profesional de salud
- **Método**: `PATCH /personal-salud/:id`
- **Descripción**: Actualiza datos personales, correo, bandera de supervisor o reemplaza especialidades.

**Body (JSON)**
```json
{
  "correoElectronico": "nuevo@clinica.com",
  "esSupervisor": true,
  "persona": {
    "telefono": "71230000"
  },
  "idEspecialidades": ["2", "3"]
}
```

**Notas**
- Si `idEspecialidades` es enviado, se reemplazan todas las especialidades existentes por las nuevas.
- Si no se envía, las especialidades no cambian.

### 5) Inactivar profesional de salud
- **Método**: `PATCH /personal-salud/:id/inactivacion`
- **Descripción**: Realiza una baja lógica del personal de salud (estado `INACTIVO`).

**Ejemplo**
```http
PATCH /personal-salud/123/inactivacion
Authorization: Bearer <token>
```

### 6) Activar profesional de salud
- **Método**: `PATCH /personal-salud/:id/activacion`
- **Descripción**: Reactiva al personal de salud (estado `ACTIVO`).

**Ejemplo**
```http
PATCH /personal-salud/123/activacion
Authorization: Bearer <token>
```

## Recomendaciones para frontend y app móvil
- **Manejo de IDs**: usar siempre `idEspecialidades` para enviar IDs de especialidad.
- **Sincronización de especialidades**: enviar la lista completa en actualizaciones si se requiere reemplazar.
- **Paginación y búsqueda**: usar `filtro` para mejorar la experiencia del usuario al buscar por nombre/documento/teléfono.
- **Errores comunes**:
  - `PERSONAL_SALUD_NOT_FOUND`: cuando no existe el ID solicitado.
  - `INVALID_SUPERVISOR_FLAG`: si `esSupervisor` se envía sin el rol correcto (ya está asignado internamente).

