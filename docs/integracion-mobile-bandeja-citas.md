# Integración móvil: bandeja de citas (resumen + solicitadas + timeline)

Esta guía explica cómo consumir los nuevos endpoints de citas para implementar la pantalla **Mis citas** en la app móvil.

## Objetivo funcional

1. Mostrar un **resumen** rápido desde hoy.
2. Mostrar citas **SOLICITADA** en un bloque superior colapsable.
3. Mostrar el resto en un **timeline agrupado por fecha** con scroll infinito.
4. Permitir que **admin** consulte sus citas o las de cualquier personal (`scope`).

---

## Endpoints

## 1) Resumen

`GET /citas/mis-resumen`

### Query params

- `desde` (ISO, opcional; default inicio del día)
- `hasta` (ISO, opcional)
- `idLugar` (opcional)
- `scope` (`mine|all`, opcional)
- `idPersonal` (opcional, útil cuando `scope=all`)

### Response

```json
{
  "finalizado": true,
  "mensaje": "Operación realizada con éxito",
  "datos": {
    "solicitadasPendientesConfirmacion": 12,
    "proximasConfirmadas": 7,
    "totalDesdeHoy": 19,
    "primeraFechaConCitas": "2026-03-13"
  }
}
```

---

## 2) Solicitadas (bloque superior)

`GET /citas/mis-solicitadas`

### Query params

- `desde` / `hasta` (opcionales)
- `idLugar` (opcional)
- `scope` (`mine|all`, opcional)
- `idPersonal` (opcional)
- `cursor` (formato: `fechaISO|id`)
- `limite` (default 20)
- `ocultas` (`true|false`, opcional)

### Response

```json
{
  "finalizado": true,
  "mensaje": "Listado exitoso",
  "datos": {
    "items": [],
    "nextCursor": "2026-03-18T10:30:00.000Z|12345",
    "hasMore": true,
    "totalAprox": 120
  }
}
```

---

## 3) Timeline por fecha

`GET /citas/mis-timeline`

### Query params

- `desde` / `hasta` (opcionales)
- `idLugar` (opcional)
- `scope` (`mine|all`, opcional)
- `idPersonal` (opcional)
- `cursorFechaHora` (ISO opcional)
- `cursorId` (opcional)
- `limite` (default 30)
- `incluirSolicitadas` (`true|false`, opcional)

### Response

```json
{
  "finalizado": true,
  "mensaje": "Listado exitoso",
  "datos": {
    "grupos": [
      { "fecha": "2026-03-13", "items": [] },
      { "fecha": "2026-03-14", "items": [] }
    ],
    "nextCursor": {
      "cursorFechaHora": "2026-03-14T16:00:00.000Z",
      "cursorId": "98765"
    },
    "hasMore": true
  }
}
```

---

## Reglas de alcance (scope)

- Usuario estándar: siempre se resuelve como `scope=mine`.
- Admin:
  - `scope=mine`: solo sus citas.
  - `scope=all` sin `idPersonal`: vista global.
  - `scope=all` con `idPersonal`: vista de un personal específico.

---

## Flujo recomendado en app móvil

1. Al abrir pantalla:
   - llamar `mis-resumen`;
   - llamar primera página de `mis-solicitadas`;
   - llamar primera página de `mis-timeline`.
2. Si el usuario colapsa solicitadas:
   - ocultar bloque visualmente (sin romper su estado de paginación).
3. En scroll inferior:
   - usar `nextCursor` de timeline para pedir siguiente bloque.
4. En solicitadas “Ver más”:
   - usar `nextCursor` de solicitadas.
5. Al cambiar filtros (scope, personal, lugar, rango):
   - resetear cursores y recargar desde primera página.

---

## Recomendaciones de implementación frontend

- Persistir preferencia de UI: `solicitadasCollapsed` (local storage/secure storage).
- Separar estados por sección:
  - `resumenState`
  - `solicitadasState` (items, nextCursor, hasMore)
  - `timelineState` (grupos, nextCursor, hasMore)
- Debounce para cambios rápidos de filtros (200–300ms).
- Reintento simple en errores de red (máximo 1 retry).

---

## Ejemplos rápidos

### Mis citas (usuario estándar)

```http
GET /citas/mis-resumen
GET /citas/mis-solicitadas?limite=20
GET /citas/mis-timeline?limite=30
```

### Vista admin global filtrada por lugar

```http
GET /citas/mis-resumen?scope=all&idLugar=2
GET /citas/mis-solicitadas?scope=all&idLugar=2&limite=20
GET /citas/mis-timeline?scope=all&idLugar=2&limite=30
```

### Vista admin de un personal específico

```http
GET /citas/mis-resumen?scope=all&idPersonal=42
GET /citas/mis-solicitadas?scope=all&idPersonal=42
GET /citas/mis-timeline?scope=all&idPersonal=42
```
