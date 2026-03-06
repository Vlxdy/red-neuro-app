# Migración de identificadores en Citas: `idMedico` / `idPersonalSalud` -> `idPersonal`

Este documento resume los cambios para sincronizar Backend, Frontend y App Móvil.

## Cambios de contrato

- Nuevo nombre estándar: `idPersonal`.
- Se reemplazó `idMedico` y `idPersonalSalud` por `idPersonal` en query, request y response del módulo de citas.
- En historial, el campo de cambio ahora usa `idPersonal`.

## Endpoints con cambios en Query Params

- `GET /citas`: `idPersonal`
- `GET /citas/paginado`: `idPersonal`
- `GET /citas/cantidad-por-dia`: `idPersonal`
- `GET /citas/mis-citas` (deprecated): usa `idPersonal` internamente.

## Endpoints con cambios en Request Body

- `POST /citas`: `idPersonal`
- `PATCH /citas/:id/editar-borrador`: `idPersonal`
- `POST /citas/:id/enviar`: `idPersonal`

## Endpoints con cambios en Response Body

- Respuesta de cita (`CitaResponseDto`): `idPersonal` y `personal`
- Cita nueva por reprogramación (`CitaNuevaDetalleDto`): `idPersonal` y `personal`
- Notificaciones tipadas (`NotificacionResponse`): `idPersonal` y `personal`

## Historial

- `detalleCambios[].field`:
  - antes: `idMedico` / `idPersonalSalud`
  - ahora: `idPersonal`

## Nota de implementación (backend)

- La entidad `Cita` y `Notificacion` ahora exponen propiedades `idPersonal` y relación `personal`.
- La columna en base de datos se mantiene como `id_medico` para evitar una migración destructiva en esta entrega.

## Checklist Frontend/App

1. Reemplazar uso de `idMedico` y `idPersonalSalud` por `idPersonal`.
2. Reemplazar `medico`/`medicoId` por `personal`/`idPersonal` en modelos y mappers.
3. Actualizar lógica de historial para `detalleCambios.field === 'idPersonal'`.
