# LAB-04 — Hardening y configuración segura de PostgreSQL

**Estudiante:** Zamora Serrano Irvin Donovan | **Grupo:** 4-3
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos — Unidad II, tema 2.6
**Fecha:** 2026-11-02

## Objetivo
Aplicar un proceso básico de hardening a PostgreSQL 16: identificar la superficie de ataque, reducir la exposición de red y de autenticación, separar cuentas con mínimo privilegio, revisar permisos del sistema operativo y TLS, y documentar el estado antes y después con una línea base y una checklist.

## Entorno
- PostgreSQL 16 en un contenedor Docker académico y aislado: `postgres-lab`.
- Cliente: `psql` mediante `docker exec`, desde PowerShell en VS Code.
- Base de las prácticas: `postgres`, con los objetos de los LAB-01 a LAB-03.
- No se modificó ningún servidor institucional ni firewall. El firewall se diseña de forma conceptual.

| Ruta | Contenido |
|---|---|
| `sql/01-inspeccion.sql` | Inspección de solo lectura (superficie, archivos, `pg_hba`, roles, extensiones, conexiones, TLS) |
| `sql/02-roles.sql` | Cuentas `app_user` y `consulta_user` con privilegios mínimos |
| `sql/03-configuracion.sql` | Parámetros: registro de conexiones, tiempos máximos, SCRAM, `listen_addresses` |
| `sql/04-verificacion.sql` | Verificación del estado posterior y pruebas de privilegios |
| `configuracion/baseline.md` | Línea base de seguridad de PostgreSQL 16 |
| `configuracion/cambios.md` | Comparación antes/después, registro de cambios y análisis |
| `configuracion/pg_hba.hardened.conf` | Reglas de acceso endurecidas |
| `configuracion/guia-ejecucion.md` | Pasos reproducibles, en orden |
| `evidencias/` | Capturas 01 a 06 |
| `informe.md` | Respuestas, caso integral y reflexión |

## Superficie de ataque inicial
> Completa con tu salida de `sql/01-inspeccion.sql` y la guía (Paso 1).

| Elemento | Estado actual | ¿Es necesario? | Riesgo |
|---|---|---|---|
| Puerto PostgreSQL | `<5432; docker port: ...>` | Sí, para el servicio | Punto de entrada conocido |
| Interfaces de escucha | `<listen_addresses: ...>` | Solo la local | `'*'` expone el servicio en todas las interfaces |
| Conexiones remotas | `<pg_stat_activity / docker port>` | No hay aplicaciones remotas en el laboratorio | Superficie innecesaria |
| Usuarios administrativos | `<roles con superuser>` | Solo para administración | Una cuenta con control total |
| SSL/TLS | `<SHOW ssl: ...>` | Sí | Sin TLS, credenciales y datos viajan sin protección |
| Métodos de autenticación | `<auth_method de pg_hba_file_rules>` | `scram-sha-256` | `trust` permite entrar sin contraseña |

## Hallazgos
> Ajusta cada fila a lo que observaste; elimina las que no apliquen.

| # | Hallazgo | Riesgo | Evidencia |
|---|---|---|---|
| 1 | `listen_addresses` en `<valor>` | Servicio en interfaces innecesarias | `evidencias/02-listen-addresses.png` |
| 2 | Reglas de `pg_hba.conf` amplias (`host all all all`) y/o `trust` en TCP local | Cualquier origen puede intentar autenticarse; acceso sin contraseña | `evidencias/03-pg-hba.png` |
| 3 | Solo la cuenta `postgres` (superusuario), sin cuentas por función | Cuenta de aplicación con control total | `evidencias/04-roles.png` |
| 4 | Registro de conexiones y tiempos máximos sin configurar | Sin trazabilidad; sesiones indefinidas | `configuracion/cambios.md` |
| 5 | `<TLS: estado encontrado>` | Tráfico sin cifrar | `evidencias/05-tls.png` |
| 6 | `<permisos del SO encontrados>` | Lectura de archivos sensibles | `configuracion/cambios.md` |

## Cambios realizados
Resumen (detalle, comandos y reversión en `configuracion/cambios.md`):
1. Cuentas `app_user` y `consulta_user` con privilegios mínimos y límite de conexiones; `REVOKE CONNECT ... FROM PUBLIC`.
2. `pg_hba.conf` con reglas por base de datos, usuario, origen y método; solo `127.0.0.1`/`::1`, `hostssl` y `scram-sha-256`; `reject` explícito para el resto.
3. `listen_addresses = 'localhost'`.
4. `log_connections`, `log_disconnections`, `statement_timeout` e `idle_in_transaction_session_timeout`.
5. Permisos `600` y propietario `postgres` en `pg_hba.conf`.

## Justificación de los cambios
- **Exposición de red:** si PostgreSQL no escucha fuera del equipo local, la mayoría de las rutas de ataque remotas desaparecen.
- **`pg_hba.conf` específico:** limita quién puede autenticarse, en qué base, desde dónde y con qué método.
- **Cuentas por función:** una cuenta comprometida solo puede hacer lo que su función requiere.
- **TLS y SCRAM:** protegen credenciales y datos en tránsito y el almacenamiento de contraseñas.
- **Tiempos y registros:** protegen la disponibilidad y permiten detectar abusos.
- **No se cambió el puerto:** hacerlo no es hardening suficiente.

## Verificación
> Resultados de `sql/04-verificacion.sql` y de las pruebas de la guía (Paso 5).

| Prueba | Resultado esperado | Resultado obtenido | Evidencia |
|---|---|---|---|
| `SHOW listen_addresses` | `localhost` | `<completar>` | `02-listen-addresses.png` |
| `pg_hba_file_rules` sin errores | columna `error` vacía | `<completar>` | `03-pg-hba.png` |
| Conexión sin contraseña | `no password supplied` | `<completar>` | `06-verificacion.png` |
| Usuario no autorizado | `pg_hba.conf rejects connection` | `<completar>` | `06-verificacion.png` |
| Conexión sin TLS | rechazada | `<completar>` | `06-verificacion.png` |
| Conexión con TLS | `ssl = t`, versión y cipher | `<completar>` | `05-tls.png` |
| `app_user` hace `DELETE` | `permission denied` | `<completar>` | `06-verificacion.png` |
| `consulta_user` escribe | `permission denied` | `<completar>` | `06-verificacion.png` |

## Checklist de hardening
Marca con ☑ solo lo que verificaste, y enlaza la evidencia.

| # | Control | Verificado | Evidencia |
|---|---|---|---|
| 1 | Puerto documentado | ☐ | `01-superficie-ataque.png` |
| 2 | Interfaces de escucha justificadas | ☐ | `02-listen-addresses.png` |
| 3 | `pg_hba.conf` revisado | ☐ | `03-pg-hba.png` |
| 4 | Redes autorizadas restringidas | ☐ | `03-pg-hba.png` |
| 5 | Autenticación segura (SCRAM) | ☐ | `01-inspeccion.sql` (A7) |
| 6 | Superusuarios identificados | ☐ | `04-roles.png` |
| 7 | Cuentas de aplicación separadas | ☐ | `04-roles.png` |
| 8 | Privilegios mínimos | ☐ | `06-verificacion.png` |
| 9 | Extensiones revisadas | ☐ | `cambios.md` §6 |
| 10 | TLS verificado | ☐ | `05-tls.png` |
| 11 | Configuración protegida (permisos de archivos) | ☐ | `cambios.md` |
| 12 | Directorio de datos protegido | ☐ | `cambios.md` |
| 13 | Firewall documentado | ☐ | `cambios.md` §8 |
| 14 | Actualizaciones documentadas | ☐ | `baseline.md` |
| 15 | Configuración registrada | ☐ | `cambios.md` |
| 16 | Registro de conexiones activado | ☐ | `04-verificacion.sql` (V1) |
| 17 | Límites de conexión y tiempos definidos | ☐ | `04-verificacion.sql` (V1) |
| 18 | Contraseñas fuera de scripts y repositorio | ☐ | `.gitignore`, `02-roles.sql` |

## Conclusiones
> Redáctalas con tus palabras, apoyándote en tus resultados.

El hardening reduce la superficie de ataque: elimina o restringe lo innecesario y controla lo que debe permanecer. En este laboratorio el cambio de mayor efecto fue `<tu conclusión: listen_addresses / pg_hba>`. Ningún control sustituye a los demás: red, autenticación, autorización, sistema operativo, TLS y monitoreo trabajan en capas. Un hardening solo es útil si está documentado, es reproducible y se verifica.
