# Implementación en Frontend (Next.js) o App Móvil (Flutter)

Este documento describe cómo consumir la API de citas e historial desde un frontend web (Next.js) o una app móvil (Flutter). Incluye flujo, endpoints, estados, filtros y recomendaciones de UI/UX.

## 1. Flujo general de trabajo

### 1.1 Creación de cita
- **Si se asigna médico** → la cita se crea en **SOLICITADA** y se notifica al médico para confirmación.
- **Si no se asigna médico** → la cita se crea directamente en **CONFIRMADA**.

**Endpoint:**
```
POST /citas
```

**Payload mínimo recomendado:**
- `detalle`
- `fechaInicio`
- `idEspecialidad`
- `tipoCita`
- (opcional) `idMedico`, `idConsultorio`, `idPaciente`, `idEstudio`

### 1.2 Confirmación
- El médico asignado puede confirmar la cita (cambiar estado a **CONFIRMADA**).

**Endpoint:**
```
PATCH /citas/:id/estado
```

**Payload:**
```json
{ "estado": "CONFIRMADA" }
```

### 1.3 Reprogramación
- Permite ajustar fecha/hora. Si la cita estaba **RECHAZADA**, vuelve a **SOLICITADA**.

**Endpoint:**
```
PATCH /citas/:id/reprogramar
```

### 1.4 Cancelación
- Cambia el estado a **CANCELADA** y registra historial.

**Endpoint:**
```
PATCH /citas/:id/cancelar
```

## 2. Estados y visualización en UI

**Estados:**
- SOLICITADA
- CONFIRMADA
- EN_CURSO
- COMPLETADA
- NO_ASISTIO
- CANCELADA
- RECHAZADA

**Reglas de UX sugeridas:**
- **SOLICITADA**: mostrar botón “Confirmar”.
- **CONFIRMADA**: mostrar botón “Iniciar consulta”.
- **EN_CURSO**: mostrar botón “Finalizar”.
- **RECHAZADA / CANCELADA / NO_ASISTIO**: mostrar en gris y bloquear edición.

## 3. Historial de citas (paginado y con filtros)

**Endpoint:**
```
GET /citas/:id/historial
```

**Query params soportados:**
- `pagina`
- `limite`
- `fechaInicio`
- `fechaFin`
- `estadoAnterior`
- `rolEjecutor`
- `idEjecutor`

**Respuesta paginada:**
- `filas`: lista con historial
- `total`: total de registros

**Campos clave en cada item:**
- `ejecutor` (datos completos del usuario ejecutor)
- `detalleCambios` (lista de cambios con `field`, `before`, `after`)

## 4. Implementación en Next.js

### 4.1 Cliente HTTP (Axios)
```ts
import axios from 'axios'

export const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})
```

### 4.2 Hook para historial
```ts
export async function getHistorialCita(id: string, params: any) {
  const { data } = await api.get(`/citas/${id}/historial`, { params })
  return data.datos
}
```

### 4.3 UI sugerida
- **Tabla** con columnas: fecha, ejecutor, acción, cambios.
- **Badge** por estado.
- **Drawer/Modal** para detalle de cambios.

## 5. Implementación en Flutter

### 5.1 Cliente HTTP (Dio)
```dart
final dio = Dio(BaseOptions(
  baseUrl: dotenv.env['API_URL']!,
));

dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await storage.read(key: 'token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  },
));
```

### 5.2 Llamada a historial
```dart
Future<Map<String, dynamic>> getHistorial(String id, Map<String, dynamic> params) async {
  final response = await dio.get('/citas/$id/historial', queryParameters: params);
  return response.data['datos'];
}
```

### 5.3 UI sugerida
- **ListView** con tarjetas por historial.
- Mostrar ejecutor con avatar y nombre.
- Expandable para `detalleCambios`.

## 6. Buenas prácticas

- Cachear resultados de historial si se navega varias veces a la misma cita.
- Usar paginación incremental en móvil (infinite scroll).
- Mostrar siempre `detalleCambios` cuando el historial corresponda a actualización.

