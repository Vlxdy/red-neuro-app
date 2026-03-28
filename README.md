# 🧠 Red Neuro App

Aplicación móvil desarrollada en Flutter para la gestión de citas
médicas, servicios y notificaciones en tiempo real para un centro
neurológico.

---

## 🚀 Tecnologías principales

- Flutter
- Socket.IO (tiempo real)
- Hive (almacenamiento local)
- Firebase (notificaciones)
- Provider (estado)
- GoRouter (navegación)
- flutter_dotenv (configuración por entorno)

---

## ⚙️ Configuración de entorno

La aplicación utiliza variables de entorno para manejar diferentes
configuraciones (desarrollo, producción, etc).

---

## 📁 Archivos de entorno

.env.dev\
.env.prod\
.env.dev.example\
.env.prod.example

---

## 🔑 Variables utilizadas

- URL_BASE: URL base del backend REST\
- SOCKETS: URL base del servidor de sockets\
- SOCKET_PATH: Path del endpoint de socket.io\
- ENVIRONMENT: Entorno actual (dev, prod, staging)\
- CITAS_DURACION_DEFECTO_MINUTOS: Duración por defecto de citas

---

## ▶️ Ejecución

### Desarrollo

fvm flutter run --dart-define=FLAVOR=dev

### Producción

fvm flutter run --dart-define=FLAVOR=prod

---

## ⚠️ Importante

Agregar en pubspec.yaml:

flutter: assets: - .env.dev - .env.prod

Agregar en .gitignore:

.env* !.env*.example

---

## 🔐 Seguridad

Hive usa clave generada dinámicamente con:

Hive.generateSecureKey()

Guardada en flutter_secure_storage.

---

## 🔌 WebSockets

Configuración:

IO.io( Constantes.sockets, IO.OptionBuilder()
.setPath(Constantes.socketPath) .setTransports(\['websocket'\])
.build(), );

---

## 📂 Estructura

lib/ ├── main.dart └── src/ ├── config/ ├── constants/ └── ...

---

## 👨‍💻 Proyecto Red Neuro
