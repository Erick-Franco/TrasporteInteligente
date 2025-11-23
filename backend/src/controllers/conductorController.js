// ============================================
// CONTROLADOR DE CONDUCTORES
// backend/src/controllers/conductorController.js
// ============================================

const { query, pool } = require('../config/database');

// ════════════════════════════════════════════════════════
// 🔐 LOGIN DE CONDUCTOR (ARREGLADO)
// ════════════════════════════════════════════════════════

const loginConductor = async (req, res) => {
    try {
        const { licencia, password } = req.body;

        console.log('🔐 Intento de login:', { licencia });

        if (!licencia || !password) {
            return res.status(400).json({
                success: false,
                message: 'Licencia y contraseña son requeridos',
            });
        }

        // ✅ ARREGLADO: JOIN directo con rutas desde conductores.ruta_id
        const result = await query(`
            SELECT 
                c.id,
                c.nombre,
                c.licencia,
                c.email,
                c.telefono,
                c.estado,
                c.created_at,
                c.ruta_id,
                v.id as vehiculo_id,
                v.placa,
                v.modelo,
                v.capacidad,
                r.nombre as ruta_nombre,
                r.codigo as ruta_codigo,
                r.color as ruta_color,
                vi.id as viaje_id,
                vi.estado as viaje_estado
            FROM conductores c
            LEFT JOIN vehiculos v ON v.conductor_id = c.id
            LEFT JOIN rutas r ON r.id = c.ruta_id
            LEFT JOIN viajes vi ON vi.conductor_id = c.id AND vi.estado = 'en_progreso'
            WHERE (c.licencia = $1 OR c.email = $1)
                AND c.password_hash = crypt($2, c.password_hash)
                AND c.estado = 'activo'
            LIMIT 1
        `, [licencia, password]);

        if (result.rows.length === 0) {
            console.log('❌ Login fallido: Credenciales incorrectas o conductor inactivo');
            return res.status(401).json({
                success: false,
                message: 'Credenciales incorrectas o conductor inactivo',
            });
        }

        const conductor = result.rows[0];
        console.log('✅ Login exitoso:', conductor.nombre);

        res.json({
            success: true,
            data: conductor,
            message: 'Login exitoso',
        });
    } catch (error) {
        console.error('❌ Error en login:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// ════════════════════════════════════════════════════════
// 👥 OBTENER CONDUCTORES
// ════════════════════════════════════════════════════════

// Obtener todos los conductores activos
const getAllConductores = async (req, res) => {
    try {
        // ✅ CAMBIO: activo → estado
        const result = await query(`
            SELECT id, nombre, licencia, telefono, email, estado
            FROM conductores
            WHERE estado = 'activo'
            ORDER BY nombre
        `);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount
        });
    } catch (error) {
        console.error('Error en getAllConductores:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener conductores',
            message: error.message 
        });
    }
};

// Obtener conductor por ID
const getConductorById = async (req, res) => {
    try {
        const { id } = req.params;
        
        // ✅ CAMBIO: c.activo → c.estado
        const result = await query(`
            SELECT 
                c.id,
                c.nombre,
                c.licencia,
                c.telefono,
                c.email,
                c.estado,
                v.id as vehiculo_id,
                v.placa,
                v.modelo,
                vi.id as viaje_id,
                vi.estado as viaje_estado,
                vi.ruta_id,
                r.nombre as ruta_nombre,
                r.codigo as ruta_codigo
            FROM conductores c
            LEFT JOIN vehiculos v ON v.conductor_id = c.id
            LEFT JOIN viajes vi ON vi.conductor_id = c.id AND vi.estado = 'en_progreso'
            LEFT JOIN rutas r ON vi.ruta_id = r.id
            WHERE c.id = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                error: 'Conductor no encontrado' 
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0] 
        });
    } catch (error) {
        console.error('Error en getConductorById:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener conductor',
            message: error.message 
        });
    }
};

// ════════════════════════════════════════════════════════
// 🚗 VIAJES
// ════════════════════════════════════════════════════════

// Obtener viaje actual del conductor
const getViajeActual = async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await query(`
            SELECT 
                v.id as viaje_id,
                v.fecha_salida,
                v.estado,
                v.vehiculo_id,
                v.ruta_id,
                v.conductor_id,
                r.codigo,
                r.nombre as ruta_nombre,
                r.color as ruta_color,
                ve.placa,
                ve.modelo
            FROM viajes v
            JOIN rutas r ON v.ruta_id = r.id
            JOIN vehiculos ve ON v.vehiculo_id = ve.id
            WHERE v.conductor_id = $1 AND v.estado = 'en_progreso'
            LIMIT 1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.json({ 
                success: true, 
                data: null,
                message: 'No hay viaje activo' 
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0] 
        });
    } catch (error) {
        console.error('Error en getViajeActual:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener viaje actual',
            message: error.message 
        });
    }
};

// Iniciar viaje
const iniciarViaje = async (req, res) => {
    try {
        const { conductor_id, vehiculo_id, ruta_id } = req.body;
        
        if (!conductor_id || !vehiculo_id || !ruta_id) {
            return res.status(400).json({
                success: false,
                error: 'Se requieren: conductor_id, vehiculo_id, ruta_id'
            });
        }
        
        // Verificar si ya tiene viaje activo
        const viajeActivo = await query(`
            SELECT id FROM viajes 
            WHERE conductor_id = $1 AND estado = 'en_progreso'
        `, [conductor_id]);
        
        if (viajeActivo.rows.length > 0) {
            return res.status(400).json({
                success: false,
                error: 'El conductor ya tiene un viaje activo'
            });
        }
        
        const result = await query(`
            INSERT INTO viajes (vehiculo_id, ruta_id, conductor_id, estado)
            VALUES ($1, $2, $3, 'en_progreso')
            RETURNING *
        `, [vehiculo_id, ruta_id, conductor_id]);
        
        res.json({ 
            success: true, 
            data: result.rows[0],
            message: 'Viaje iniciado exitosamente'
        });
    } catch (error) {
        console.error('Error en iniciarViaje:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al iniciar viaje',
            message: error.message 
        });
    }
};

// Finalizar viaje
const finalizarViaje = async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await query(`
            UPDATE viajes 
            SET estado = 'completado', fecha_llegada = CURRENT_TIMESTAMP
            WHERE id = $1 AND estado = 'en_progreso'
            RETURNING *
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Viaje no encontrado o ya finalizado'
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0],
            message: 'Viaje finalizado exitosamente'
        });
    } catch (error) {
        console.error('Error en finalizarViaje:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al finalizar viaje',
            message: error.message 
        });
    }
};

// ════════════════════════════════════════════════════════
// 🛠️ ASIGNAR RUTA Y VEHÍCULO A UN CONDUCTOR
// ════════════════════════════════════════════════════════
const asignarRutaYVehiculo = async (req, res) => {
    const conductorId = req.params.id;
    const { ruta_id, vehiculo_id } = req.body;

    if (!ruta_id && !vehiculo_id) {
        return res.status(400).json({ success: false, error: 'Se requiere ruta_id o vehiculo_id' });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Si pasaron ruta_id, actualizar conductores.ruta_id
        if (ruta_id) {
            await client.query(
                'UPDATE conductores SET ruta_id = $1 WHERE id = $2',
                [ruta_id, conductorId]
            );
        }

        // Si pasaron vehiculo_id, reasignar vehículo al conductor
        if (vehiculo_id) {
            // Opcional: liberar vehículo anterior del conductor (si existiera)
            await client.query(
                'UPDATE vehiculos SET conductor_id = NULL WHERE conductor_id = $1',
                [conductorId]
            );

            // Asignar el vehículo seleccionado al conductor
            await client.query(
                'UPDATE vehiculos SET conductor_id = $1 WHERE id = $2',
                [conductorId, vehiculo_id]
            );
        }

        await client.query('COMMIT');

        res.json({ success: true, message: 'Asignación guardada' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error al asignar ruta/vehículo:', error);
        res.status(500).json({ success: false, error: error.message });
    } finally {
        client.release();
    }
};

// ════════════════════════════════════════════════════════
// 📤 EXPORTS
// ════════════════════════════════════════════════════════

module.exports = {
    loginConductor,        // ✅ ARREGLADO - LOGIN
    getAllConductores,
    getConductorById,
    getViajeActual,
    iniciarViaje,
    finalizarViaje,
    asignarRutaYVehiculo
};