-- =====================================================
-- LAB-03 | Actividad 2: Principio de minimizacion
-- Estudiante: Zamora Serrano Irvin Donovan
-- Fecha: 2026-10-31
-- Requiere: tabla public.clientes del LAB-01
-- NOTA: la tabla solicitada por soporte con TODOS los campos
-- (rfc, edad, ciudad, codigo_postal, fecha_alta) NO se crea:
-- se analiza y se rechaza por contradecir la minimizacion.
-- =====================================================

\echo '--- Estructura de la tabla origen (LAB-01) ---'
\d clientes

--8.0 En caso de no exitir la tabla 'clientes_soporte'
CREATE TABLE clientes_soporte ( 
  id BIGSERIAL, 
  nombre VARCHAR(120),
  correo VARCHAR(150), 
  telefono VARCHAR(20), 
  rfc VARCHAR(13), 
  edad INTEGER,
  ciudad VARCHAR(80), 
  codigo_postal VARCHAR(10), 
  fecha_alta DATE 
);

-- 8.1 Estructura minima para la finalidad de soporte
DROP TABLE IF EXISTS clientes_soporte;
CREATE TABLE clientes_soporte (
  id BIGINT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  correo VARCHAR(150) NOT NULL,
  telefono VARCHAR(20)
);

INSERT INTO clientes_soporte (id, nombre, correo, telefono)
SELECT id, nombre, correo, telefono FROM clientes;

\echo '--- clientes_soporte: solo los datos necesarios ---'
SELECT * FROM clientes_soporte;

\echo '--- Comparacion de columnas: clientes vs clientes_soporte ---'
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('clientes', 'clientes_soporte')
ORDER BY table_name, ordinal_position;
