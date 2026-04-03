# Implementación completa: citas con pago pendiente, regularización y caja

## Objetivo

Este flujo permite completar la atención clínica aunque el cobro no se realice en el mismo momento. Cuando no se cobra al completar atención, se crea un **pago pendiente**. Luego, **JEFE** o **COORDINADOR** pueden regularizar ese pendiente desde bandejas de pagos.

## Roles

- `PROFESIONAL_INVITADO`
  - Puede completar atención.
  - No puede operar pagos/caja/reportes.
  - Al completar atención, su registro financiero se crea como **PENDIENTE**.
- `COORDINADOR`
  - Puede ver pagos pendientes.
  - Puede regularizar (cobrar) pagos pendientes.
  - Puede anular pagos.
- `JEFE`
  - Puede ver/regularizar/anular pagos.
  - Puede apertura/cierre de caja.

## Modelo de pagos

Se mantiene una sola fila activa por cita en `cita_pago` y se incorpora `estado_pago`:

- `PENDIENTE`: deuda pendiente de regularización.
- `PAGADO`: cobro realizado y asociado a caja.
- `ANULADO`: pago anulado.

Notas:

- `_estado` sigue controlando vigencia técnica (ACTIVO/INACTIVO).
- `id_caja_sesion`, `metodo_pago` y `fecha_pago` son opcionales mientras esté pendiente.

## Flujos

### 1) Completar atención con pago inmediato

`POST /api/citas/:id/completar-atencion`

- Si `registrarPago=true` y rol permitido:
  - exige `metodoPago`
  - exige caja abierta
  - crea pago `estado_pago=PAGADO`
  - cambia cita a `COMPLETADA`

### 2) Completar atención con pago pendiente

`POST /api/citas/:id/completar-atencion`

- Si `registrarPago=false` o rol `PROFESIONAL_INVITADO`:
  - crea pago `estado_pago=PENDIENTE`
  - sin caja, sin método obligatorio
  - cambia cita a `COMPLETADA`

### 3) Regularizar pendiente

`POST /api/citas/:id/pagos`

- Si la cita tiene pago activo `PENDIENTE`:
  - exige caja abierta
  - setea método/fecha/caja
  - cambia `estado_pago` a `PAGADO`
- Si no hay pendiente, crea pago directo pagado (flujo habitual).

### 4) Anular pago

`POST /api/pagos/:id/anular`

- Marca `estado_pago=ANULADO`
- Marca `_estado=INACTIVO`

## Bandejas y Home

### Bandeja de pagos pendientes

`GET /api/pagos/pendientes`

- Visible para `ADMINISTRADOR`, `JEFE`, `COORDINADOR`.
- Devuelve los pagos en `estado_pago=PENDIENTE`.

### Home: bloque de pagos pendientes

`GET /api/citas/home/bandeja`

- Agrega contador `pagosPendientes` y preview `pagosPendientes`.

`GET /api/citas/home/pagos-pendientes`

- Lista incremental de citas con pago pendiente para seguimiento y cobro.

## Rutas principales

- `POST /api/citas/:id/completar-atencion`
- `POST /api/citas/:id/pagos`
- `GET /api/citas/:id/pagos`
- `GET /api/pagos/pendientes`
- `POST /api/pagos/:id/anular`
- `GET /api/reportes/pagos`
- `GET /api/caja/actual`
- `POST /api/caja/apertura`
- `POST /api/caja/cierre`

## Reportes

`GET /api/reportes/pagos`

- Considera únicamente pagos activos con `estado_pago=PAGADO`.
- Excluye pendientes y anulados.
