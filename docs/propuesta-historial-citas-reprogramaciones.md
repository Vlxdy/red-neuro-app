# Propuesta detallada — Opción A: historial unificado por `idHistorialCita`

## 1) Contexto y problema
Hoy el historial se consulta por `idCita`. Cuando una cita se reprograma se crea una nueva fila en `citas`, por lo que la trazabilidad queda fragmentada en múltiples historiales, aun cuando funcionalmente se trata del mismo proceso.

La meta es que **todas las citas vinculadas por reprogramación compartan una sola línea de tiempo**, sin perder el detalle de en cuál cita ocurrió cada evento.

---

## 2) Decisión de diseño
Adoptar **Opción A**: usar `idHistorialCita` como identificador de agrupación lógica (cadena de cita original + reprogramaciones).

En el modelo actual ya existe `citas.idHistorialCita`; la propuesta extiende ese concepto para que también se persista y consulte en `historial_citas`.

### Principio clave
- `idCita` = identidad de la instancia puntual de cita.
- `idHistorialCita` = identidad del proceso longitudinal de atención/agenda.

---

## 3) Comportamiento funcional esperado

## 3.1 Alta de cita (no reprogramación)
1. Se crea la cita.
2. Si no existe `idHistorialCita`, se genera (UUID recomendado).
3. Todos los eventos de historial de esa cita guardan ese `idHistorialCita`.

## 3.2 Reprogramación de cita
1. La cita origen (`citaA`) cambia a estado de reprogramada (o equivalente).
2. Se crea la nueva cita (`citaB`).
3. `citaB.idHistorialCita = citaA.idHistorialCita`.
4. Los eventos de ambas (`citaA`, `citaB`) se guardan con el mismo `idHistorialCita`.
5. Al consultar historial desde cualquier cita de la cadena, se devuelve el mismo conjunto de eventos.

## 3.3 Consulta de historial
- Entrada: `GET /citas/:id/historial`.
- Resolución:
  1. Buscar cita `:id`.
  2. Si tiene `idHistorialCita`, consultar historial por ese campo.
  3. Si no tiene (dato legado), fallback por `idCita = :id`.
- Salida: eventos ordenados de forma estable (fecha + id), con paginación consistente.

---

## 4) Impacto por capa (qué afectaría)

## 4.1 Base de datos

### Cambios de esquema
1. `historial_citas`
   - Agregar columna `id_historial_cita` (`varchar(100)` o UUID según estándar del proyecto).
   - Mantener `id_cita` (no se elimina).

2. Índices
   - Índice principal de consulta:
     - `(id_historial_cita, fecha_creacion DESC, id DESC)` para timeline paginable.
   - Opcional: índice de compatibilidad legado por `id_cita` si aún hay consumo viejo.

3. Integridad recomendada
   - Validar no nulo en nuevos registros de historial (después de backfill).
   - Regla operativa: toda cita nueva/reprogramada debe portar `idHistorialCita`.

### Migración de datos (backfill)
- Objetivo: completar `historial_citas.id_historial_cita` para registros antiguos.
- Fuente:
  - unir `historial_citas.id_cita -> citas.id` y copiar `citas.id_historial_cita`.
- Casos sin valor:
  - generar uno por cita aislada antigua y actualizar tanto `citas` como su historial.

---

## 4.2 Dominio / entidades

## Entidad `Cita`
- Ya contiene `idHistorialCita`.
- Reforzar regla en creación/reprogramación para que siempre se propague/establezca.

## Entidad `HistorialCita`
- Agregar campo `idHistorialCita`.
- Mantener `idCita` para auditoría fina.

---

## 4.3 Repositorios y consultas

## Escritura de historial
Cada operación que crea historial debe incluir:
- `idCita` (evento puntual)
- `idHistorialCita` (agrupador de cadena)

## Lectura de historial
Refactor de consulta actual:
- Antes: `WHERE historial.idCita = :idCita`
- Después:
  1. Resolver `idHistorialCita` desde cita consultada.
  2. `WHERE historial.idHistorialCita = :idHistorialCita`
  3. fallback legado si no existe.

## Orden recomendado
`ORDER BY historial.fechaCreacion DESC, historial.id DESC`
(estable para paginación aunque haya timestamps repetidos).

---

## 4.4 Servicios de negocio

## Servicio de creación de cita
- Si llega `idHistorialCita` usarlo.
- Si no llega, generar uno y persistir.

## Servicio de reprogramación
- Heredar `idHistorialCita` de cita origen en la nueva cita.
- Registrar eventos de ambas citas con el mismo agrupador.

## Servicio/listado de historial
- Convertir endpoint actual para devolver historial unificado sin romper contrato externo.

---

## 4.5 API y contrato de respuesta

## Endpoint
`GET /citas/:id/historial`

## Query params sugeridos
- `fechaInicio`
- `fechaFin`
- `idEjecutor`
- `limite`
- `saltar` (o cursor si evolucionan a cursor pagination)

## Respuesta sugerida
```json
{
  "idHistorialCita": "HIST-abc123",
  "total": 47,
  "items": [
    {
      "idHistorial": "9001",
      "fechaCreacion": "2026-01-05T14:30:00.000Z",
      "accion": "CITA_REPROGRAMADA",
      "idCita": "120",
      "idCitaOrigen": "118",
      "idCitaDestino": "120",
      "ejecutor": { "id": "44", "nombre": "Dr. X" },
      "payload": { "motivo": "Choque de agenda" }
    }
  ]
}
```

Notas:
- `idCita` en cada item permite saber en qué iteración ocurrió la acción.
- `idHistorialCita` en cabecera confirma que todo pertenece a la misma cadena.

---

## 5) Compatibilidad y transición

## Estrategia sin ruptura (backward compatible)
1. Desplegar columna nueva e índices.
2. Escribir `id_historial_cita` en nuevos eventos.
3. Leer prioritariamente por `id_historial_cita` con fallback legado.
4. Ejecutar backfill.
5. Cuando cobertura de backfill sea 100%, endurecer validaciones (no nulo).

## Manejo de legado
- Si una cita antigua no tiene `idHistorialCita`, se considera cadena de 1 elemento.
- El usuario no pierde visibilidad de historial previo.

---

## 6) Riesgos y mitigaciones

1. **Riesgo: cadenas incompletas por datos históricos faltantes**
   - Mitigación: script de backfill idempotente + reporte de órfanos.

2. **Riesgo: duplicidad/colisiones de identificador**
   - Mitigación: UUID v4 o convención con alta entropía.

3. **Riesgo: paginación inestable**
   - Mitigación: orden secundario por `id`.

4. **Riesgo: degradación de performance**
   - Mitigación: índice compuesto y pruebas con volúmenes reales.

---

## 7) Observabilidad y auditoría

- Métricas:
  - % de eventos con `id_historial_cita` no nulo.
  - latencia p95 del endpoint de historial.
  - cantidad de consultas fallback legado.
- Logs de negocio:
  - en reprogramación, registrar `{idCitaOrigen, idCitaNueva, idHistorialCita}`.
- Alertas:
  - si se intenta crear historial sin `idHistorialCita` en flujo nuevo.

---

## 8) Plan de implementación (sprint-friendly)

### Fase 1 — Persistencia base
- Migración schema (`historial_citas.id_historial_cita` + índices).
- Ajustar entidad y repositorio de historial.

### Fase 2 — Escritura correcta
- Forzar generación/propagación de `idHistorialCita` en creación y reprogramación.
- Garantizar que todos los eventos nuevos lo persistan.

### Fase 3 — Lectura unificada
- Cambiar consulta del endpoint para leer por agrupador.
- Mantener fallback por `idCita`.

### Fase 4 — Backfill y hardening
- Ejecutar script histórico.
- Revisar métricas.
- Hacer `NOT NULL` (si aplica) y retirar código de transición cuando sea seguro.

---

## 9) Casos de prueba funcional mínimos
1. **Cita simple sin reprogramación**
   - Debe mostrar historial normal con un único `idHistorialCita`.
2. **Una reprogramación**
   - Consultando desde cita original y nueva debe verse exactamente el mismo timeline.
3. **Múltiples reprogramaciones encadenadas**
   - Deben agregarse todos los eventos en orden estable.
4. **Legado sin `idHistorialCita`**
   - Debe funcionar fallback por `idCita`.
5. **Filtros + paginación**
   - `total`, `limite`, `saltar` y orden deben ser consistentes.

---

## 10) Resultado esperado
Con este diseño, la reprogramación deja de “romper” la trazabilidad: el usuario verá una sola historia clínica/operativa de la cita, mientras el sistema conserva la granularidad de cada instancia para auditoría y análisis.
