# Propuesta aplicada: formateo único de pagos (sin agregar endpoints)

## Decisión

Se aplicó el formateo unificado de pagos **sobre endpoints existentes**, sin crear rutas nuevas.

Endpoints actualizados con el formato unificado:

- `GET /citas/home/pagos-pendientes`
- `GET /caja/:id/movimientos`
- `GET /pagos/pendientes`
- `GET /citas/:id/pagos`

---

## Estructura unificada implementada

Se usa:

- `PagoConCitaResumenDto`
- `CitaResumenPagoDto`

Orden del payload:

1. Bloque de pago.
2. Bloque de cita resumida.

```json
{
  "id": "pago-123",
  "monto": 120.5,
  "estadoPago": "PAGADO",
  "metodoPago": "QR",
  "tipoMovimiento": "PAGO",
  "fechaPago": "2026-04-06T14:31:00.000Z",
  "observacion": "Pago en caja",
  "usuarioRegistro": {
    "id": "21",
    "nombreCompleto": "Lic. Carla Gómez"
  },
  "cita": {
    "id": "cita-456",
    "detalle": "Control nutricional",
    "fechaInicio": "2026-04-06T14:00:00.000Z",
    "fechaFin": "2026-04-06T14:30:00.000Z",
    "estado": "COMPLETADA",
    "tipoCita": "CONSULTA",
    "paciente": { "id": "88", "nombreCompleto": "María Pérez" },
    "personal": { "id": "42", "nombreCompleto": "Dr. Juan Rojas" },
    "servicio": { "id": "5", "nombre": "Consulta medicina interna" }
  }
}
```

---

## Envoltura de listado

La salida de listados queda en:

```json
{
  "finalizado": true,
  "mensaje": "Listado exitoso.",
  "datos": {
    "total": 100,
    "filas": ["PagoConCitaResumenDto"]
  }
}
```

---

## Regla importante aplicada

- `usuarioRegistro` se mapea con `formatearUsuarioComoPersonal(...)` para devolver persona completa y no solo ID.

---

## Uso esperado en frontend/mobile

1. Reutilizar una sola tarjeta de pago.
2. Mostrar primero datos de pago y luego resumen de cita.
3. Al necesitar detalle completo, usar `GET /citas/:id`.
