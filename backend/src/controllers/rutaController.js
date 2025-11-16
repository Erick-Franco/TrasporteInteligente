// ============================================
// CONTROLADOR DE RUTAS
// ============================================

const { query } = require('../config/database');

// Obtener todas las rutas activas
const getAllRutas = async (req, res) => {
    try {
        const result = await query(`
            SELECT id, codigo, nombre, descripcion, color, tarifa, estado 
            FROM rutas 
            WHERE estado = 'activa'
            ORDER BY codigo
        `);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount
        });
    } catch (error) {
        console.error('Error en getAllRutas:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener rutas',
            message: error.message 
        });
    }
};

// Obtener detalles de una ruta específica
const getRutaById = async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await query(`
            SELECT * FROM rutas WHERE id = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                error: 'Ruta no encontrada' 
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0] 
        });
    } catch (error) {
        console.error('Error en getRutaById:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener ruta',
            message: error.message 
        });
    }
};

// Obtener puntos GPS de la ruta (trayectoria completa)
const getRutaPuntos = async (req, res) => {
    try {
        const { id } = req.params;
        const { tipo } = req.query; // 'ida' o 'vuelta'
        
        // Validar tipo
        if (tipo && !['ida', 'vuelta'].includes(tipo)) {
            return res.status(400).json({
                success: false,
                error: 'Tipo debe ser "ida" o "vuelta"'
            });
        }
        
        const result = await query(`
            SELECT latitud, longitud, orden, tipo 
            FROM ruta_puntos 
            WHERE ruta_id = $1 AND tipo = $2
            ORDER BY orden
        `, [id, tipo || 'ida']);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount,
            ruta_id: id,
            tipo: tipo || 'ida'
        });
    } catch (error) {
        console.error('Error en getRutaPuntos:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener puntos de ruta',
            message: error.message 
        });
    }
};

// Obtener paraderos de una ruta
const getRutaParaderos = async (req, res) => {
    try {
        const { id } = req.params;
        const { direccion } = req.query; // 'ida' o 'vuelta'
        
        let queryText = `
            SELECT id, nombre, descripcion, latitud, longitud, orden, direccion, radio_metros
            FROM puntos_control 
            WHERE ruta_id = $1
        `;
        
        const params = [id];
        
        if (direccion) {
            queryText += ` AND direccion = $2`;
            params.push(direccion);
        }
        
        queryText += ` ORDER BY orden`;
        
        const result = await query(queryText, params);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount,
            ruta_id: id
        });
    } catch (error) {
        console.error('Error en getRutaParaderos:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener paraderos',
            message: error.message 
        });
    }
};

// Obtener estadísticas de una ruta
const getRutaEstadisticas = async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await query(`
            SELECT 
                r.codigo,
                r.nombre,
                r.color,
                COUNT(DISTINCT CASE WHEN rp.tipo = 'ida' THEN rp.id END) as puntos_ida,
                COUNT(DISTINCT CASE WHEN rp.tipo = 'vuelta' THEN rp.id END) as puntos_vuelta,
                COUNT(DISTINCT pc.id) as total_paraderos,
                COUNT(DISTINCT v.id) as buses_activos
            FROM rutas r
            LEFT JOIN ruta_puntos rp ON r.id = rp.ruta_id
            LEFT JOIN puntos_control pc ON r.id = pc.ruta_id
            LEFT JOIN viajes v ON r.id = v.ruta_id AND v.estado = 'en_progreso'
            WHERE r.id = $1
            GROUP BY r.id, r.codigo, r.nombre, r.color
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                error: 'Ruta no encontrada' 
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0] 
        });
    } catch (error) {
        console.error('Error en getRutaEstadisticas:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener estadísticas',
            message: error.message 
        });
    }
};

module.exports = {
    getAllRutas,
    getRutaById,
    getRutaPuntos,
    getRutaParaderos,
    getRutaEstadisticas
};