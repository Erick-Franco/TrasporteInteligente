-- Script: assign_conductor_route.sql
-- Ubicación: backend/scripts/assign_conductor_route.sql
-- Propósito: Asignar ruta y/o vehículo a un conductor y opcionalmente iniciar un viaje.
-- Ajusta los IDs/licencia según tu base de datos antes de ejecutar.

-- ==============================
-- 1) Asignar RUTA por conductor ID
-- ==============================
-- Ejemplo: asignar ruta_id = 1 al conductor_id = 2
UPDATE conductores
SET ruta_id = 1,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 2;

-- ==============================
-- 2) Asignar RUTA por LICENCIA
-- ==============================
-- Ejemplo: asignar ruta L18 (id=1) al conductor con licencia 'LIC-2024-002'
UPDATE conductores
SET ruta_id = 1,
    updated_at = CURRENT_TIMESTAMP
WHERE licencia = 'LIC-2024-002';

-- ==============================
-- 3) Asignar VEHÍCULO y RUTA juntos
-- ==============================
-- Ejemplo: asignar vehiculo id=3 al conductor id=2 y asignar ruta id=1
UPDATE vehiculos
SET conductor_id = 2,
    estado = 'operativo'
WHERE id = 3;

UPDATE conductores
SET ruta_id = 1,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 2;

-- ==============================
-- 4) Iniciar un VIAJE (poner conductor en servicio)
-- ==============================
-- Importante: verifica que NO exista ya un viaje en progreso para el conductor.
-- Comprueba con la consulta siguiente; si devuelve filas, no crees un nuevo viaje.
-- SELECT id FROM viajes WHERE conductor_id = 2 AND estado = 'en_progreso';

-- Si no hay viaje activo, crea uno (ej: vehiculo_id=1, ruta_id=1, conductor_id=2):
INSERT INTO viajes (vehiculo_id, ruta_id, conductor_id, estado)
VALUES (1, 1, 2, 'en_progreso')
RETURNING id;

-- ==============================
-- 5) Consultas de verificación
-- ==============================
-- Ver conductor y ruta asignada
SELECT id, nombre, licencia, ruta_id FROM conductores WHERE id = 2;

-- Ver vehículo y su conductor
SELECT id, placa, conductor_id, estado FROM vehiculos WHERE id = 1;

-- Ver viajes del conductor
SELECT * FROM viajes WHERE conductor_id = 2 ORDER BY fecha_salida DESC LIMIT 5;

-- ==============================
-- 6) Notas y recomendaciones
-- ==============================
-- - Reemplaza los IDs y la licencia con los valores correctos para tu sistema.
-- - Si usas este script en producción, añade transacciones y validaciones (por ejemplo,
--   verificar que el vehículo no esté asignado a otro conductor, que la ruta exista, etc.).
-- - Para ejecutar desde PowerShell con psql:
--   psql -h localhost -p 5434 -U <user> -d transporte_db -f "d:\Programacion\transporte_inteligente\backend\scripts\assign_conductor_route.sql"
-- - Si prefieres ejecutar sólo ciertas secciones, copia/pega las sentencias necesarias en tu cliente SQL.
