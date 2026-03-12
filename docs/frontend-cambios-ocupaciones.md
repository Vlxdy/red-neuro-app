# Cambios para frontend: ocupaciones y citas

Este documento resume los cambios necesarios en frontend tras la refactorización de **especialidades** a **ocupaciones**.

## 1) Catálogo de ocupaciones

Rutas actuales:

- `/api/ocupaciones`
- `/admin/ocupaciones`

### Cambios en payload de ocupaciones

- Se mantiene: `id`, `nombre`, `descripcion`, `grado`, `estado`, `servicios`.
- Se elimina: `colorHex`.

## 2) Citas

Las citas **ya no tienen vínculo directo con ocupación**.

### Request de crear/editar cita

- Ya no se envía `idEspecialidad` (ni `idOcupacion`).

### Response de cita

- Ya no retorna `especialidadId` / `especialidad`.
- La respuesta se centra en `personal`, `paciente`, `servicio`, `consultorio`, `lugar`.

## 3) Personal de salud y servicios

La ocupación sí continúa en:

- Personal de salud: `idOcupaciones` y `ocupaciones`.
- Servicios: `ocupacionIds` y `ocupaciones`.

## 4) Checklist de migración

- [ ] Quitar `colorHex` de formularios/modelos de ocupaciones.
- [ ] Quitar selector de ocupación en pantallas de citas.
- [ ] No enviar `idEspecialidad` al crear/editar cita.
- [ ] Dejar de leer `especialidadId`/`especialidad` en respuestas de cita.
- [ ] Usar `idOcupaciones` en personal y `ocupacionIds` en servicios.
