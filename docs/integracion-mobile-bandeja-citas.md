# Integración mobile: Bandeja Home de citas (resumen + previews + bandejas incrementales)

Esta guía describe cómo implementar en la app mobile la nueva bandeja de citas del Home.

## Objetivo funcional

1. Cargar Home con una sola llamada (`/citas/home/bandeja`).
2. Mostrar contadores y previews por prioridad.
3. Abrir cada bandeja completa de forma independiente.
4. Manejar carga incremental (sin páginas numéricas).
5. En confirmadas, cargar incremental por días.

---

## Orden de visualización en Home

1. Alertas operativas
   - Pendientes de aprobación
   - Rechazadas
2. Borradores
3. Confirmadas asignadas

---

## 1) Endpoint principal de Home

> Estos endpoints están expuestos en un controlador dedicado `HomeCitasController` bajo el prefijo `citas/home`.

`GET /citas/home/bandeja`

### Query params

- `scope`: `mine | personal | all` (default `mine`)
- `idPersonal`: requerido cuando `scope=personal`
- `idLugar` (opcional)
- `fechaBase` (opcional)
- `limitPreview` (opcional, default `10`)

### Respuesta

```json
{
  "finalizado": true,
  "mensaje": "Operación realizada con éxito",
  "datos": {
    "scopeAplicado": "mine",
    "idPersonalAplicado": "42",
    "fechaBase": "2026-03-16",
    "contadores": {
      "pendientesAprobacionAsignadas": 12,
      "rechazadasSolicitadasPorMi": 5,
      "borradores": 8,
      "confirmadasAsignadas": 34
    },
    "preview": {
      "pendientesAprobacionAsignadas": {
        "items": [],
        "total": 12,
        "limitAplicado": 10,
        "hasMore": true
      },
      "rechazadasSolicitadasPorMi": {
        "items": [],
        "total": 5,
        "limitAplicado": 10,
        "hasMore": false
      },
      "borradores": {
        "items": [],
        "total": 8,
        "limitAplicado": 10,
        "hasMore": false
      },
      "confirmadasAsignadas": {
        "items": [],
        "total": 34,
        "limitAplicado": 10,
        "reglaAplicada": "top10_o_todas_las_de_hoy_si_hoy_gt_10",
        "hasMore": true
      }
    },
    "updatedAt": "2026-03-16T14:20:00.000Z"
  }
}
```

### Regla especial confirmadas en preview

- Mostrar top 10 próximas por fecha.
- Si hoy tiene más de 10 confirmadas, mostrar todas las de hoy.

---

## 2) Endpoints de bandeja completa (uno por bloque)

## Pendientes de aprobación

`GET /citas/home/pendientes-aprobacion`

## Rechazadas

`GET /citas/home/rechazadas-solicitadas`

## Borradores

`GET /citas/home/borradores`

## Confirmadas (incremental por días)

`GET /citas/home/confirmadas-asignadas`

---

## 3) Listados paginados

Para pendientes/rechazadas/borradores (heredan `PaginacionQueryDto`):

### Query params

- `scope`, `idPersonal`, `idLugar`, `fechaBase`
- `limite` (default 10)
- `pagina` (default 1)
- `filtro` (opcional)
- `orden` (opcional)

### Respuesta

```json
{
  "finalizado": true,
  "mensaje": "Listado exitoso",
  "datos": {
    "filas": [],
    "total": 96
  }
}
```

### Estrategia en app

1. Cargar `pagina=1`.
2. Incrementar página según scroll/paginador.
3. Reemplazar o concatenar según estrategia de UI.

---

## 4) Confirmadas paginadas agrupadas por días

### Query params

- comunes: `scope`, `idPersonal`, `idLugar`, `limite`, `pagina`
- `dia` (`YYYY-MM-DD`, opcional; filtra un día específico)

### Respuesta

```json
{
  "finalizado": true,
  "mensaje": "Listado exitoso",
  "datos": {
    "filas": [
      { "dia": "2026-03-16", "items": [] },
      { "dia": "2026-03-17", "items": [] }
    ],
    "total": 96
  }
}
```

### Estrategia UI para confirmadas

- Renderizar por secciones (`dia`).
- Al paginar, pedir siguiente `pagina` manteniendo agrupación por `dia`.
- Mantener agrupación por día.

---

## 5) Reglas de scope por rol

- `PERSONAL`: backend fuerza `scope=mine`.
- `PERSONAL_ADMINISTRADOR` (funcional): usuario con rol `PERSONAL_SALUD` y `esSupervisor=true`.
  - default `mine`,
  - puede usar `personal` + `idPersonal`,
  - puede usar `all`.

> Si un usuario `PERSONAL_SALUD` no tiene `esSupervisor=true`, cualquier `scope` enviado distinto de `mine` será ignorado por backend.

---

## 6) Flujo recomendado en mobile

1. Abrir Home → llamar `GET /citas/home/bandeja`.
2. Pintar contadores + previews.
3. Al tocar un contador o `Ver todas`, abrir bandeja específica.
4. Gestionar incremental solo en la bandeja abierta.
5. Si cambia scope/filtros, resetear estado y cursores de la bandeja actual.

---

## 7) Tiempo real

Socket namespace: `/citas-home`

Eventos mínimos:

- `cita.creada`
- `cita.actualizada`
- `cita.estado_cambiado`
- `cita.eliminada`
- `citas:home-actualizada` (evento orientado a refrescar contadores/previews de Home)

Comportamiento:

- En Home: refrescar contadores + preview impactado.
- En bandeja específica abierta: refrescar solo esa bandeja.
- Fallback: polling cada 60–120s.
