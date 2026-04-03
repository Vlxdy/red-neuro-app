# Implementación móvil: atención completada + pendiente + regularización

## Objetivo UX

Permitir que la atención se complete siempre, incluso sin cobro inmediato.

## Reglas por rol

- `PROFESIONAL_INVITADO`: completa atención, genera pendiente, no cobra.
- `COORDINADOR`: ve pendientes y los regulariza.
- `JEFE`: ve pendientes, regulariza y administra caja.

## Pantallas sugeridas

### 1) Completar atención

Acción: **Completar atención**
Payload mínimo:

- `monto`
- `registrarPago` (opcional; default true)
- `metodoPago` solo cuando se paga al instante

Comportamiento:

- Invitado => siempre pendiente.
- Coordinador/Jefe => puede pago inmediato o pendiente.

### 2) Bandeja de pagos pendientes

Endpoint: `GET /api/pagos/pendientes`

- Lista de pendientes para regularizar.
- Acciones:
  - cobrar: `POST /api/citas/:id/pagos`
  - anular: `POST /api/pagos/:id/anular`

### 3) Home con pendientes

- `GET /api/citas/home/bandeja` (contador + preview)
- `GET /api/citas/home/pagos-pendientes` (listado incremental)

## Estados visibles

- `PENDIENTE`: falta cobrar.
- `PAGADO`: regularizado.
- `ANULADO`: inválido/anulado.

## Mensajes recomendados

- “Atención completada. Pago pendiente de regularización.”
- “Pago regularizado correctamente.”
- “No existe caja abierta para regularizar este pago.”
