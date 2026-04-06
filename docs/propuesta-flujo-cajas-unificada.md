# Propuesta ajustada: bandeja única de **Cajas** + cierre mensual con revisión

## 1) Objetivo

Unificar la operación en una sola bandeja llamada **Cajas** y eliminar la bandeja separada de pagos, incorporando:

- selección de caja,
- detalle de caja,
- listado paginado de movimientos/pagos,
- reglas operativas de cierre mensual con revisión,
- control estricto de pendientes antes de cerrar,
- control de visibilidad por rol (Home vs Bandeja Cajas vs Pagos).

## 2) Flujo funcional propuesto (nuevo)

1. El usuario abre el módulo **Cajas**.
2. El frontend carga `GET /caja` para el selector.
3. Siempre hay una caja seleccionada:
   - por defecto, la caja en estado `ABIERTA`;
   - si no existe, la más reciente en `REVISION`.
4. Al seleccionar una caja se muestran:
   - cabecera de caja (estado, fechas, montos, responsable),
   - tabla paginada de pagos/movimientos de esa caja.
5. Operación mensual:
   - al inicio de cada mes se crea automáticamente una nueva caja `ABIERTA`,
   - la caja anterior pasa a estado `REVISION`.
6. Cierre:
   - solo `JEFE` puede cerrar una caja,
   - no se puede cerrar con pagos pendientes,
   - si hay pendientes, primero se regularizan o se trasladan a la nueva caja.
7. Visibilidad por rol:
   - Home con resumen de pendientes: `ADMINISTRADOR`, `JEFE`, `COORDINADOR`,
   - bandeja Cajas: solo `ADMINISTRADOR`, `JEFE`,
   - detalle de pagos (totales/resúmenes operativos): solo `ADMINISTRADOR`, `JEFE`.

## 3) Reglas de negocio (importantes)

### 3.1 Estados sugeridos de caja

- `ABIERTA`: caja operativa del mes en curso.
- `REVISION`: caja del mes anterior en auditoría operativa.
- `CERRADA`: caja validada y cerrada por jefe.

### 3.2 Rotación mensual automática

- Fecha de corte sugerida: **00:00 del día 1 de cada mes**.
- Acción automática:
  1. si existe una caja `ABIERTA`, cambiarla a `REVISION`;
  2. crear nueva caja `ABIERTA` del mes actual.

### 3.3 Regla de cierre estricto

No permitir `POST /caja/:id/cierre` si existe al menos un pago con:

- `estadoPago = PENDIENTE` asociado a esa caja, o
- inconsistencia de conciliación (opcional, si se activa validación contable).

Respuesta recomendada al intentar cerrar con pendientes:

- HTTP 409 + detalle de pendientes + acciones sugeridas.

### 3.4 Resolución de pagos pendientes

Dos caminos válidos antes de cerrar:

1. **Regularizar pago** en la misma caja en revisión.
2. **Trasladar pendiente** a la caja abierta del nuevo mes.

### 3.5 Regla para corrección de pagos (sin edición directa)

- Un pago **no se modifica en la misma fila**.
- Para corregir un pago se debe:
  1. marcar el pago original con estado de reemplazo/invalidez controlada,
  2. crear un **nuevo pago** con los datos corregidos.
- Esta operación está permitida solo cuando la caja esté en `ABIERTA`.
- Si la caja está en `REVISION` o `CERRADA`, la corrección debe bloquearse (HTTP 409).
- Debe quedar trazabilidad completa: quién registró el original, quién hizo la corrección, cuándo y por qué.

Estados sugeridos para este caso:
- `REGISTRADO`: pago vigente.
- `REEMPLAZADO`: pago original que fue sustituido por corrección.
- `ANULADO`: pago inválido por anulación operativa/administrativa.

### 3.6 Matriz de permisos solicitada

#### A) Home (resúmenes de pagos pendientes)

- Pueden ver resumen/badge de pendientes:
  - `ADMINISTRADOR`
  - `JEFE`
  - `COORDINADOR`
- No pueden ver:
  - todos los demás roles.

#### B) Bandeja Cajas

- Pueden acceder:
  - `ADMINISTRADOR`
  - `JEFE`
- No pueden acceder:
  - `COORDINADOR` y demás roles.

#### C) Regulación de pagos pendientes

- Desde Home:
  - `ADMINISTRADOR`, `JEFE`, `COORDINADOR`.
- Desde Bandeja Cajas:
  - `ADMINISTRADOR`, `JEFE`.

#### D) Totales y resúmenes financieros detallados

- Mostrar solo para:
  - `ADMINISTRADOR`
  - `JEFE`
- No exponer a `COORDINADOR` ni otros roles.

#### E) Historial/Auditoría de pagos

- Todo pago debe mantener:
  - `idUsuarioRegistro`,
  - `fechaRegistro`,
  - `idUsuarioModificacion` (si aplica por flujo de reemplazo),
  - `fechaModificacion`,
  - `motivo` de reemplazo/anulación,
  - referencia al pago anterior (`idPagoOrigen`) y al nuevo (`idPagoReemplazo`) cuando corresponda.
- No se debe perder historial de versiones del pago.

## 4) Endpoints propuestos (sin estrategia deprecada)

> Ajuste solicitado: **no usar esquema de endpoints deprecados**. Se define reemplazo directo y limpieza.

### 4.1 Endpoints de caja (bandeja única)

#### A) Listado de cajas para selector

`GET /caja`

Query params:
- `estado` (`ABIERTA|REVISION|CERRADA`, opcional)
- `gestion` (YYYY, opcional)
- `mes` (1..12, opcional)
- `pagina`, `limite`

Respuesta:
- `rows`
- `total`
- `defaultCajaId`

#### B) Detalle de caja

`GET /caja/:id`

Incluye:
- metadata,
- resumen operativo,
- contadores (`pagosTotales`, `pagosPendientes`, `pagosAnulados`).

#### C) Movimientos de la caja (paginado)

`GET /caja/:id/movimientos`

Query params:
- `pagina`, `limite`
- `estadoPago` (`PAGADO|PENDIENTE|ANULADO`)
- `metodoPago`
- `fechaDesde`, `fechaHasta`

#### D) Crear caja manual (fallback)

`POST /caja/apertura`

> Se mantiene para contingencia operativa; la creación normal será automática por scheduler mensual.

#### E) Cerrar caja por id (con validación de pendientes)

`POST /caja/:id/cierre`

Valida:
- caja en `REVISION` o `ABIERTA` (según regla final),
- cero pendientes.

#### F) Cambio de estado por rotación mensual (interno/sistema)

`POST /caja/rotacion-mensual`

- Endpoint interno o job programado (cron).
- No expuesto a cliente mobile/web normal.

### 4.2 Endpoints de pagos alineados a caja

#### G) Listado de pagos pendientes (solo pendientes)

`GET /pagos/pendientes`

Propósito:
- devolver **únicamente pagos en estado `PENDIENTE`**.

Acceso:
- `JEFE` (privado de pagos según requerimiento),
- opcionalmente `ADMINISTRADOR` si negocio lo habilita.

Notas:
- este endpoint no devuelve totales globales para roles no autorizados,
- para Home se puede exponer un resumen controlado por rol en endpoint de home (ver sección 4.3).

#### H) Regularizar pago pendiente

`POST /pagos/:id/regularizar`

- Completa cobro de pendiente.
- Acceso desde Home: `ADMINISTRADOR`, `JEFE`, `COORDINADOR`.
- Acceso desde Cajas: `ADMINISTRADOR`, `JEFE`.

#### I) Corregir pago (crear nuevo y reemplazar anterior)

`POST /pagos/:id/corregir`

Uso:
- no actualiza el pago original; crea un nuevo pago corregido y marca el anterior como `REEMPLAZADO`.

Body sugerido:

```json
{
  "nuevoPago": {
    "metodoPago": "QR",
    "monto": 120,
    "fechaPago": "2026-04-04T10:30:00.000Z",
    "observacion": "Corrección por método de cobro"
  },
  "motivo": "Corrección de registro",
  "idCajaDestino": "uuid-opcional-si-corresponde"
}
```

Validación obligatoria:
- solo permitido si la caja del pago original está en `ABIERTA`.

Resultado esperado:
- pago anterior cambia a `REEMPLAZADO`,
- nuevo pago queda en `REGISTRADO`,
- ambos quedan enlazados por referencia de auditoría.

Acceso:
- `ADMINISTRADOR`, `JEFE`.

#### J) Trasladar pago pendiente de caja

`POST /pagos/:id/trasladar-caja`

Body sugerido:

```json
{
  "idCajaDestino": "uuid",
  "motivo": "Pendiente heredado de cierre mensual"
}
```

Reglas:
- solo si `estadoPago = PENDIENTE`,
- no permitido para pagos ya `PAGADO`/`ANULADO`.
- acceso: `ADMINISTRADOR`, `JEFE`.

### 4.3 Endpoint de Home para resumen de pendientes (rol-controlado)

`GET /citas/home/bandeja`

Regla de respuesta:
- incluir bloque/resumen de pagos pendientes solo para:
  - `ADMINISTRADOR`, `JEFE`, `COORDINADOR`.
- ocultar bloque para el resto.

## 5) Qué endpoints eliminar o reemplazar

### Eliminar/reemplazar

1. `GET /caja/actual`
   - reemplazado por `GET /caja` + `defaultCajaId`.
2. `GET /citas/home/pagos-pendientes`
   - eliminar si la operación queda centralizada en bandeja única de Cajas.

### Mantener

- `GET /pagos/pendientes` (solo pendientes, con permisos restringidos).
- `POST /pagos/:id/anular` (opcional, sujeto a política financiera).

## 6) Propuesta de contrato UI para la nueva bandeja

1. Pantalla única `Cajas`.
2. Selector superior (combo) con cajas.
3. Card de resumen de caja seleccionada.
4. Tabla paginada de movimientos con filtros.
5. Si la caja está en `REVISION`:
   - mostrar badge “En revisión”,
   - habilitar acciones de regularizar/trasladar pendientes,
   - botón `Cerrar caja` solo cuando pendientes = 0.

## 7) Plan de implementación técnico

1. **Entidad/DB**
   - agregar estado `REVISION` a `caja_sesion.estado`.
   - agregar campos de periodo: `gestion`, `mes` (si no existen).
   - extender estado de pago para soportar `REEMPLAZADO` en historial de correcciones.
   - agregar referencias `idPagoOrigen`/`idPagoReemplazo` (o tabla de historial) para trazabilidad.
2. **Scheduler**
   - job mensual para rotación de caja.
3. **Repository**
   - query paginada de movimientos por `idCajaSesion`.
   - query de conteo de pendientes por caja.
4. **Service**
   - `listarCajas`, `obtenerCaja`, `listarMovimientosCaja`, `cerrarCajaConValidacion`.
   - `trasladarPagoPendienteCaja`.
   - `corregirPagoConVersionado` (marca anterior + crea nuevo).
5. **Controller**
   - nuevas rutas descritas arriba.
6. **Validaciones**
   - bloquear cierre con pendientes (HTTP 409).
   - bloquear corrección de pagos cuando la caja no esté `ABIERTA`.
7. **Auditoría**
   - persistir relación entre pago original y pago corregido.
   - exponer historial para trazabilidad.

## 8) Resumen ejecutivo final

### Crear
- `GET /caja`
- `GET /caja/:id`
- `GET /caja/:id/movimientos`
- `POST /caja/:id/cierre`
- `POST /caja/rotacion-mensual` (interno)
- `POST /pagos/:id/regularizar`
- `POST /pagos/:id/corregir` (crea nuevo + marca anterior `REEMPLAZADO`, solo caja `ABIERTA`)
- `POST /pagos/:id/trasladar-caja`

### Mantener
- `POST /caja/apertura` (fallback)
- `GET /pagos/pendientes` (solo pendientes)
- `POST /pagos/:id/anular` (según política)

### Eliminar/reemplazar
- `GET /caja/actual`
- `GET /citas/home/pagos-pendientes`
