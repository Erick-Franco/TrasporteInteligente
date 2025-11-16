// ============================================
// CONTROLADOR DE BUSES
// ============================================

const { query } = require('../config/database');

// Obtener todos los buses activos con ubicación GPS
const getBusesActivos = async (req, res) => {
    try {
        const result = await query(`
            SELECT * FROM vista_buses_activos
        `);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount,
            timestamp: new Date()
        });
    } catch (error) {
        console.error('Error en getBusesActivos:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener buses activos',
            message: error.message 
        });
    }
};

// Obtener buses de una ruta específica
const getBusesPorRuta = async (req, res) => {
    try {
        const { rutaId } = req.params;
        
        const result = await query(`
            SELECT 
                c.id as conductor_id,
                c.nombre as conductor_nombre,
                v.id as vehiculo_id,
                v.placa,
                v.modelo,
                v.capacidad,
                ubt.latitud,
                ubt.longitud,
                ubt.velocidad,
                ubt.direccion,
                ubt.timestamp as ultima_actualizacion
            FROM viajes vi
            JOIN vehiculos v ON vi.vehiculo_id = v.id
            JOIN conductores c ON vi.conductor_id = c.id
            LEFT JOIN LATERAL (
                SELECT * FROM ubicaciones_tiempo_real
                WHERE conductor_id = c.id
                ORDER BY timestamp DESC
                LIMIT 1
            ) ubt ON true
            WHERE vi.ruta_id = $1 AND vi.estado = 'en_progreso'
        `, [rutaId]);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount,
            ruta_id: rutaId
        });
    } catch (error) {
        console.error('Error en getBusesPorRuta:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener buses por ruta',
            message: error.message 
        });
    }
};

// Obtener información de un bus específico
const getBusById = async (req, res) => {
    try {
        const { busId } = req.params;
        
        const result = await query(`
            SELECT * FROM vista_buses_activos
            WHERE vehiculo_id = $1
        `, [busId]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                error: 'Bus no encontrado' 
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0] 
        });
    } catch (error) {
        console.error('Error en getBusById:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener información del bus',
            message: error.message 
        });
    }
};

// Obtener buses cercanos a un punto
const getBusesCercanos = async (req, res) => {
    try {
        const { lat, lng, radio } = req.query;
        
        if (!lat || !lng) {
            return res.status(400).json({
                success: false,
                error: 'Se requieren parámetros: lat y lng'
            });
        }
        
        const radioKm = radio || 1.0;
        
        const result = await query(`
            SELECT * FROM buses_cercanos($1, $2, $3)
        `, [parseFloat(lat), parseFloat(lng), parseFloat(radioKm)]);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount,
            punto: { lat: parseFloat(lat), lng: parseFloat(lng) },
            radio_km: parseFloat(radioKm)
        });
    } catch (error) {
        console.error('Error en getBusesCercanos:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al buscar buses cercanos',
            message: error.message 
        });
    }
};

module.exports = {
    getBusesActivos,
    getBusesPorRuta,
    getBusById,
    getBusesCercanos
};