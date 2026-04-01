# Implementación mobile: historial paginado de citas por paciente

Esta guía describe cómo consumir el nuevo endpoint backend:

- `GET /pacientes/:id/citas`

El endpoint devuelve **todas** las citas del paciente ordenadas de la más reciente a la más antigua, con paginación y filtros.

## 1) Parámetros soportados

Path params:

- `id`: identificador del paciente.

Query params:

- `limite` (number, opcional, default backend).
- `pagina` (number, opcional, default backend).
- `fechaInicioDesde` (ISO string, opcional).
- `fechaInicioHasta` (ISO string, opcional).
- `estado` (opcional): `SOLICITADA | PROGRAMADA | ...`.
- `tipoCita` (opcional): `CONSULTA | ESTUDIO`.
- `idPersonal` (opcional).
- `idLugar` (opcional).

### Regla especial para `PROFESIONAL_INVITADO`

- El backend **ignora** el filtro `idPersonal`.
- Solo devuelve citas donde `idPersonal` coincide con el usuario autenticado.

## 2) Ejemplo de request

```http
GET /pacientes/145/citas?pagina=1&limite=20&estado=PROGRAMADA&fechaInicioDesde=2026-01-01T00:00:00Z
Authorization: Bearer <token>
```

## 3) Ejemplo de respuesta

```json
{
  "finalizado": true,
  "mensaje": "Transacción exitosa",
  "datos": {
    "filas": [
      {
        "id": "915",
        "detalle": "Control mensual",
        "fechaInicio": "2026-03-28T14:00:00.000Z",
        "fechaFin": "2026-03-28T14:30:00.000Z",
        "estado": "PROGRAMADA",
        "tipoCita": "CONSULTA",
        "idPersonal": "42",
        "pacienteId": "145"
      }
    ],
    "total": 57
  }
}
```

## 4) Recomendación de implementación (React Native / TypeScript)

```ts
type FiltrosCitasPaciente = {
  pagina?: number
  limite?: number
  fechaInicioDesde?: string
  fechaInicioHasta?: string
  estado?: string
  tipoCita?: 'CONSULTA' | 'ESTUDIO'
  idPersonal?: string
  idLugar?: string
}

export async function obtenerCitasPaciente(
  idPaciente: string,
  filtros: FiltrosCitasPaciente,
  token: string
) {
  const query = new URLSearchParams()
  Object.entries(filtros).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      query.append(key, String(value))
    }
  })

  const res = await fetch(
    `${API_URL}/pacientes/${idPaciente}/citas?${query.toString()}`,
    {
      headers: { Authorization: `Bearer ${token}` },
    }
  )

  if (!res.ok) {
    throw new Error('No se pudo obtener el listado de citas del paciente')
  }

  return await res.json()
}
```

## 5) Paginación infinita en app

1. Cargar primera página con `pagina=1`.
2. Guardar `total` y cantidad acumulada de `filas`.
3. Si `acumuladas < total`, pedir `pagina + 1`.
4. Al cambiar filtros, reiniciar lista y volver a `pagina=1`.
