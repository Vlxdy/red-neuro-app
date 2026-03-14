# Propuesta revisada: bandeja de citas con resumen + paginado por fecha

## Contexto del ajuste

Se descarta `GET /citas/paginado` como base de la solución porque ya no se está usando en producto.
La propuesta debe centrarse en:

1. **Resumen operativo** (totales útiles para la cabecera y tabs).
2. **Listado paginado por fecha** (no por "número de página" tradicional).
3. **Priorizar citas solicitadas arriba**, con opción de ocultarlas.
4. Soportar escenarios donde hay demasiadas solicitadas (también paginadas).

## Recomendación de UX móvil

Pantalla única "Mis citas" con 3 bloques:

1. **Resumen superior (cards/chips)**
   - `solicitadasPendientesConfirmacion`
   - `proximasConfirmadas`
   - `totalDesdeHoy`

2. **Bloque destacado: "Solicitadas" (colapsable)**
   - Se muestra arriba por prioridad operativa.
   - Tiene botón "Ocultar / Mostrar".
   - Si son muchas, se pagina con cursor propio.

3. **Timeline por fecha (desde hoy en adelante)**
   - Lista agrupada por día (`2026-03-13`, `2026-03-14`, etc.).
   - Scroll infinito por cursor de fecha/hora, no por page/limit clásico.

---

## APIs propuestas (reemplazo de la lógica anterior)

> Regla transversal de alcance:
>
> - **Personal estándar**: solo puede consultar "mis citas".
> - **Administrador**: puede consultar "mis citas" o "citas de cualquier personal" usando filtros explícitos.

## 1) `GET /citas/mis-resumen`

Entrega solo métricas para pintar rápidamente la parte superior.

### Query params

- `desde` (ISO opcional, default: inicio del día actual)
- `hasta` (ISO opcional)
- `idLugar` (opcional)
- `scope` (opcional: `mine` | `all`, default `mine`)
- `idPersonal` (opcional; requerido cuando `scope=all` y se quiere un personal puntual)

### Comportamiento por rol

- Si el usuario **no es admin**, forzar `scope=mine` ignorando cualquier valor enviado.
- Si el usuario **es admin**:
  - `scope=mine`: resumen solo de sus citas.
  - `scope=all` sin `idPersonal`: resumen global (todos los personales visibles por política).
  - `scope=all` con `idPersonal`: resumen de un personal específico.

### Response sugerida

```json
{
  "solicitadasPendientesConfirmacion": 12,
  "proximasConfirmadas": 7,
  "totalDesdeHoy": 19,
  "primeraFechaConCitas": "2026-03-13"
}
```

---

## 2) `GET /citas/mis-solicitadas`

Lista solamente citas en estado `SOLICITADA` para el usuario autenticado.

### Query params

- `cursor` (opcional; apunta al último item de la página anterior)
- `limit` (default 20)
- `idLugar` (opcional)
- `ocultas` (opcional, default `false`; para recuperar lo oculto por el usuario si se requiere)
- `scope` (opcional: `mine` | `all`, default `mine`)
- `idPersonal` (opcional; filtro de personal cuando `scope=all`)

### Orden

- `fechaInicio ASC`
- desempate por `id ASC`

### Response sugerida

```json
{
  "items": [],
  "nextCursor": "2026-03-18T10:30:00Z|12345",
  "hasMore": true,
  "totalAprox": 120
}
```

> `totalAprox` evita costo alto de conteo exacto cuando el volumen es grande.

### Nota admin

- Para evitar payloads inmanejables en `scope=all`, se recomienda exigir al menos uno de:
  - `idPersonal`, o
  - `idLugar`, o
  - `desde/hasta` acotado.

---

## 3) `GET /citas/mis-timeline`

Listado principal paginado por cursor temporal y agrupado por fecha.

### Query params

- `desde` (ISO opcional, default hoy 00:00)
- `cursorFechaHora` (ISO opcional)
- `cursorId` (opcional; desempate estable)
- `limit` (default 30)
- `idLugar` (opcional)
- `incluirSolicitadas` (default `false`, porque ya viven en el bloque superior)
- `scope` (opcional: `mine` | `all`, default `mine`)
- `idPersonal` (opcional; filtro de personal cuando `scope=all`)

### Reglas

- Trae estados operativos futuros (por ejemplo `CONFIRMADA`, y opcionalmente `SOLICITADA` si `incluirSolicitadas=true`).
- Orden ascendente por fecha.
- Devuelve grupos por fecha para render directo en móvil.

### Response sugerida

```json
{
  "grupos": [
    {
      "fecha": "2026-03-13",
      "items": []
    },
    {
      "fecha": "2026-03-14",
      "items": []
    }
  ],
  "nextCursor": {
    "cursorFechaHora": "2026-03-14T16:00:00Z",
    "cursorId": "98765"
  },
  "hasMore": true
}
```

---

## ¿Cuántas APIs conviene tener?

Recomendación: **3 endpoints** (resumen + solicitadas + timeline).

- Menos de 3 sobrecarga un endpoint con demasiada responsabilidad.
- Más de 3 aumenta complejidad de integración móvil sin beneficio claro.

Si se quiere simplificar al máximo en backend, alternativa de **2 endpoints**:

1. `GET /citas/mis-home` (resumen + primera página solicitadas + primera página timeline)
2. `GET /citas/mis-home/continuar` (cursor para siguientes páginas por sección)

Pero esta opción suele ser más difícil de mantener.

---

## ¿Cómo cubrir el caso administrador sin duplicar endpoints?

La mejor estrategia es **mantener los mismos 3 endpoints** y agregar control de alcance por `scope` + `idPersonal`:

1. Evita crear pares duplicados como `/mis-*` y `/admin-*`.
2. Reduce costo de mantenimiento en frontend y backend.
3. Mantiene reglas de seguridad centralizadas por rol.

### Reglas recomendadas

- `scope=mine`: usa siempre el `idUsuarioRol` autenticado.
- `scope=all`:
  - permitido solo a admin,
  - opcionalmente exige filtros mínimos para proteger performance,
  - permite ver uno, varios o todos los personales (según políticas Casbin).

### UX recomendada para admin en móvil

- Agregar selector "Ver: Mis citas | Todo el personal".
- Si elige "Todo el personal", mostrar filtros rápidos:
  - Personal,
  - Lugar,
  - Rango de fechas.
- Mantener el mismo comportamiento de bloque "Solicitadas" colapsable.

---

## Comportamiento recomendado para "solicitadas arriba"

1. La UI abre con solicitadas **visibles** por defecto.
2. El usuario puede colapsarlas (preferencia local persistida en app).
3. Si `solicitadasPendientesConfirmacion > N` (ej. 20), mostrar:
   - primeras 10/20,
   - botón "Ver más" que pagina `mis-solicitadas`.
4. El timeline debajo no se bloquea por cargar solicitadas.

Así se evita que demasiadas solicitadas "se coman" toda la pantalla.

---

## Notas de implementación backend

1. Mantener autorización por usuario autenticado en servicio ("mis citas").
2. Usar cursor-based pagination (fecha + id) para estabilidad con datos en movimiento.
3. Index recomendado en tabla citas:
   - `(id_personal, estado, fecha_inicio, id)`
   - `(id_personal, fecha_inicio, id)`
4. Evitar `COUNT(*)` pesado en cada request; usar conteo aproximado o diferido para badges.

---

## Plan de implementación sugerido

1. Crear `GET /citas/mis-resumen`.
2. Crear `GET /citas/mis-solicitadas` (cursor).
3. Crear `GET /citas/mis-timeline` (cursor + agrupación por fecha).
4. Mobile: nueva pantalla con bloque colapsable + timeline infinito.
5. Métricas: tiempo medio de confirmación y tasa de no asistencia.
6. Extender frontend/admin con selector de alcance (`mine/all`) + filtros de personal.
