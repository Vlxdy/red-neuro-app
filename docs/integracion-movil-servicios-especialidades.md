# Integración móvil: especialidades en servicios (flujo recomendado)

Este documento define el flujo recomendado para app móvil usando una sola semántica:

1. **Operación de sincronización total (replace)**: enviar la lista final completa de especialidades.

> Para **agregar o quitar** una especialidad, se usa `PATCH /servicios/{id}` con el arreglo final `especialidadIds`.
>
> Reglas de negocio al guardar:
> - Si `especialidadIds` es `undefined` o `null`, no se modifican relaciones.
> - Si `especialidadIds` es `[]`, se inactivan todas las relaciones existentes del servicio.
> - Si llegan IDs, se sincroniza: se crean nuevas relaciones, se reactivan las inactivas presentes y se inactivan las no enviadas.

## Endpoints a utilizar

### Sincronizar especialidades del servicio (replace)

- **Método**: `PATCH`
- **Ruta**: `/servicios/{id}`
- **Body**:

```json
{
  "especialidadIds": ["1", "3", "5"]
}
```

## ¿Cómo quitar una especialidad desde móvil?

### Ejemplo práctico

- Estado actual en UI/API: `["1", "2", "3"]`
- Quiero quitar `"2"`
- Enviar:

```json
{
  "especialidadIds": ["1", "3"]
}
```

Con eso, backend reemplaza la relación completa y `"2"` queda desasociada.

## ¿Cómo agregar una especialidad desde móvil?

### Ejemplo práctico

- Estado actual en UI/API: `["1", "3"]`
- Quiero agregar `"2"`
- Enviar:

```json
{
  "especialidadIds": ["1", "2", "3"]
}
```

Con eso, backend reemplaza la relación completa y `"2"` queda asociada.

## Flujo recomendado en pantalla móvil

1. Obtener servicio con `GET /servicios/{id}`.
2. Renderizar `especialidades[]` como lista editable (chips, checks, multiselect, etc.).
3. Al guardar cambios:
   - construir la lista final `especialidadIds` según selección actual;
   - enviar `PATCH /servicios/{id}` con esa lista completa.
4. Actualizar estado local con la respuesta del backend.

## Manejo de errores

- `404` si el servicio no existe.
- `404` si algún `especialidadId` enviado no existe.
- `400` si payload no cumple validaciones.

## Notas importantes de persistencia

- Las relaciones servicio-especialidad no se eliminan físicamente.
- El backend cambia el estado de la relación (`ACTIVO`/`INACTIVO`) durante la sincronización.
- En los listados de servicios con especialidades solo se devuelven relaciones activas y especialidades activas.

## Recomendaciones UX

- Evitar múltiples llamadas por cada “quitar”: preferir una sola acción de **Guardar cambios** con `PATCH`.
- Deshabilitar botón Guardar durante la petición.
- Mostrar confirmación de cambios aplicados al completar.
