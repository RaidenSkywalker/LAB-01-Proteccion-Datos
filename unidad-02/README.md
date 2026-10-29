# LAB-02 — Cifrado, credenciales y comunicaciones seguras

**Estudiante:** Zamora Serrano Irvin Donovan
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos — Unidad II, tema 2.4
**Motor:** PostgreSQL 16 en Docker (contenedor `postgres-lab`)
**Fecha:** 2026-10-27

## Contenido

| Ruta | Descripción |
|---|---|
| `sql/01-credenciales.sql` | Actividad 1: contraseñas en texto claro vs. hash con `crypt()` |
| `sql/02-cifrado-datos.sql` | Actividad 2: cifrado del RFC con `pgp_sym_encrypt` |
| `sql/03-verificacion-tls.sql` | Actividades 4 a 6: verificación de TLS |
| `evidencias/` | Evidencias 01, 02, 03, 04, 07, 08 y 10 |

## Cómo ejecutar
```powershell
Get-Content unidad-02/Lab-02-cifrado-credenciales/sql/01-credenciales.sql | docker exec -i postgres-lab psql -U postgres
Get-Content unidad-02/Lab-02-cifrado-credenciales/sql/02-cifrado-datos.sql | docker exec -i postgres-lab psql -U postgres
 Get-Content unidad-02/Lab-02-cifrado-credenciales/sql/03-verificacion-tls.sql | docker exec -i postgres-lab psql "host=localhost port=5432 dbname=postgres user=postgres sslmode=prefer"
```
La configuración de TLS (certificado de laboratorio y activación de `ssl`) está documentada en `evidencias/04-tls.md`.

## 1. Introducción
Un control de acceso correcto no basta: las contraseñas, los datos sensibles, las comunicaciones y las claves también deben protegerse. Este laboratorio aborda tres necesidades de Comercializadora Norte: credenciales, información sensible y comunicaciones.

## 2. Protección de credenciales
- **Texto claro:** la contraseña se ve directamente; una lectura de la tabla la expone.
- **Hash:** transformación unidireccional con sal (`crypt()` + `gen_salt('bf')`); permite verificar, no recuperar.
- **Cifrado:** transformación reversible con clave; no es apropiado para contraseñas porque la clave expuesta revela todas.

## 3. Protección de datos sensibles
Se protegió el RFC con `pgp_sym_encrypt`/`pgp_sym_decrypt` porque es un dato fiscal que debe poder recuperarse cuando exista justificación. La clave utilizada es ficticia y de laboratorio.

## 4. TLS
TLS protege los datos en tránsito (confidencialidad, integridad y autenticación del servidor). Se verificó el estado con `SHOW ssl;` y `pg_stat_ssl`, se habilitó TLS con un certificado autofirmado y se compararon `sslmode=disable`, `require` y `verify-full`. Resultados en `evidencias/04-tls.md`.

## 5. Gestión de claves
Las claves no deben almacenarse junto con los scripts ni en el repositorio: el historial de Git conserva los secretos aunque se borren, y un repositorio privado no es un almacén de secretos. Debe usarse un gestor de secretos o KMS. Ver `evidencias/03-gestion-claves.md` y `evidencias/10-politica-claves.md`.

## 6. Resultados
- Contraseña correcta → `t`; incorrecta → `f`; los dos hashes de la misma contraseña son distintos.
- El RFC se almacena cifrado (`bytea`) y se recupera solo con la clave correcta.
- <Resume aquí lo que obtuviste en TLS: valor de `ssl`, versión, cipher y diferencia entre modos.>
- La revisión de secretos no encontró credenciales reales.

## 7. Problemas encontrados
> Ajusta esta sección a lo que realmente te ocurrió. Posibles puntos:
- La imagen `postgres:16` tiene `ssl = off` por defecto; hubo que generar un certificado y activar TLS.
- Una conexión por socket Unix (`docker exec ... psql -U postgres`) no usa TLS; para verificarlo hay que conectar por TCP (`host=localhost`).
- `verify-full` requiere que el nombre de conexión coincida con el certificado (`CN=localhost`).
- <Otros errores reales y cómo los resolviste.>

## 8. Conclusiones
Aprendí que cada riesgo requiere un mecanismo distinto (hash, cifrado, TLS, gestión de claves) y que ninguno sustituye al control de acceso. En producción aplicaría: contraseñas con Argon2id/bcrypt, cifrado de columnas sensibles con claves en un KMS, TLS con `verify-full` y certificados de una CA, cifrado de respaldos, escaneo de secretos antes de cada commit y una política de rotación de claves.

## Preguntas de reflexión

1. **¿Por qué una contraseña no debe almacenarse como texto claro?** Porque quien lea la tabla o un respaldo obtiene credenciales utilizables de inmediato.
2. **¿Por qué un hash no es equivalente a un cifrado?** El hash es unidireccional y no se puede revertir; el cifrado es reversible con la clave.
3. **¿Por qué el cifrado de una columna no sustituye al control de acceso?** Quien tenga la clave o acceso a la función de descifrado puede leer el dato; los permisos siguen definiendo quién puede consultar y usar la clave.
4. **¿Por qué TLS no sustituye a la autorización de PostgreSQL?** TLS protege el canal; no decide qué puede hacer cada usuario una vez conectado.
5. **¿Qué ocurriría si se pierde la clave de cifrado?** Los datos cifrados quedarían irrecuperables.
6. **¿Y si una clave se publica accidentalmente en GitLab/GitHub?** Debe considerarse comprometida: cualquiera con acceso podría descifrar los datos; hay que rotarla y recifrar, porque permanece en el historial.
7. **¿Por qué un repositorio privado no es un almacén de secretos?** Reduce la exposición, pero el secreto queda en historial, clones y copias a disposición de todos con acceso.
8. **¿Diferencia entre proteger datos almacenados y datos en transmisión?** Lo almacenado se protege con cifrado en reposo; lo transmitido, con TLS. Son problemas distintos y se resuelven por separado.
9. **¿Por qué la gestión de claves es tan importante como el algoritmo?** Un algoritmo robusto no sirve si la clave se expone, se pierde o se almacena junto a los datos.
10. **¿Qué mecanismo adicional para los respaldos?** Cifrado de los respaldos (por ejemplo con `gpg` o `age`), claves guardadas aparte y control de acceso al almacenamiento.
