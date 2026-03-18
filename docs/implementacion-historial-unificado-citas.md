# Implementación técnica: historial unificado de citas reprogramadas

Este documento describe cómo implementar en backend el historial unificado de citas usando `idHistorialCita`.

## Objetivo
- Todas las citas de una misma cadena de reprogramación deben compartir un único historial visible.
- Mantener trazabilidad por cita individual (`idCita`) para auditoría.

## Cambios aplicados en backend

## 1) Persistencia del agrupador en historial
Se agrega `idHistorialCita` en la entidad `HistorialCita` para guardar el agrupador de cadena también a nivel de evento.

## 2) Enriquecimiento automático en escritura
`HistorialCitasRepository` ahora:
- resuelve `idHistorialCita` desde `citas` cuando no llega explícitamente,
- lo aplica tanto en `crearHistorial` como en `crearHistoriales`.

Con esto, cualquier flujo que ya escribía historial por `idCita` queda alineado sin refactors masivos.

## 3) Lectura unificada con fallback legado
La consulta del historial cambia a:
1. buscar `idHistorialCita` de la cita consultada,
2. si existe, listar por `historial.idHistorialCita`,
3. si no existe, fallback por `historial.idCita`.

Además, se ordena por `fechaCreacion DESC, id DESC` para paginación estable.

## 4) Reprogramación con propagación garantizada
En `reprogramarCita`:
- se garantiza `historialCitaId` para la cita origen (si no tenía, se genera),
- la nueva cita hereda ese mismo identificador.

Resultado: consultar historial desde la cita original o cualquiera de sus reprogramaciones devuelve la misma cadena.

## 5) Contrato de respuesta de historial
Se expone también `historialCitaId` en cada item del historial para que clientes (web/mobile) puedan:
- reconocer agrupación,
- cachear por cadena,
- mostrar indicadores de continuidad entre citas.

---

## Cambios de base de datos recomendados
> Si el ambiente no usa migraciones automáticas, ejecutar SQL equivalente manualmente.

```sql
ALTER TABLE historial_citas
ADD COLUMN IF NOT EXISTS id_historial_cita varchar(100);

CREATE INDEX IF NOT EXISTS idx_historial_citas_historial_fecha
ON historial_citas (id_historial_cita, fecha_creacion DESC, id DESC);
```

## Backfill recomendado
```sql
UPDATE historial_citas hc
SET id_historial_cita = c.id_historial_cita
FROM citas c
WHERE hc.id_cita = c.id
  AND hc.id_historial_cita IS NULL
  AND c.id_historial_cita IS NOT NULL;
```

Para citas legadas sin `citas.id_historial_cita`, generar un id por cita y replicarlo a su historial.

---

## Plan de despliegue sugerido
1. Desplegar código + columna + índice.
2. Ejecutar backfill.
3. Monitorear porcentaje de eventos con `id_historial_cita` no nulo.
4. Opcional: endurecer `NOT NULL` cuando la cobertura sea 100%.

## Validación funcional rápida
1. Crear cita A, revisar historial (1 cadena).
2. Reprogramar A -> B.
3. Consultar `GET /citas/A/historial` y `GET /citas/B/historial`.
4. Verificar mismo total y mismos eventos (ordenados igual).
