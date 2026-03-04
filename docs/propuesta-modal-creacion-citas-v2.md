# Propuesta UX/UI: creación de citas en formulario único + confirmación simplificada

## 1) Problema detectado en el flujo actual

El flujo paso a paso para crear una cita agrega fricción cuando la mayoría de los usuarios ya sabe qué información necesita ingresar. Además, los submodales de confirmación al final fragmentan la experiencia y generan dudas sobre:

- qué datos se están confirmando exactamente,
- si la cita ya fue creada o todavía no,
- qué acción sigue después de confirmar.

Resultado: mayor tiempo por operación, más clics y menor claridad en un proceso frecuente.

---

## 2) Objetivo de la propuesta

Reducir tiempo y esfuerzo para crear una cita, pasando de un wizard a un **formulario completo en una sola vista**, con validaciones en línea y un **cierre de flujo en una sola confirmación clara**.

Objetivos concretos:

1. Disminuir el número de interacciones para crear una cita.
2. Hacer visible todo el contexto de la cita antes de guardar.
3. Eliminar ambigüedad de estados al final del proceso.
4. Mantener seguridad con validaciones y confirmación explícita.

---

## 3) Flujo propuesto (alto nivel)

1. Usuario toca **“Nueva cita”**.
2. Se abre modal ancho (o pantalla completa en móvil) con formulario completo.
3. Usuario completa campos en cualquier orden.
4. Validaciones se muestran por campo en tiempo real.
5. Al presionar **“Crear cita”**, se muestra **un solo diálogo de confirmación-resumen**.
6. Confirmar → crear cita → feedback de éxito con CTA principal.

Sin submodales encadenados.

---

## 4) Estructura recomendada del formulario único

### Sección A: Paciente
- Paciente (autocomplete obligatorio)
- Documento / identificación (autocompletado y solo lectura si ya existe)
- Teléfono de contacto (editable)

### Sección B: Atención
- Especialidad (obligatorio)
- Profesional (obligatorio, filtrado por especialidad)
- Tipo de cita (primera vez / control / otro)
- Motivo breve (opcional con límite de caracteres)

### Sección C: Fecha y lugar
- Fecha (obligatorio)
- Horario (obligatorio; slots disponibles)
- Sede / lugar (obligatorio)
- Modalidad (presencial / teleconsulta)

### Sección D: Configuración adicional
- Prioridad (normal / preferente)
- Notificar por (WhatsApp / SMS / correo)
- Observaciones internas (opcional)

### Footer fijo del modal
- Botón secundario: **Cancelar**
- Botón terciario (si aplica): **Limpiar**
- Botón principal: **Crear cita** (deshabilitado hasta mínimos obligatorios válidos)

---

## 5) Confirmación simplificada (sin submodales)

Reemplazar múltiples submodales por una sola capa de confirmación tipo “Review + Confirm”:

**Título:** Confirmar creación de cita

**Resumen visible:**
- Paciente
- Especialidad y profesional
- Fecha, hora y sede
- Modalidad
- Notificación

**Acciones:**
- Secundaria: Volver a editar
- Primaria: Confirmar y crear

Reglas:
- No abrir más diálogos encima.
- Si hay conflicto de agenda al confirmar, mostrar error contextual en el mismo modal con opción de elegir otro horario.

---

## 6) Estados y mensajes UX

### Validaciones en línea
- Campo requerido vacío: “Este campo es obligatorio”.
- Horario no disponible: “Ese horario ya no está disponible, elige otro”.
- Profesional sin agenda ese día: sugerir próxima fecha automáticamente.

### Estado loading
- En botón principal: “Creando cita…” + spinner.
- Bloqueo temporal para evitar doble envío.

### Estado éxito
- Toast + mensaje en modal: “Cita creada correctamente”.
- CTAs:
  - “Ver detalle de cita” (principal)
  - “Crear otra cita” (secundario)

### Estado error
- Mensaje claro, sin códigos técnicos.
- Acción recuperable: “Reintentar”.

---

## 7) Orden visual recomendado (para velocidad)

Priorizar los campos en el orden natural de decisión:

1. Paciente
2. Especialidad
3. Profesional
4. Fecha
5. Horario
6. Lugar/modalidad
7. Opcionales

Esto reduce scroll mental y minimiza correcciones posteriores.

---

## 8) Reglas de negocio sugeridas (MVP)

1. Fecha no puede ser anterior a hoy.
2. Horarios dependen de profesional + sede + fecha.
3. Si cambia profesional, limpiar horario seleccionado.
4. Si cambia fecha, recalcular disponibilidad.
5. Confirmación solo habilitada cuando datos críticos estén válidos.

---

## 9) Métricas para validar mejora

Comparar antes vs después durante 2-4 semanas:

- Tiempo promedio de creación de cita.
- Tasa de abandono en modal.
- Errores por validación al guardar.
- Reintentos por conflicto de agenda.
- Satisfacción cualitativa de usuarios internos.

Meta inicial sugerida:
- -25% tiempo promedio.
- -30% abandono del flujo.

---

## 10) Plan de implementación incremental

### Fase 1 (rápida)
- Mantener backend actual.
- Reemplazar UI stepper por formulario único.
- Unificar confirmación en un solo diálogo.

### Fase 2
- Mejoras de autocompletado y disponibilidad en tiempo real.
- Atajos para “Crear otra cita con mismos datos base”.

### Fase 3
- Experimentos A/B (si aplica) con variantes de layout.

---

## 11) Recomendación final

La mejor alternativa para este caso es migrar a **formulario completo con validación en línea + única confirmación de resumen**, porque mejora velocidad operativa sin perder control ni seguridad.

En procesos administrativos repetitivos (como agendar citas), esta estructura suele ser más eficiente y más fácil de aprender que un wizard por pasos, especialmente para usuarios frecuentes.
