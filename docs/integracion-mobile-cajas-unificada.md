# Integración mobile: bandeja unificada de Cajas

Esta guía describe cómo integrar en la app mobile el nuevo flujo de **Cajas** con:

- selector de caja,
- detalle de caja,
- movimientos paginados,
- corrección de pagos por reemplazo,
- control de visibilidad por rol.

---

## 1) Matriz de acceso por rol

### 1.1 Home (resumen de pagos pendientes)
Pueden ver bloque/resumen en Home:
- `ADMINISTRADOR`
- `JEFE`
- `COORDINADOR`

No deben ver este bloque:
- resto de roles.

### 1.2 Bandeja Cajas
Pueden acceder a la pantalla Cajas:
- `ADMINISTRADOR`
- `JEFE`

### 1.3 Acciones de pagos
- Regularizar pago desde Home:
  - `ADMINISTRADOR`, `JEFE`, `COORDINADOR`
- Regularizar/corregir/trasladar desde Cajas:
  - `ADMINISTRADOR`, `JEFE`

---

## 2) Endpoints para mobile

## 2.1 Home

### `GET /api/citas/home/bandeja`
- Usa este endpoint para badges y resumen del Home.
- El bloque de pagos pendientes debe mostrarse solo cuando el backend lo devuelva (según rol).

## 2.2 Cajas

### `GET /api/caja`
Listado de cajas para el selector.

Parámetros opcionales:
- `estado=ABIERTA|REVISION|CERRADA`
- `gestion`
- `mes`
- `pagina`
- `limite`

Respuesta esperada:
- `rows[]`
- `total`
- `defaultCajaId`

### `GET /api/caja/:id`
Detalle de caja seleccionada:
- estado,
- fechas,
- montos,
- `pagosPendientes`.

### `GET /api/caja/:id/movimientos`
Movimientos/pagos de la caja (paginado).

Parámetros opcionales:
- `pagina`, `limite`
- `estadoPago=PAGADO|PENDIENTE|ANULADO|REEMPLAZADO`
- `metodoPago`
- `fechaDesde`, `fechaHasta`

### `POST /api/caja/:id/cierre`
Cierra caja por id (solo `JEFE`).

Reglas:
- si la caja tiene pagos pendientes, backend responde error y no cierra.

## 2.3 Pagos

### `GET /api/pagos/pendientes`
- Bandeja privada de pendientes (principalmente `JEFE`, opcional `ADMINISTRADOR` según política final).
- No usar este endpoint para mostrar datos a roles no autorizados.

### `POST /api/pagos/:id/regularizar`
Regulariza pago pendiente.

### `POST /api/pagos/:id/corregir`
Corrige pago por reemplazo (no edita el original).

Comportamiento backend:
1. marca pago anterior como `REEMPLAZADO`,
2. crea nuevo pago con datos corregidos,
3. relaciona nuevo pago con `idPagoOrigen`.

Regla:
- solo se permite cuando la caja del pago está `ABIERTA`.

### `POST /api/pagos/:id/trasladar-caja`
Traslada un pago pendiente a otra caja.

---

## 3) Flujo UI recomendado

## 3.1 Pantalla Home
1. Llamar `GET /api/citas/home/bandeja`.
2. Si backend incluye bloque de pendientes, mostrar badge y acceso.
3. Si no incluye bloque, ocultar sección.

## 3.2 Pantalla Cajas
1. Al abrir pantalla, llamar `GET /api/caja`.
2. Seleccionar caja inicial:
   - `defaultCajaId` si viene,
   - si no, primer elemento de `rows`.
3. Llamar en paralelo:
   - `GET /api/caja/:id`
   - `GET /api/caja/:id/movimientos?pagina=1&limite=20`
4. Cambiar caja en selector:
   - resetear tabla a página 1,
   - volver a pedir detalle + movimientos.

## 3.3 Tabla de movimientos
- Implementar paginación server-side.
- Al aplicar filtros, reiniciar paginación.
- Mostrar estado de pago con chips: `PENDIENTE`, `PAGADO`, `ANULADO`, `REEMPLAZADO`.

## 3.4 Acciones en movimiento
- **Regularizar**: enviar `POST /api/pagos/:id/regularizar`.
- **Corregir**: abrir formulario y enviar `POST /api/pagos/:id/corregir`.
- **Trasladar**: enviar `POST /api/pagos/:id/trasladar-caja`.

Luego de cada acción:
1. refrescar `GET /api/caja/:id` (totales/pendientes),
2. refrescar página actual de `GET /api/caja/:id/movimientos`,
3. refrescar Home si está abierto.

---

## 4) Manejo de errores en mobile

## 4.1 Cierre de caja con pendientes
Mostrar mensaje de negocio:
- “No se puede cerrar la caja porque tiene pagos pendientes”.

## 4.2 Corrección fuera de caja abierta
Mostrar mensaje:
- “Solo se puede corregir pagos cuando la caja está ABIERTA”.

## 4.3 Permisos
Si backend responde `403`, mostrar pantalla sin permisos y ocultar acciones.

---

## 5) Casos de prueba QA mobile

1. `ADMINISTRADOR`:
   - ve Home con pendientes,
   - entra a Cajas,
   - ve movimientos,
   - corrige pago en caja abierta.
2. `JEFE`:
   - puede cerrar caja sin pendientes,
   - no puede cerrar caja con pendientes.
3. `COORDINADOR`:
   - ve resumen en Home,
   - no accede a bandeja Cajas,
   - puede regularizar desde Home.
4. Rol no autorizado:
   - no ve bloque de pagos en Home,
   - no accede a Cajas.

---

## 6) Checklist de implementación

- [ ] Consumir `GET /api/caja` para selector.
- [ ] Implementar detalle con `GET /api/caja/:id`.
- [ ] Implementar tabla paginada con `GET /api/caja/:id/movimientos`.
- [ ] Implementar acción de corrección con `POST /api/pagos/:id/corregir`.
- [ ] Respetar control de rol para visibilidad de Home y módulo Cajas.
- [ ] Manejar errores de negocio (`400/403/409`) con mensajes claros.
