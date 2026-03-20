# Flujo actualizado de cierre de atención y programación de control

Este documento explica el cambio aplicado al flujo de citas cuando una cita ya fue atendida y se debe decidir entre **cerrarla definitivamente** o **programar un control**.

## 1. Resumen del cambio

Antes existía el endpoint:

- `POST /citas/:id/completar`

Ese endpoint ya no debe usarse para el flujo operativo principal.

Ahora, cuando una cita está en estado `PROGRAMADA`, el cierre de la atención tiene **dos opciones explícitas**:

1. **Dar alta**
   - Endpoint: `POST /citas/:id/dar-alta`
   - Resultado: la cita actual pasa a `COMPLETADA`.

2. **Programar control**
   - Endpoint: `POST /citas/:id/programar-control`
   - Resultado:
     - la cita actual pasa a `COMPLETADA`
     - se crea una **nueva cita** en estado `PROGRAMADA`
     - ambas citas comparten el mismo `idHistorialCita`
     - la nueva cita conserva el mismo paciente de la cita original

---

## 2. Regla de negocio actual

Cuando una cita está en `PROGRAMADA` y la atención termina, el sistema debe permitir solo uno de estos caminos:

### Opción A: dar alta

- Se usa cuando la atención termina y **no requiere un nuevo control**.
- La cita termina en `COMPLETADA`.
- No se crea otra cita.

### Opción B: programar control

- Se usa cuando la atención actual termina, pero se necesita una **nueva cita de seguimiento/control**.
- La cita actual también termina en `COMPLETADA`.
- Se crea otra cita en `PROGRAMADA`.
- El historial queda unificado para poder consultar toda la secuencia desde cualquiera de las dos citas.

---

## 3. Endpoints afectados y nuevos

## 3.1 Endpoint que deja de usarse

### `POST /citas/:id/completar`

- Se reemplaza por endpoints más explícitos.
- Motivo: ya no existe una sola acción genérica de “completar”; ahora el flujo distingue entre **dar alta** y **programar control**.

## 3.2 Endpoint nuevo: dar alta

### `POST /citas/:id/dar-alta`

Marca una cita programada como finalizada.

**Precondición:**

- la cita debe estar en estado `PROGRAMADA`

**Efecto:**

- `PROGRAMADA -> COMPLETADA`

**Body:**

- no requiere body

**Uso recomendado:**

- cuando la atención terminó y no se agenda un seguimiento inmediato

## 3.3 Endpoint nuevo: programar control

### `POST /citas/:id/programar-control`

Completa la cita actual y genera una nueva cita de control.

**Precondición:**

- la cita actual debe estar en estado `PROGRAMADA`

**Efectos dentro de una misma transacción:**

1. la cita actual pasa a `COMPLETADA`
2. se crea una nueva cita en `PROGRAMADA`
3. la cita original guarda `idCitaNueva`
4. ambas citas comparten el mismo `idHistorialCita`

**Restricción importante:**

- el paciente **no puede cambiarse** durante este flujo
- la nueva cita reutiliza el `idPaciente` de la cita original

**Campos que sí pueden cambiar en la nueva cita:**

- `detalle`
- `fechaInicio`
- `idPersonal`
- `idConsultorio`
- `idLugar`
- `tipoCita`
- `idServicio`

**Body esperado:**

```json
{
  "detalle": "Control posterior",
  "fechaInicio": "2026-03-30T14:00:00Z",
  "idPersonal": "42",
  "idConsultorio": "8",
  "idLugar": "2",
  "tipoCita": "CONSULTA",
  "idServicio": "5"
}
```

---

## 4. Cómo queda el historial

Cuando se usa `programar-control`:

- la cita original y la nueva cita quedan unidas por `idHistorialCita`
- la cita original además referencia a la nueva con `idCitaNueva`
- desde cualquiera de las dos citas se puede reconstruir la historia completa del caso

Esto permite que frontend/mobile muestre el seguimiento como una misma línea de atención y no como registros aislados.

---

## 5. Ejemplos de transición

## Caso 1: atención terminada sin seguimiento

Estado inicial:

- cita A = `PROGRAMADA`

Acción:

- `POST /citas/A/dar-alta`

Resultado:

- cita A = `COMPLETADA`

## Caso 2: atención terminada con nuevo control

Estado inicial:

- cita A = `PROGRAMADA`

Acción:

- `POST /citas/A/programar-control`

Resultado:

- cita A = `COMPLETADA`
- cita B = `PROGRAMADA`
- cita A.`idCitaNueva` = cita B.id
- cita A.`idHistorialCita` = cita B.`idHistorialCita`
- cita B conserva el mismo paciente de cita A

---

## 6. Recomendaciones para frontend y mobile

- Reemplazar cualquier uso de `POST /citas/:id/completar` por:
  - `POST /citas/:id/dar-alta`, o
  - `POST /citas/:id/programar-control`
- En la UI de una cita `PROGRAMADA`, mostrar dos acciones separadas:
  - **Dar alta**
  - **Programar control**
- Para `programar-control`, reutilizar los datos actuales de la cita como base del formulario, bloqueando edición del paciente.
- Después de programar control, refrescar la cita actual y también insertar/actualizar la nueva cita en listados y timeline.

---

## 7. Matriz resumida del flujo afectado

- `PROGRAMADA -> COMPLETADA` con `POST /citas/:id/dar-alta`
- `PROGRAMADA -> COMPLETADA` + nueva `PROGRAMADA` con `POST /citas/:id/programar-control`
