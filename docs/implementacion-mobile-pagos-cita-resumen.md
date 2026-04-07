# Guía mobile: pagos con cita resumida (rutas existentes)

## Endpoints a consumir (sin rutas nuevas)

- Home: `GET /citas/home/pagos-pendientes`
- Caja: `GET /caja/:id/movimientos`
- Pendientes: `GET /pagos/pendientes`
- Pagos por cita: `GET /citas/:id/pagos`

Todos se alinean al formato de `PagoConCitaResumenDto`.

---

## Orden visual recomendado

1. Estado + monto.
2. Método + fecha.
3. Registrado por.
4. Resumen de cita (detalle, fecha, paciente, personal, servicio, tipo).
5. Acción “Ver cita completa” -> `GET /citas/:id`.

---

## Modelo TS de referencia

```ts
export interface PagoConCitaResumenDto {
  id: string
  monto: number
  estadoPago: string
  metodoPago?: string
  tipoMovimiento: string
  fechaPago?: string
  observacion?: string
  usuarioRegistro: {
    id: string
    nombreCompleto?: string
  }
  cita: {
    id: string
    detalle: string
    fechaInicio: string
    fechaFin: string
    estado: string
    tipoCita: string
    paciente?: { id: string; nombreCompleto?: string }
    personal?: { id: string; nombreCompleto?: string }
    servicio?: { id: string; nombre: string }
  }
}
```
