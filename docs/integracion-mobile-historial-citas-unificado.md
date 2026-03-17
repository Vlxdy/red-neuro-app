# Guía Mobile: consumo de historial unificado de citas

Este documento explica cómo aplicar en app móvil el historial unificado cuando existen reprogramaciones.

## Qué cambia para mobile
El endpoint `GET /citas/:id/historial` mantiene su contrato base, pero ahora cada ítem puede incluir:
- `historialCitaId`: identificador compartido de toda la cadena.

Además, al consultar por cualquier cita reprogramada de la cadena, el backend devuelve el mismo timeline.

## Recomendaciones de implementación en app

## 1) Modelo local
Agregar campo opcional en el modelo de historial:
- `historialCitaId?: string`

Y conservar:
- `citaId` (evento puntual),
- `fechaCreacion`,
- `comentario`,
- `detalleCambios`, etc.

## 2) Estrategia de cache
- Cachear historial por clave:
  - preferido: `historialCitaId`,
  - fallback: `citaId` cuando no exista `historialCitaId` (legado).

Ejemplo de key:
- `historial:${historialCitaId ?? citaId}`

## 3) UI/UX sugerida
- Título: **Historial de la cita** (sin diferenciar por intento).
- Subetiqueta opcional por evento: “Cita #<citaId>” para auditoría.
- Orden descendente por fecha (ya viene del backend).

## 4) Deep links y navegación
Si se abre detalle desde una cita reprogramada:
- usar su `id` actual para la consulta,
- confiar en backend para unificar eventos.

No es necesario resolver cadenas en cliente.

## 5) Manejo de compatibilidad
En versiones de transición:
- si no llega `historialCitaId`, seguir renderizando normal por lista recibida,
- no bloquear UI por ausencia del nuevo campo.

## 6) Analítica recomendada
Registrar eventos:
- `historial_opened` con `citaId` y `historialCitaId` (si existe).
- `historial_item_tapped` con `citaId` del item.

Esto permite medir adopción del historial unificado.

---

## Checklist de QA mobile
1. Abrir historial de cita sin reprogramación.
2. Abrir historial de cita original reprogramada.
3. Abrir historial de la cita nueva reprogramada.
4. Confirmar que (2) y (3) muestran mismo total y mismos eventos.
5. Confirmar que app no falla si `historialCitaId` no viene (dato antiguo).

## Ejemplo de tipado (TypeScript)
```ts
type HistorialItem = {
  id: string;
  citaId: string;
  historialCitaId?: string;
  idEjecutor: string;
  comentario?: string;
  fechaCreacion: string;
  detalleCambios?: Array<{
    field: string;
    before?: string;
    after?: string;
  }>;
};
```
