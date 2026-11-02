# Guía de ejecución reproducible — LAB-04

Contenedor: `postgres-lab` (PostgreSQL 16). Ejecutar desde esta carpeta (`unidad-02/lab-04-hardening`) en PowerShell. El orden importa: primero se captura el **estado inicial**, después se aplican los cambios y al final se verifica.

> Antes de empezar: este laboratorio cambia la configuración de acceso de un contenedor **académico aislado**. No lo apliques a servidores institucionales ni de producción.

## Paso 0. Respaldos (evita perder el trabajo de los LAB-01 a LAB-03)
```powershell
docker exec postgres-lab sh -c "pg_dumpall -U postgres > /tmp/respaldo-antes-lab04.sql"
docker cp postgres-lab:/tmp/respaldo-antes-lab04.sql .\respaldo-antes-lab04.sql
docker exec postgres-lab cp /var/lib/postgresql/data/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf.bak-lab04
```
Los respaldos están en `.gitignore`: no se suben al repositorio.

## Paso 1. Estado inicial (ANTES)
```powershell
Get-Content sql/01-inspeccion.sql | docker exec -i postgres-lab psql -U postgres
```
Permisos del sistema operativo (Actividad 12):
```powershell
docker exec postgres-lab ls -l /var/lib/postgresql/data/postgresql.conf /var/lib/postgresql/data/pg_hba.conf /var/lib/postgresql/data/pg_ident.conf
docker exec postgres-lab ls -ld /var/lib/postgresql/data
```
Reglas de `pg_hba.conf` sin comentarios:
```powershell
docker exec postgres-lab sh -c "grep -v -E '^(#|$)' /var/lib/postgresql/data/pg_hba.conf"
```
Exposición de red (Actividad 13). `ss` puede no existir en el contenedor, por lo que se usan alternativas:
```powershell
docker port postgres-lab
netstat -ano | findstr :5432
docker exec postgres-lab sh -c "grep ' 0A ' /proc/net/tcp /proc/net/tcp6"
```
- `docker port` muestra cómo se publica el puerto hacia tu equipo (por ejemplo `0.0.0.0:5432`).
- En `/proc/net/tcp`, el estado `0A` es LISTEN. `00000000:1538` equivale a `0.0.0.0:5432` (todas las interfaces) y `0100007F:1538` a `127.0.0.1:5432` (solo local). `1538` en hexadecimal es 5432.

TLS por TCP antes del hardening (Actividad 15; requiere el TLS del LAB-02):
```powershell
docker exec postgres-lab psql "host=127.0.0.1 port=5432 dbname=postgres user=postgres sslmode=require" -c "SELECT pid, usename, client_addr, ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid();"
```
Si `SHOW ssl;` da `off`, primero realiza los pasos de TLS documentados en `unidad-02/lab-02-cifrado-credenciales/evidencias/04-tls.md`.

**Qué capturar:** `01-superficie-ataque.png` (versión, puerto, `listen_addresses`, `ssl`, `password_encryption` y `docker port`) y `02-listen-addresses.png` (estado "antes" de `listen_addresses` y los sockets en LISTEN).

## Paso 2. Roles (Actividades 8 y 9)
```powershell
Get-Content sql/02-roles.sql | docker exec -i postgres-lab psql -U postgres
```
Asigna las contraseñas **de forma interactiva** (no quedan en scripts ni en el repositorio). Usa contraseñas de laboratorio, no reutilizadas:
```powershell
docker exec -it postgres-lab psql -U postgres -c "\password app_user"
docker exec -it postgres-lab psql -U postgres -c "\password consulta_user"
docker exec -it postgres-lab psql -U postgres -c "\password postgres"
```
(La última solo si no recuerdas la contraseña del contenedor; el administrador la necesitará para entrar por TCP.)

**Qué capturar:** `04-roles.png` (tabla de roles: `postgres` superusuario; `app_user` y `consulta_user` sin privilegios administrativos).

## Paso 3. `pg_hba.conf` (Actividades 4 a 6)
Revisa y ajusta `configuracion/pg_hba.hardened.conf` a tu entorno. Si `SHOW ssl;` es `off`, cambia `hostssl` por `host`. Después:
```powershell
docker cp .\configuracion\pg_hba.hardened.conf postgres-lab:/var/lib/postgresql/data/pg_hba.conf
docker exec -u root postgres-lab chown postgres:postgres /var/lib/postgresql/data/pg_hba.conf
docker exec -u root postgres-lab chmod 600 /var/lib/postgresql/data/pg_hba.conf
docker exec postgres-lab psql -U postgres -c "SELECT line_number, type, database, user_name, address, auth_method, error FROM pg_hba_file_rules ORDER BY line_number;"
```
**La columna `error` debe estar vacía en todas las filas.** Si hay un error (por ejemplo por saltos de línea de Windows), corrígelo antes de recargar. Cuando esté limpio:
```powershell
docker exec postgres-lab psql -U postgres -c "SELECT pg_reload_conf();"
```
La regla `local all postgres trust` mantiene tu acceso con `docker exec ... psql -U postgres`, así que no puedes quedarte sin acceso.

**Qué capturar:** `03-pg-hba.png` (reglas "después"; las "antes" las pegas como texto en `cambios.md`).

## Paso 4. Parámetros de configuración y reinicio (Actividades 3, 7 y 11)
```powershell
Get-Content sql/03-configuracion.sql | docker exec -i postgres-lab psql -U postgres
docker restart postgres-lab
docker ps
```
Espera unos segundos a que el contenedor vuelva a estar `Up`. `listen_addresses='localhost'` significa que PostgreSQL ya no acepta conexiones desde fuera del contenedor (por ejemplo DBeaver desde tu equipo). Tus scripts con `docker exec` siguen funcionando.

## Paso 5. Verificación (Actividades 15 y 16)
```powershell
Get-Content sql/04-verificacion.sql | docker exec -i postgres-lab psql -U postgres
```
Pruebas de autenticación por TCP. Los mensajes de error son parte de la evidencia:
```powershell
# Sin contraseña (-w = no preguntar): la autenticación es obligatoria
docker exec postgres-lab psql -w "host=127.0.0.1 dbname=postgres user=app_user sslmode=require" -c "SELECT 1"

# Usuario no autorizado: rechazado por pg_hba.conf
docker exec postgres-lab psql -w "host=127.0.0.1 dbname=postgres user=intruso sslmode=require" -c "SELECT 1"

# Sin TLS: rechazado porque las reglas exigen hostssl
docker exec postgres-lab psql -w "host=127.0.0.1 dbname=postgres user=app_user sslmode=disable" -c "SELECT 1"

# Con contraseña y TLS verificado (te pedirá la contraseña de app_user)
docker exec -it postgres-lab psql "host=localhost dbname=postgres user=app_user sslmode=verify-full sslrootcert=/var/lib/postgresql/server.crt" -c "SELECT current_user" -c "SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid();"
```
Verifica el sistema operativo y la red otra vez:
```powershell
docker exec -u root postgres-lab ls -l /var/lib/postgresql/data/pg_hba.conf /var/lib/postgresql/data/postgresql.conf
docker exec postgres-lab sh -c "grep ' 0A ' /proc/net/tcp /proc/net/tcp6"
```
Después del reinicio, `0100007F:1538` (solo 127.0.0.1) debe aparecer y `00000000:1538` ya no.

**Qué capturar:** `05-tls.png` (conexión con TLS: `ssl = t`, versión y cipher) y `06-verificacion.png` (pruebas de privilegios y conexiones permitidas y denegadas).

## Cómo revertir
```powershell
# pg_hba.conf original
docker exec postgres-lab cp /var/lib/postgresql/data/pg_hba.conf.bak-lab04 /var/lib/postgresql/data/pg_hba.conf
docker exec postgres-lab psql -U postgres -c "SELECT pg_reload_conf();"

# listen_addresses
docker exec postgres-lab psql -U postgres -c "ALTER SYSTEM RESET listen_addresses;"
docker restart postgres-lab
```
