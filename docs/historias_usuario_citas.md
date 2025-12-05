# SISTEMA DE GESTIÓN DE CITAS MÉDICAS  
## Historias de Usuario, Criterios de Aceptación y Endpoints

---

# 🧩 1. HISTORIAS DE USUARIO – ADMINISTRADOR

## HU-ADM-01 — Registrar usuarios
**Como** administrador  
**Quiero** registrar nuevos usuarios  
**Para** permitir acceso al sistema según rol.

### Criterios de aceptación
- Email único obligatorio.  
- Roles permitidos: ADMIN, SUPERVISOR, MEDICO.  
- Debe poder activar/desactivar usuarios.  

### Endpoints
- POST /usuarios  
- PATCH /usuarios/:id  
- PATCH /usuarios/:id/desactivar  

---

## HU-ADM-02 — Gestionar etiquetas
**Como** administrador  
**Quiero** crear, editar y eliminar etiquetas  
**Para** clasificar las citas con facilidad.

### Criterios de aceptación
- Nombre y colorHex obligatorios.  
- No permitir duplicados.  

### Endpoints
- POST /etiquetas  
- PATCH /etiquetas/:id  
- DELETE /etiquetas/:id  

---

## HU-ADM-03 — Administrar agrupadores
**Como** administrador  
**Quiero** gestionar agrupadores de citas  
**Para** organizar la información por campañas o bloques.

### Endpoints
- POST /agrupadores  
- PATCH /agrupadores/:id  
- DELETE /agrupadores/:id  

---

## HU-ADM-04 — Ver todas las citas
**Como** administrador  
**Quiero** ver todas las citas  
**Para** monitorear el sistema.

### Filtros:
- fechaInicio, fechaFin  
- medicoId  
- estado  
- etiquetaId  
- agrupadorId  

### Endpoints
- GET /citas  

---

## HU-ADM-05 — Crear citas para cualquier médico
**Como** administrador  
**Quiero** registrar citas  
**Para** organizar la agenda de los médicos.

### Endpoints
- POST /citas  

---

## HU-ADM-06 — Editar, cancelar o reprogramar citas
### Endpoints
- PATCH /citas/:id  
- PATCH /citas/:id/cancelar  
- PATCH /citas/:id/reprogramar  
- PATCH /citas/:id/estado  

---

# 🧩 2. HISTORIAS DE USUARIO – SUPERVISOR

## HU-SUP-01 — Crear citas para médicos
### Endpoints
- POST /citas  

---

## HU-SUP-02 — Ver todas las citas
### Endpoints
- GET /citas  

---

## HU-SUP-03 — Reprogramar citas
### Endpoints
- PATCH /citas/:id/reprogramar  

---

## HU-SUP-04 — Cancelar citas
### Endpoints
- PATCH /citas/:id/cancelar  

---

## HU-SUP-05 — Asignar etiquetas a citas
### Endpoints
- PATCH /citas/:id/etiquetas  

---

# 🧩 3. HISTORIAS DE USUARIO – PERSONAL MÉDICO

## HU-MED-01 — Ver solo mis citas
### Endpoints
- GET /citas/mis-citas  

---

## HU-MED-02 — Cambiar estado de una cita
### Endpoints
- PATCH /citas/:id/estado  

---

## HU-MED-03 — Reprogramar mis citas
### Endpoints
- PATCH /citas/:id/reprogramar  

---

## HU-MED-04 — Agregar etiquetas a mis citas
### Endpoints
- PATCH /citas/:id/etiquetas  

---

# 🧩 4. ENDPOINTS GENERALES DEL SISTEMA

## Autenticación
- POST /auth/login  
- POST /auth/refresh  

## Gestión de usuarios
- GET /usuarios  
- GET /usuarios/:id  
- POST /usuarios  
- PATCH /usuarios/:id  
- PATCH /usuarios/:id/desactivar  
- DELETE /usuarios/:id  

## Gestión de etiquetas
- GET /etiquetas  
- GET /etiquetas/:id  
- POST /etiquetas  
- PATCH /etiquetas/:id  
- DELETE /etiquetas/:id  

## Gestión de agrupadores
- GET /agrupadores  
- GET /agrupadores/:id  
- POST /agrupadores  
- PATCH /agrupadores/:id  
- DELETE /agrupadores/:id  

## Gestión de citas
- GET /citas  
- GET /citas/mis-citas  
- GET /citas/:id  
- POST /citas  
- PATCH /citas/:id  
- PATCH /citas/:id/estado  
- PATCH /citas/:id/reprogramar  
- PATCH /citas/:id/cancelar  
- PATCH /citas/:id/etiquetas  
- PATCH /citas/:id/agrupador  

