// ============================================
// CONTROLADOR DE UBICACIONES GPS
// ============================================

const { query } = require('../config/database');

// Enviar ubicación GPS del conductor (desde app móvil)
const enviarUbicacion = async (req, res) => {
    try {
        const { conductor_id, vehiculo_id, ruta_id, latitud, longitud, velocidad, direccion, altitud } = req.body;
        
        // Validar datos requeridos
        if (!conductor_id || !latitud || !longitud) {
            return res.status(400).json({ 
                success: false, 
                error: 'Faltan datos requeridos: conductor_id, latitud, longitud' 
            });
        }
        
        const result = await query(`
            INSERT INTO ubicaciones_tiempo_real 
            (conductor_id, vehiculo_id, ruta_id, latitud, longitud, velocidad, direccion, altitud)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
        `, [
            conductor_id, 
            vehiculo_id, 
            ruta_id, 
            latitud, 
            longitud, 
            velocidad || 0, 
            direccion || 0,
            altitud || 0
        ]);
        
        // Aquí puedes emitir evento WebSocket si lo implementas
        // io.emit('location-update', result.rows[0]);
        
        res.json({ 
            success: true, 
            data: result.rows[0],
            message: 'Ubicación actualizada'
        });
    } catch (error) {
        console.error('Error en enviarUbicacion:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al enviar ubicación',
            message: error.message 
        });
    }
};

// Obtener última ubicación de un conductor
const getUltimaUbicacion = async (req, res) => {
    try {
        const { conductorId } = req.params;
        
        const result = await query(`
            SELECT * FROM ubicaciones_tiempo_real
            WHERE conductor_id = $1
            ORDER BY timestamp DESC
            LIMIT 1
        `, [conductorId]);
        
        if (result.rows.length === 0) {
            return res.json({ 
                success: true, 
                data: null,
                message: 'No hay ubicación registrada' 
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0] 
        });
    } catch (error) {
        console.error('Error en getUltimaUbicacion:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener ubicación',
            message: error.message 
        });
    }
};

// Obtener historial de ubicaciones de un viaje
const getHistorialUbicaciones = async (req, res) => {
    try {
        const { viajeId } = req.params;
        const { limit } = req.query;
        
        // Obtener conductor_id del viaje
        const viaje = await query(`
            SELECT conductor_id FROM viajes WHERE id = $1
        `, [viajeId]);
        
        if (viaje.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Viaje no encontrado'
            });
        }
        
        const conductorId = viaje.rows[0].conductor_id;
        
        const result = await query(`
            SELECT * FROM ubicaciones_tiempo_real
            WHERE conductor_id = $1
            ORDER BY timestamp DESC
            LIMIT $2
        `, [conductorId, limit || 100]);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount,
            viaje_id: viajeId
        });
    } catch (error) {
        console.error('Error en getHistorialUbicaciones:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener historial',
            message: error.message 
        });
    }
};

// Registrar paso por paradero
const registrarParadero = async (req, res) => {
    try {
        const { viaje_id, punto_control_id, vehiculo_id, conductor_id, latitud, longitud } = req.body;
        
        if (!viaje_id || !punto_control_id || !latitud || !longitud) {
            return res.status(400).json({
                success: false,
                error: 'Faltan datos requeridos'
            });
        }
        
        const result = await query(`
            INSERT INTO eventos_puntos_control 
            (viaje_id, punto_control_id, vehiculo_id, conductor_id, latitud, longitud)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *
        `, [viaje_id, punto_control_id, vehiculo_id, conductor_id, latitud, longitud]);
        
        res.json({ 
            success: true, 
            data: result.rows[0],
            message: 'Paso por paradero registrado'
        });
    } catch (error) {
        console.error('Error en registrarParadero:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al registrar paradero',
            message: error.message 
        });
    }
};

// Limpiar ubicaciones antiguas
const limpiarUbicacionesAntiguas = async (req, res) => {
    try {
        const result = await query(`
            SELECT limpiar_ubicaciones_antiguas() as eliminadas
        `);
        
        res.json({ 
            success: true, 
            eliminadas: result.rows[0].eliminadas,
            message: 'Ubicaciones antiguas eliminadas'
        });
    } catch (error) {
        console.error('Error en limpiarUbicacionesAntiguas:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al limpiar ubicaciones',
            message: error.message 
        });
    }
};

module.exports = {
    enviarUbicacion,
    getUltimaUbicacion,
    getHistorialUbicaciones,
    registrarParadero,
    limpiarUbicacionesAntiguas
};