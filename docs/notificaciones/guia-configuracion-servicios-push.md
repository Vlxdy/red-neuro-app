# Guía de configuración de servicios push (credenciales y pruebas)

## 1) Firebase Cloud Messaging (Android / opcional iOS)

### 1.1 Registro y obtención de credenciales

1. Entrar a https://console.firebase.google.com.
2. Crear proyecto (o usar existente).
3. Ir a **Project settings > Service accounts**.
4. Generar nueva clave privada (JSON).
5. Del JSON tomar:
   - `project_id` -> `FCM_PROJECT_ID`
   - `client_email` -> `FCM_CLIENT_EMAIL`
   - `private_key` -> `FCM_PRIVATE_KEY`

### 1.2 Dónde pegarlas

Pegar en `.env` del backend:

```env
PUSH_PROVIDER=fcm
# Ruta directa al archivo descargado desde Firebase (recomendado)
FCM_CREDENTIALS_FILE=./secrets/red-neuro-firebase-adminsdk-fbsvc-c44b035d64.json

```

> Si usas Docker/K8s, poner estos valores como secretos del entorno de despliegue.

---

## 2) Configuración mínima recomendada (solo JSON de Firebase)

Usar únicamente:

```env
PUSH_PROVIDER=fcm
FCM_CREDENTIALS_FILE=./secrets/red-neuro-firebase-adminsdk-fbsvc-c44b035d64.json
```

No necesitas declarar `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL` ni `FCM_PRIVATE_KEY` por separado si el JSON existe y es válido.

---

## 3) Validar que la configuración está bien

## 3.1 Checklist backend

1. Variables presentes en entorno.
2. Backend reiniciado con las nuevas variables.
3. Registro de token funciona:
   - `POST /api/dispositivos-push`
4. Token se puede inactivar:
   - `DELETE /api/dispositivos-push/:token`
5. Validar lectura del JSON en backend:
   - `GET /api/notificaciones/validar-config-push` (admin)

## 3.2 Prueba funcional mínima

1. Login en app móvil.
2. Registrar token push (endpoint anterior).
3. Ejecutar resumen manual:
   - `POST /api/notificaciones/ejecutar-resumen-diario`
4. Verificar:
   - llega push al dispositivo,
   - aparece en bandeja (`GET /api/notificaciones`),
   - `PATCH /api/notificaciones/:id/visto` actualiza estado.

## 3.3 Prueba de no-asistió automático

1. Configurar:
   - `CITAS_AUTO_NO_ASISTIO_ENABLED=true`
   - `CITAS_AUTO_NO_ASISTIO_CRON` según ventana deseada.
2. Ejecutar manual para validar:
   - `POST /api/citas/ejecutar-auto-no-asistio`
3. Confirmar que citas no completadas cambian a `NO_ASISTIO`.

---

## 4) Problemas comunes

- **FCM_PRIVATE_KEY mal escapada**: usar `\n` en saltos de línea.
- **APNs .p8 inválida**: key descargada distinta o truncada.
- **Bundle ID diferente**: APNs no entrega si no coincide.
- **Token viejo**: registrar token nuevamente después de reinstalar app.
- **`npm i firebase-admin` falla con 403**: validar política del registry corporativo o whitelist del paquete en seguridad.


## 5) Librería usada en backend

La implementación del backend usa **`firebase-admin`** para envío push.

Configuración usada:
- Módulo dedicado `FirebaseModule` para inicializar SDK una sola vez.
- Inicialización con `FCM_CREDENTIALS_FILE`.
- Envío por lote con `sendEachForMulticast`.
- Validación de credenciales vía `GET /api/notificaciones/validar-config-push`.

Instalación en entorno:

```bash
npm install firebase-admin
```
