# Guía de migración para aplicación mobile: ocupación y categorías

> Este documento es únicamente para equipos de **aplicación mobile / frontend**.
> No incluye pasos de base de datos ni scripts SQL.

## 1) Resumen funcional de cambios

Se realizaron dos cambios principales en contratos de API:

1. **Personal de salud**
   - Antes: el personal devolvía una colección `ocupaciones: OcupacionPersonalDto[]`.
   - Ahora: el personal devuelve un campo simple `ocupacion?: string`.

2. **Servicios**
   - Antes: la relación era con `ocupaciones`.
   - Ahora: la relación es con `categorias` (N:N), incluyendo `colorHex`.

Además, se añade un **CRUD de categorías** para administración.

---

## 2) Endpoints nuevos y modificados

## 2.1 Categorías (nuevo CRUD)

Base: `/api/categorias`

- `GET /api/categorias`
  - Lista paginada de categorías.
- `GET /api/categorias/:id`
  - Obtiene detalle de una categoría.
- `POST /api/categorias`
  - Crea una categoría.
- `PATCH /api/categorias/:id`
  - Actualiza una categoría.
- `PATCH /api/categorias/:id/cambiar-estado`
  - Activa/Inactiva categoría (soft toggle).

## 2.2 Servicios

- Se mantiene `GET /api/servicios`.
- El endpoint de filtro por relación cambia a:
  - **Nuevo:** `GET /api/servicios/categorias/:id`
  - **Reemplaza a:** `GET /api/servicios/ocupaciones/:id`

## 2.3 Personal de salud

Base: `/api/personal-salud`

- `GET /api/personal-salud`
- `GET /api/personal-salud/:id`
- `POST /api/personal-salud`
- `PATCH /api/personal-salud/:id`

> Las rutas no cambian, pero sí cambia el contrato de `ocupacion` (ver sección DTOs).

---

## 3) DTOs / contratos afectados

## 3.1 Personal de salud

### Request: crear/actualizar personal

- Antes:
```json
{
  "idOcupaciones": ["1", "2"]
}
```

- Ahora:
```json
{
  "ocupacion": "Cardiología"
}
```

### Response: personal

- Antes:
```json
{
  "ocupaciones": [
    { "id": "1", "nombre": "Cardiología", "estado": "ACTIVO" }
  ]
}
```

- Ahora:
```json
{
  "ocupacion": "Cardiología"
}
```

## 3.2 Servicios

### Request: crear/actualizar servicio

- Antes:
```json
{
  "ocupacionIds": ["1", "3"]
}
```

- Ahora:
```json
{
  "categoriaIds": ["1", "3"]
}
```

### Response: servicio

- Antes:
```json
{
  "ocupaciones": [
    { "id": "1", "nombre": "Cardiología" }
  ]
}
```

- Ahora:
```json
{
  "categorias": [
    { "id": "1", "nombre": "Cardiología", "colorHex": "#ef4444" }
  ]
}
```

## 3.3 Categorías (nuevo contrato)

Ejemplo de response:

```json
{
  "id": "1",
  "nombre": "Cardiología",
  "descripcion": "Categoría enfocada en corazón y sistema vascular.",
  "colorHex": "#ef4444",
  "estado": "ACTIVO"
}
```

---

## 4) Impacto en pantallas mobile

## 4.1 Pantallas de personal

Actualizar formularios y modelos locales:
- Reemplazar selector/lista múltiple de ocupaciones por input simple `ocupacion` (texto).
- Actualizar mapeo de respuesta para leer `ocupacion` en lugar de `ocupaciones`.

## 4.2 Pantallas de servicios

- Donde se enviaba `ocupacionIds`, enviar `categoriaIds`.
- Donde se mostraba `ocupaciones`, migrar a `categorias`.
- Si hay chips/etiquetas visuales, usar `categorias[].colorHex` para color de etiqueta.

## 4.3 Pantallas administrativas de catálogo

Agregar módulo de categorías con:
- listado,
- creación,
- edición,
- cambio de estado (activar/inactivar).

---

## 5) Permisos (Casbin) a considerar

Se registraron permisos para categorías en backend y frontend:

- Frontend admin:
  - `/admin/categorias`

- Backend API:
  - `/api/categorias`
  - `/api/categorias/:id`
  - `/api/categorias/:id/cambiar-estado`
  - `/api/servicios/categorias/:id`

Si la app mobile consume catálogo/servicios, verificar que el rol del usuario tenga acceso a esas rutas.

---

## 6) Checklist de migración mobile

1. Reemplazar en modelos/types:
   - `idOcupaciones` → `ocupacion` (personal)
   - `ocupacionIds` → `categoriaIds` (servicios)
   - `ocupaciones[]` → `categorias[]`

2. Cambiar endpoint de filtro:
   - `/api/servicios/ocupaciones/:id` → `/api/servicios/categorias/:id`

3. Incorporar `colorHex` en UI de categorías/servicios.

4. Ajustar validaciones de formularios:
   - `ocupacion` como texto opcional,
   - `categoriaIds` como arreglo de IDs opcional.

5. Probar flujos E2E:
   - listar categorías,
   - crear/editar categoría,
   - desactivar/reactivar categoría,
   - crear/editar servicio con categorías,
   - crear/editar personal con ocupación textual.

---

## 7) Nota de compatibilidad

No se debe asumir compatibilidad con contratos anteriores de `ocupaciones`.
Para evitar errores en runtime, desplegar mobile con estos cambios de contrato sincronizados con backend.
