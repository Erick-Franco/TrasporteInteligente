const { query } = require('../config/database');

const eventoController = {
    // Obtener eventos recientes de puntos de control
    getEventosRecientes: async (req, res) => {
        try {
            const { limite = 20 } = req.query;
            
            const result = await query(`
                SELECT 
                    epc.*,
                    pc.nombre as punto_control_nombre,
                    r.nombre as ruta_nombre,
                    r.color as ruta_color,
                    v.placa as vehiculo_placa,
                    c.nombre as conductor_nombre,
                    TO_CHAR(epc.timestamp, 'HH24:MI:SS') as hora,
                    TO_CHAR(epc.timestamp, 'DD/MM/YYYY') as fecha
                FROM eventos_puntos_control epc
                LEFT JOIN puntos_control pc ON epc.punto_control_id = pc.id
                LEFT JOIN rutas r ON pc.ruta_id = r.id
                LEFT JOIN vehiculos v ON epc.vehiculo_id = v.id
                LEFT JOIN conductores c ON epc.conductor_id = c.id
                WHERE epc.timestamp > NOW() - INTERVAL '24 hours'
                ORDER BY epc.timestamp DESC
                LIMIT $1
            `, [limite]);
            
            res.json({
                success: true,
                data: result.rows,
                count: result.rowCount
            });
        } catch (error) {
            console.error('Error en getEventosRecientes:', error);
            res.status(500).json({
                success: false,
                message: 'Error obteniendo eventos recientes',
                error: error.message
            });
        }
    },

    // Obtener todos los eventos con filtros
    getEventosPuntosControl: async (req, res) => {
        try {
            const { fecha, ruta_id, conductor_id, limite = 100 } = req.query;
            
            let whereConditions = ['1=1'];
            let queryParams = [limite];
            let paramCount = 1;

            if (fecha) {
                paramCount++;
                whereConditions.push(`DATE(epc.timestamp) = $${paramCount}`);
                queryParams.push(fecha);
            }

            if (ruta_id) {
                paramCount++;
                whereConditions.push(`pc.ruta_id = $${paramCount}`);
                queryParams.push(ruta_id);
            }

            if (conductor_id) {
                paramCount++;
                whereConditions.push(`epc.conductor_id = $${paramCount}`);
                queryParams.push(conductor_id);
            }

            const result = await query(`
                SELECT 
                    epc.*,
                    pc.nombre as punto_control_nombre,
                    pc.latitud as punto_control_latitud,
                    pc.longitud as punto_control_longitud,
                    r.nombre as ruta_nombre,
                    r.codigo as ruta_codigo,
                    v.placa as vehiculo_placa,
                    c.nombre as conductor_nombre
                FROM eventos_puntos_control epc
                LEFT JOIN puntos_control pc ON epc.punto_control_id = pc.id
                LEFT JOIN rutas r ON pc.ruta_id = r.id
                LEFT JOIN vehiculos v ON epc.vehiculo_id = v.id
                LEFT JOIN conductores c ON epc.conductor_id = c.id
                WHERE ${whereConditions.join(' AND ')}
                ORDER BY epc.timestamp DESC
                LIMIT $1
            `, queryParams);
            
            res.json({
                success: true,
                data: result.rows,
                count: result.rowCount
            });
        } catch (error) {
            console.error('Error en getEventosPuntosControl:', error);
            res.status(500).json({
                success: false,
                message: 'Error obteniendo eventos',
                error: error.message
            });
        }
    },

    // Obtener estadísticas de eventos
    getEstadisticasEventos: async (req, res) => {
        try {
            const { fecha } = req.query;
            
            let whereCondition = '';
            let queryParams = [];

            if (fecha) {
                whereCondition = 'WHERE DATE(epc.timestamp) = $1';
                queryParams.push(fecha);
            }

            const result = await query(`
                SELECT 
                    DATE(epc.timestamp) as fecha,
                    COUNT(*) as total_eventos,
                    COUNT(DISTINCT epc.conductor_id) as conductores_activos,
                    COUNT(DISTINCT epc.vehiculo_id) as vehiculos_activos,
                    COUNT(DISTINCT pc.ruta_id) as rutas_activas
                FROM eventos_puntos_control epc
                LEFT JOIN puntos_control pc ON epc.punto_control_id = pc.id
                ${whereCondition}
                GROUP BY DATE(epc.timestamp)
                ORDER BY fecha DESC
                LIMIT 30
            `, queryParams);
            
            res.json({
                success: true,
                data: result.rows,
                count: result.rowCount
            });
        } catch (error) {
            console.error('Error en getEstadisticasEventos:', error);
            res.status(500).json({
                success: false,
                message: 'Error obteniendo estadísticas',
                error: error.message
            });
        }
    }
};

module.exports = eventoController;