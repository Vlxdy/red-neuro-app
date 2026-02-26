# Proyecto Base - PERMISOS

El proyecto base actualmente cuenta con roles y permisos de ejemplo

#### Roles

- ADMINISTRADOR
- TECNICO
- USUARIO

#### RUTAS sin autenticación

| verbo | ruta                        | descripción                                 |
|-------|-----------------------------|---------------------------------------------|
| GET   | /estado                     | Verificar el estado de la aplicación        |
| POST  | /auth                       | Autenticación usuario y contraseña          |
| GET   | /ciudadania-auth            | Autenticación con Ciudadanía Digital        |
| GET   | /ciudadania-callback        | Ruta para redirección de Ciudadanía Digital |
| GET   | /usuarios/cuenta/desbloqueo | Ruta para desbloqueo de cuenta              |

#### RUTAS con autenticación (acciones sobre la misma cuenta)

| VERBO | ruta                        | descripción                                     |
|-------|-----------------------------|-------------------------------------------------|
| GET   | /usuarios/cuenta/perfil     | Obtener información del perfil autenticado      |
| PATCH | /usuarios/cuenta/contrasena | Actualizar la contraseña del perfil autenticado |

#### Rutas con autenticación (configuraciones y paramétricas)

| verbo  | ruta                               | descripción                               |
|--------|------------------------------------|-------------------------------------------|
| GET    | /parametros/:grupo/listado         | Obtener paramétricas por grupo            |
| GET    | /autorizacion/permisos             | Lista políticas de permisos para frontend |
| POST   | /autenticacion/token\*             | Obtener un nuevo access token             |
| GET    | /autenticacion/logout\*            | Cierre de sesión                          |
| DELETE | /autenticacion/:id/refresh-token\* | Eliminar un refresh token                 |

#### Rutas con autenticación (específicas por rol)

| ruta/roles                       | ADMINISTRADOR | TECNICO | USUARIO |
|----------------------------------|---------------|---------|---------|
| GET /autorizacion/politicas      | x             |         |         |
| POST /autorizacion/politicas     | x             |         |         |
| PATCH /autorizacion/politicas    | x             |         |         |
| DELETE /autorizacion/politicas   | x             |         |         |
| GET /autorizacion/roles          | x             | x       |         |
| GET /autorizacion/modulos        | x             | x       |         |
| GET /usuarios                    | x             | x       |         |
| POST /usuarios                   | x             |         |         |
| PATCH /usuarios/:id              | x             |         |         |
| POST /usuarios/cuenta/ciudadania | x             |         |         |
| PATCH /usuarios/:id/inactivacion | x             |         |         |
| PATCH /usuarios/:id/activacion   | x             |         |         |
| PATCH /usuarios/:id/contrasena   | x             |         |         |
| GET /parametros                  | x             | x       |         |
| POST /parametros                 | x             | x       |         |

#### Permisos - Formato Casbin

```
ADMINISTRADOR, /api/autorizacion/politicas, GET|POST|DELETE
ADMINISTRADOR, /api/autorizacion/politicas/:id, PATCH
ADMINISTRADOR, /api/autorizacion/roles, GET
ADMINISTRADOR, /api/autorizacion/modulos, GET
ADMINISTRADOR, /api/usuarios, GET|POST
ADMINISTRADOR, /api/usuarios/:id, PATCH
ADMINISTRADOR, /api/usuarios/cuenta/ciudadania, POST
ADMINISTRADOR, /api/usuarios/:id/activacion, PATCH
ADMINISTRADOR, /api/usuarios/:id/inactivacion, PATCH
ADMINISTRADOR, /api/usuarios/:id/restauracion, PATCH
ADMINISTRADOR, /api/parametros, GET|POST
TECNICO, /api/autorizacion/roles, GET
TECNICO, /api/autorizacion/modulos, GET
TECNICO, /api/usuarios, GET
TECNICO, /api/parametros, GET|POST
*, /api/parametros/:grupo/listado, GET
*, /api/autorizacion/permisos, GET
*, /usuarios/cuenta/perfil, GET
*, /usuarios/cuenta/contrasena, PATCH
```
