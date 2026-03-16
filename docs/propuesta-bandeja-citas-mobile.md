# Propuesta integral: Bandeja Home de Citas (Mobile)

## 1) Objetivo

Definir desde cero una propuesta completa para la bandeja de citas del Home mobile que:

- priorice el trabajo operativo real del usuario,
- funcione para `PERSONAL` y para el perfil supervisor de `PERSONAL_SALUD` (`esSupervisor=true`),
- cargue rápido en la pantalla inicial,
- soporte alto volumen de citas,
- se actualice en tiempo real,
- y permita abrir cada bandeja completa por separado con listados **paginados**.

> Nota: la app administra la navegación incremental en cliente; backend expone paginación (`limite` + `pagina`) para continuar carga.

---

## 2) Alcance funcional (lo que debe ver el usuario)

La Home muestra primero un resumen y luego previews por prioridad.

## Orden obligatorio en Home

1. **Alertas operativas**
   - Citas asignadas al usuario y pendientes de aprobación.
   - Citas rechazadas donde el usuario fue quien solicitó.
2. **Borradores creados por el usuario**
3. **Citas confirmadas asignadas al usuario**

---

## 3) Reglas de visualización en Home

## 3.1 Resumen superior (contadores)

Debe mostrar los contadores de los 4 grupos:

- pendientes de aprobación (asignadas),
- rechazadas solicitadas por mí,
- borradores,
- confirmadas asignadas.

Al tocar un contador, se abre la bandeja completa de ese grupo.

## 3.2 Previews en Home

Regla base de preview por grupo:

- mostrar **máximo 10** ítems por grupo.

Regla especial para confirmadas asignadas:

- ordenar por `fechaInicio ASC` (las próximas primero),
- si hoy tiene más de 10 confirmadas, mostrar **todas las de hoy**,
- si hoy tiene 10 o menos, completar hasta 10 con fechas siguientes.

Motivo: evitar ocultar carga crítica del día.

## 3.3 Alto volumen

Si un grupo tiene más resultados que su preview:

- mostrar CTA `Ver todas (N)`.
- al tocar CTA, abrir **solo esa** bandeja completa.
- no recargar ni mezclar otros grupos.

---

## 4) Vista sugerida (ASCII)

```text
┌───────────────────────────────────────────────┐
│ HOME - Citas                                  │
│ [Ver: Mis citas v] [Lugar v] [Fecha base v]   │
├───────────────────────────────────────────────┤
│ CONTADORES                                    │
│ [Pend. Aprobación: 12] [Rechazadas: 5]        │
│ [Borradores: 8]       [Confirmadas: 34]       │
├───────────────────────────────────────────────┤
│ 1) ALERTAS OPERATIVAS                         │
│   Pendientes de aprobación                     │
│   • ... (preview)                             │
│   [Ver todas (12)]                            │
│                                               │
│   Rechazadas                                  │
│   • ... (preview)                             │
│   [Ver todas (5)]                             │
├───────────────────────────────────────────────┤
│ 2) BORRADORES                                 │
│   • ... (preview)                             │
│   [Ver todas (8)]                             │
├───────────────────────────────────────────────┤
│ 3) CONFIRMADAS ASIGNADAS                      │
│   • Hoy 08:00                                 │
│   • Hoy 08:30                                 │
│   • Hoy 09:00                                 │
│   ... (si hoy >10, mostrar todas las de hoy)  │
│   [Ver todas (34)]                            │
└───────────────────────────────────────────────┘
```

---

## 5) Modelo por rol

## `PERSONAL`

- Solo puede consultar su propio alcance.
- Backend fuerza `scope=mine`.

## `PERSONAL_ADMINISTRADOR` (funcional)

En este proyecto corresponde a un usuario con rol `PERSONAL_SALUD` y `esSupervisor=true`.

- Inicia por defecto igual que personal (`scope=mine`).
- Puede cambiar a:
  - `scope=personal` (`idPersonal` obligatorio),
  - `scope=all` (según visibilidad permitida por políticas).

## Selector recomendado para admin

- `Mis citas` | `Un personal` | `Todos`
- Si `Un personal`: selector/autocomplete.
- Si `Todos`: permitir filtro por lugar y/o rango temporal para control de volumen.

---

## 6) Contrato API propuesto

Se propone separar claramente:

1. **Endpoint único de Home** (resumen + previews).
2. **Endpoints por bandeja completa** (uno por tipo), todos paginados.

## 6.1 Endpoint de Home

`GET /citas/home/bandeja`

### Propósito

Retornar todo lo necesario para renderizar la Home en una sola llamada:

- contadores,
- previews por grupo,
- metadata de filtros aplicados.

### Query params

- `scope` = `mine | personal | all` (default `mine`)
- `idPersonal` (requerido cuando `scope=personal`)
- `idLugar` (opcional)
- `fechaBase` (opcional; default hoy)
- `limitPreview` (opcional; default 10)

### Response sugerida

```json
{
  "scopeAplicado": "mine",
  "idPersonalAplicado": "p-123",
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
      "reglaAplicada": "top10_o_todas_las_de_hoy_si_hoy_gt_10",
      "hasMore": true
    }
  },
  "updatedAt": "2026-03-16T14:20:00Z"
}
```

---

## 6.2 Endpoints de bandeja completa (uno por caso)

Para que cada vista “Ver todas” consulte solo su propio dominio:

1. `GET /citas/home/pendientes-aprobacion`
2. `GET /citas/home/rechazadas-solicitadas`
3. `GET /citas/home/borradores`
4. `GET /citas/home/confirmadas-asignadas` (paginado y agrupado por días)

### Query params comunes

- `scope` = `mine | personal | all`
- `idPersonal` (si aplica)
- `idLugar` (opcional)
- `fechaBase` (opcional)
- `limite` (default 10)
- `pagina` (default 1)

### Query params adicionales para confirmadas (por días)

- `dia` (opcional, formato `YYYY-MM-DD`)

### Response común sugerida

```json
{
  "filas": [],
  "total": 96
}
```

> Se propone paginación estándar con `limite` y `pagina`, heredando `PaginacionQueryDto`.

### Respuesta sugerida para confirmadas por días

```json
{
  "grupos": [
    {
      "dia": "2026-03-16",
      "items": []
    },
    {
      "dia": "2026-03-17",
      "items": []
    }
  ],
  "total": 96
}
```

---

## 7) Reglas de orden por endpoint

- `pendientes-aprobacion`: prioridad operativa, luego `fechaInicio ASC`, `id ASC`.
- `rechazadas-solicitadas`: `updatedAt DESC`, `id DESC`.
- `borradores`: `updatedAt DESC`, `id DESC`.
- `confirmadas-asignadas`: agrupadas por día (`dia ASC`) y dentro de cada día `fechaInicio ASC`, `id ASC`.

---

## 8) Paginado en cliente (comportamiento esperado)

Para cualquier bandeja completa:

1. al abrir, pedir `pagina=1`,
2. para más resultados, incrementar `pagina`,
3. usar `limite` para tamaño de página.

Para **confirmadas**, además de paginar, se renderiza agrupado por día.

---

## 9) Tiempo real (sockets)

## Namespace/rooms sugeridos

- Namespace: `/citas-home`
- Rooms:
  - `user:{idUsuario}`
  - `personal:{idPersonal}`
  - `admin_scope:{tenantId}` (si aplica)

## Eventos mínimos

- `cita.creada`
- `cita.actualizada`
- `cita.estado_cambiado`
- `cita.eliminada`

## Reacción cliente

- Si usuario está en Home:
  - actualizar contadores,
  - refrescar preview del bloque impactado.
- Si usuario está en una bandeja completa:
  - actualizar solo esa bandeja.
- Fallback:
  - polling suave cada 60–120s si no hay socket,
  - re-sync tras reconexión con `syncSince`.

---

## 10) Cambios backend necesarios

## 10.1 Crear

- `GET /citas/home/bandeja`
- `GET /citas/home/pendientes-aprobacion`
- `GET /citas/home/rechazadas-solicitadas`
- `GET /citas/home/borradores`
- `GET /citas/home/confirmadas-asignadas`
- Publicación de eventos socket de citas (creada/actualizada/estado/eliminada).

## 10.2 Modificar

- Capa de autorización para aplicar `scope` por rol en todos los endpoints.
- Servicio de consultas para soportar paginación (`limite` + `saltar`).
- Capa de agregación para construir `contadores + previews` del endpoint Home.
- Reglas de negocio de confirmadas para excepción “todas las de hoy si hoy >10”.

## 10.3 Reutilizar

- DTO/base de cita para response `items`.
- Middleware de autenticación/autorización existente.
- Infraestructura actual de sockets (si ya existe en proyecto).

---

## 11) Performance e índices

Índices recomendados:

- `(id_personal, estado, fecha_inicio, id)`
- `(creado_por, estado, updated_at, id)`
- `(estado, fecha_inicio, id)` para `scope=all`

Recomendaciones:

- evitar `COUNT(*)` pesado en cada request,
- usar `totalAprox` cuando corresponda,
- cache corto para contadores de Home si el tráfico crece.

---

## 12) Plan de implementación

1. Definir mapa final de estados por cada bandeja.
2. Implementar endpoint `GET /citas/home/bandeja`.
3. Implementar los 4 endpoints de bandeja completa (paginados).
4. Integrar sockets + eventos.
5. Ajustar cliente mobile (Home + vistas Ver todas).
6. QA funcional por rol.
7. QA de volumen: >10, >100, >1000 por bandeja.

---

## 13) Criterios de aceptación

- Home carga con una sola llamada (`/citas/home/bandeja`).
- Orden en Home respeta prioridad funcional definida.
- Cada contador/CTA abre solo su bandeja específica.
- Cada bandeja completa carga con paginación por `limite` y `pagina`.
- Confirmadas se renderiza agrupada por día (caso especial).
- Regla especial de confirmadas de hoy aplicada correctamente.
- Funciona para `PERSONAL` y para `PERSONAL_SALUD` supervisor (`esSupervisor=true`) según reglas de scope.
- Cambios se reflejan en tiempo real o fallback de polling.
