# Guía de implementación frontend para reservas de citas

Esta guía resume los componentes y flujos necesarios en el frontend para soportar la reserva de citas por parte de pacientes y la gestión por nutricionistas.

## Arquitectura de componentes

- **Agenda del paciente** (`PatientAppointmentsPage`)
  - Muestra calendario/lista de citas segmentado por estado.
  - Permite crear nueva cita y acceder al detalle.
- **Agenda administrativa** (`StaffSchedulerPage`)
  - Disponible para nutricionistas y administradores.
  - Permite crear citas confirmadas directamente, reprogramar aprobadas y visualizar la disponibilidad global.
- **Editor de cita** (`AppointmentForm`)
  - Formularios dinámicos para crear/editar citas en estados `BORRADOR` y `RECHAZADA`.
  - Validación de disponibilidad (consultar endpoint de disponibilidad si existe).
- **Detalle de cita** (`AppointmentDetailDrawer`)
  - Resumen de información y acciones disponibles según el estado y el rol activo.
  - Incluye timeline de historial, comentarios y recordatorio de los límites de modificación restantes.
- **Historial de cambios** (`AppointmentHistoryModal`)
  - Lista cronológica de eventos con avatar/rol y comentario.

## Gestión de estado (front)

- Recomendado usar un store centralizado (`Redux Toolkit` o `Zustand`) para manejar:
  - `appointments`: listado por estado y metadatos de paginación.
  - `selectedAppointment`: detalle e historial cargados bajo demanda.
  - `ui`: indicadores de carga y mensajes.
- Normalizar las citas por `id` para facilitar actualizaciones parciales tras cada operación.

## Flujo del paciente

1. **Crear cita**
   - Acción: botón "Nueva cita".
   - Llama a `POST /pacientes/:id/citas`.
   - Mostrar feedback de éxito y redirigir al formulario en modo edición (`BORRADOR`).
2. **Editar y enviar a revisión**
   - Guardado automático (PATCH) para cambios en `BORRADOR`, mostrando contador de modificaciones disponibles.
   - Botón "Enviar a revisión" ejecuta `POST /citas/:id/enviar` y bloquea campos.
   - Si el paciente desea ajustar después de enviar, debe usar la acción "Volver a borrador" hasta un máximo de dos veces cada 7 días.
3. **Revisar rechazo**
   - Si el backend responde con estado `RECHAZADA`, mostrar banner con el comentario del nutricionista y el contador de reprogramaciones restantes.
   - Acciones disponibles: "Editar propuesta" (retorna a `BORRADOR`, descontando un intento) o "Cancelar cita" (`POST /citas/:id/cancelar`).
4. **Cancelar cita**
   - Disponible en `BORRADOR`, `SOLICITADA` y `RECHAZADA`.
   - Confirmación modal para prevenir cancelaciones accidentales.
5. **Cita aprobada**
   - Estado `CONFIRMADA` bloquea los inputs.
   - Mostrar CTA para agregar a calendario externo (opcional) y botón de "Cancelar" solo si políticas lo permiten (hasta 24h antes).
   - Indicar que cambios posteriores requieren contactar a soporte/nutricionista.

## Flujo del nutricionista

1. **Bandeja de pendientes**
   - Componente `PendingAppointmentsList` que consume `GET /nutricionistas/:id/citas?estado=SOLICITADA`.
   - Permite filtrar por fecha y paciente.
2. **Aprobar cita**
   - Botón "Aprobar" ejecuta `POST /citas/:id/aprobar`.
   - Actualiza estado en store y dispara notificación por correo/push al paciente.
3. **Rechazar cita**
   - Modal para capturar comentario obligatorio.
   - Acción `POST /citas/:id/rechazar`.
   - Tras rechazo, remover de bandeja, notificar al paciente y actualizar los contadores de intentos permitidos.
4. **Crear cita confirmada**
   - Botón "Nueva cita confirmada" disponible en `StaffSchedulerPage` ejecuta `POST /profesionales/:id/citas/confirmada`.
   - El formulario debe solicitar fecha, hora, paciente, notas y enviar notificaciones al paciente.
5. **Reprogramar cita aprobada**
   - Acción `POST /citas/:id/reprogramar`.
   - Requiere comentario obligatorio que se muestra al paciente.
   - Debe actualizar el historial y disparar notificaciones a ambas partes.
6. **Historial**
   - Acceso al mismo componente `AppointmentHistoryModal` reutilizable.

## Manejo del historial

- Llamar a `GET /citas/:id/historial` al abrir el detalle.
- Presentar cada item con:
  - Estado anterior → nuevo.
  - Usuario y rol que ejecutó la acción.
  - Fecha en formato legible.
  - Comentario si existe.
- Permitir paginación (cargar más) en historiales extensos.

## Estados y permisos en UI

| Estado       | Paciente                                                                              | Nutricionista                                 | Administrador                                                   |
| ------------ | ------------------------------------------------------------------------------------- | --------------------------------------------- | --------------------------------------------------------------- |
| `BORRADOR`   | Editar, cancelar, enviar (mostrar contador de reversiones disponibles cuando aplique) | Visualizar                                    | Visualizar                                                      |
| `SOLICITADA` | Ver, cancelar, volver a borrador (máx. 2 veces/7 días)                                | Aprobar, rechazar, volver a borrador          | Aprobar, rechazar, volver a borrador                            |
| `CONFIRMADA` | Ver, cancelar (hasta 24h antes)                                                       | Ver, reprogramar (hasta 2h antes), cancelar   | Ver, reprogramar/cancelar sin restricción (requiere comentario) |
| `RECHAZADA`  | Editar (restando intentos), cancelar                                                  | Ver historial, enviar comentarios adicionales | Ver historial, reabrir                                          |
| `CANCELADA`  | Ver historial                                                                         | Ver historial                                 | Ver historial                                                   |
| `COMPLETADA` | Ver historial                                                                         | Ver historial                                 | Ver historial                                                   |

## Requerimientos de UX

- Mostrar toasts/mensajes claros tras cada acción.
- Diferenciar visualmente los estados (colores, etiquetas).
- Incluir validaciones de fecha y hora con límites mínimos (ej. 24h de anticipación si aplica).
- Proveer accesibilidad (etiquetas ARIA, navegación por teclado).

## Manejo de errores

- HTTP 400: mostrar mensajes específicos (validaciones).
- HTTP 403/409: indicar que la cita cambió de estado y refrescar datos.
- HTTP 500: fallback con reintento y soporte.

## Integración con notificaciones

- Suscribirse a canal de notificaciones (websocket o polling) para actualizar la UI en tiempo real cuando el nutricionista aprueba/rechaza, cuando se reprograma una cita o cuando se crea una cita confirmada.
- Mostrar toasts diferenciados para correo enviado y notificación en-app.
- Registrar en el historial los mismos mensajes enviados por correo para mantener consistencia.

## Pruebas sugeridas

- Unit tests para componentes críticos (`AppointmentForm`, `AppointmentHistoryModal`).
- Pruebas e2e simulando el flujo completo del paciente.
- Testear formatos de fecha en distintos husos horarios.
