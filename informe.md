# Informe LAB-01 — Protección y privacidad de datos

**Estudiante:** Zamora Serrano Irvin Donovan
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos — Unidad II
**Motor:** PostgreSQL 16 (Docker, contenedor `postgres-lab`)
**Fecha:** 2026-10-23

## 1. Clasificación (Actividad 1)

| Campo | ¿Identifica directamente? | ¿Puede contribuir a identificar? | ¿Requiere protección? | Justificación |
|---|---|---|---|---|
| id | No | Sí | Sí | Enlaza registros y se usa en el mapa de seudonimización |
| nombre | Sí | Sí | Sí | |
| correo | Sí | Sí | Sí | |
| telefono | Sí | Sí | Sí | |
| rfc | Sí | Sí | Sí | |
| edad | No | Sí | Sí | Cuasi-identificador |
| ciudad | No | Sí | Sí | Cuasi-identificador |
| codigo_postal | No | Sí | Sí | Cuasi-identificador, más preciso que la ciudad |
| fecha_alta | No | Sí | Sí | Puede correlacionarse con otras fuentes |

**Preguntas**
1. Campos que identifican directamente:
2. Campos que podrían contribuir a identificar:
3. Combinación que incrementa el riesgo de reidentificación:
4. ¿Todo dato a proteger es dato personal sensible jurídicamente?

## 2. Enmascaramiento (Actividad 2)

- Qué se ocultó:
- Para quién:
- Por qué:
- Mecanismo (vista + GRANT + REVOKE):

**Preguntas**
1. ¿Qué información continúa existiendo en la tabla original?
2. ¿Qué información puede visualizar `soporte`?
3. ¿Por qué no basta ocultar los datos solo en la aplicación?
4. ¿Qué ocurriría si `soporte` tuviera acceso directo a `clientes`?

## 3. Seudonimización y separación de funciones (Actividades 3 y 4)

- Cómo se generaron los tokens:
- Dónde está el mapa de correspondencia:
- Quién debería acceder a él:
- Por qué se separaron los permisos:

**Preguntas**
1. ¿Qué ocurriría si `analista` consultara `pii.mapa_cliente`?
2. ¿Qué principio de seguridad se aplica?
3. ¿Por qué la seudonimización no equivale a anonimización?
4. ¿Qué información permite volver a relacionar el token con una persona?

## 4. Anonimización y riesgo de reidentificación (Actividades 5 y 6)

- Identificadores eliminados:
- Atributos generalizados:
- Grupos suprimidos:
- Riesgo que permanece:

**Preguntas de la Actividad 6** (1 a 7):

**Reto:** cambio realizado / motivo / resultado / riesgo que reduce:

## 5. Retención (Actividad 7)

- Criterio utilizado:
- Información a conservar:
- Información que podría eliminarse:
- Controles previos a la eliminación:
- Justificación del periodo, aprobación, respaldo, evidencia y recuperación:

## 6. Conclusiones

- ¿Qué técnica usarías para soporte?
- ¿Y para analítica?
- ¿Y para publicar estadísticas?
- ¿Por qué ninguna sustituye al control de acceso?

## 7. Preguntas de reflexión

1. ¿Cuál es la diferencia entre enmascaramiento y seudonimización?
2. ¿Por qué la seudonimización no significa anonimización?
3. ¿Por qué eliminar nombre y RFC no garantiza que un conjunto de datos sea anónimo?
4. ¿Qué función tienen los cuasi-identificadores?
5. ¿Por qué es importante separar el mapa de seudonimización?
6. ¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?
7. ¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?
8. ¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra
acceso no autorizado?
9. ¿Por qué la retención forma parte de la protección de datos?
10. ¿Qué riesgo existe si una organización conserva información indefinidamente?
