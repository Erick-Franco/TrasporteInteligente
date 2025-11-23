// ============================================
// CONTROLADOR DE VIAJES
// backend/src/controllers/viajesController.js
// ============================================

const { query } = require('../config/database');

// ════════════════════════════════════════════════════════
// 🚀 INICIAR VIAJE
// ════════════════════════════════════════════════════════
const iniciarViaje = async (req, res) => {
    try {
        const { vehiculo_id, ruta_id, conductor_id } = req.body;
        
        console.log('🚀 Iniciando viaje...');
        console.log('   Vehículo ID:', vehiculo_id);
        console.log('   Ruta ID:', ruta_id);
        console.log('   Conductor ID:', conductor_id);
        
        // Validaciones
        if (!vehiculo_id || !ruta_id || !conductor_id) {
            return res.status(400).json({
                success: false,
                error: 'Se requieren: vehiculo_id, ruta_id y conductor_id'
            });
        }
        
        // Verificar si el conductor ya tiene un viaje activo
        const viajeActivoCheck = await query(`
            SELECT id, estado 
            FROM viajes 
            WHERE conductor_id = $1 
            AND estado = 'en_progreso'
            LIMIT 1
        `, [conductor_id]);
        
        if (viajeActivoCheck.rows.length > 0) {
            return res.status(400).json({
                success: false,
                error: 'El conductor ya tiene un viaje activo',
                viaje_activo: viajeActivoCheck.rows[0]
            });
        }
        
        // Obtener ubicación actual del conductor (si existe)
        const ubicacionResult = await query(`
            SELECT latitud, longitud
            FROM ubicaciones
            WHERE conductor_id = $1
            ORDER BY timestamp DESC
            LIMIT 1
        `, [conductor_id]);
        
        const ubicacion = ubicacionResult.rows[0] || { latitud: null, longitud: null };
        
        // Crear nuevo viaje
        const result = await query(`
            INSERT INTO viajes (
                vehiculo_id, 
                ruta_id, 
                conductor_id,
                fecha_salida,
                estado
            )
            VALUES ($1, $2, $3, CURRENT_TIMESTAMP, 'en_progreso')
            RETURNING *
        `, [vehiculo_id, ruta_id, conductor_id]);
        
        const viaje = result.rows[0];
        
        console.log('✅ Viaje creado:', viaje.id);
        
        // Emitir evento por WebSocket
        if (req.io) {
            req.io.emit('viaje-iniciado', {
                viaje_id: viaje.id,
                conductor_id: conductor_id,
                vehiculo_id: vehiculo_id,
                ruta_id: ruta_id,
                fecha_salida: viaje.fecha_salida,
                estado: viaje.estado
            });
            console.log('📡 Evento viaje-iniciado emitido');
        }
        
        res.json({
            success: true,
            data: viaje,
            message: 'Viaje iniciado correctamente'
        });
        
    } catch (error) {
        console.error('❌ Error en iniciarViaje:', error);
        res.status(500).json({
            success: false,
            error: 'Error al iniciar viaje',
            message: error.message
        });
    }
};

// ════════════════════════════════════════════════════════
// 🛑 FINALIZAR VIAJE
// ════════════════════════════════════════════════════════
const finalizarViaje = async (req, res) => {
    try {
        const { id } = req.params;
        
        console.log('🛑 Finalizando viaje:', id);
        
        if (!id) {
            return res.status(400).json({
                success: false,
                error: 'Se requiere el ID del viaje'
            });
        }
        
        // Verificar que el viaje existe y está en progreso
        const viajeCheck = await query(`
            SELECT * FROM viajes WHERE id = $1
        `, [id]);
        
        if (viajeCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Viaje no encontrado'
            });
        }
        
        const viaje = viajeCheck.rows[0];
        
        if (viaje.estado !== 'en_progreso') {
            return res.status(400).json({
                success: false,
                error: `El viaje ya está en estado: ${viaje.estado}`
            });
        }
        
        // Obtener ubicación final del conductor
        const ubicacionResult = await query(`
            SELECT latitud, longitud
            FROM ubicaciones
            WHERE conductor_id = $1
            ORDER BY timestamp DESC
            LIMIT 1
        `, [viaje.conductor_id]);
        
        const ubicacionFinal = ubicacionResult.rows[0] || { latitud: null, longitud: null };
        
        // Actualizar viaje
        const result = await query(`
            UPDATE viajes 
            SET 
                fecha_llegada = CURRENT_TIMESTAMP,
                estado = 'completado'
            WHERE id = $1
            RETURNING *
        `, [id]);
        
        const viajeActualizado = result.rows[0];
        
        console.log('✅ Viaje finalizado:', id);
        
        // Emitir evento por WebSocket
        if (req.io) {
            req.io.emit('viaje-finalizado', {
                viaje_id: viajeActualizado.id,
                conductor_id: viajeActualizado.conductor_id,
                vehiculo_id: viajeActualizado.vehiculo_id,
                ruta_id: viajeActualizado.ruta_id,
                fecha_salida: viajeActualizado.fecha_salida,
                fecha_llegada: viajeActualizado.fecha_llegada,
                estado: viajeActualizado.estado
            });
            console.log('📡 Evento viaje-finalizado emitido');
        }
        
        res.json({
            success: true,
            data: viajeActualizado,
            message: 'Viaje finalizado correctamente'
        });
        
    } catch (error) {
        console.error('❌ Error en finalizarViaje:', error);
        res.status(500).json({
            success: false,
            error: 'Error al finalizar viaje',
            message: error.message
        });
    }
};

// ════════════════════════════════════════════════════════
// 📋 OBTENER VIAJE ACTIVO DE UN CONDUCTOR
// ════════════════════════════════════════════════════════
const obtenerViajeActivo = async (req, res) => {
    try {
        const { conductor_id } = req.params;
        
        const result = await query(`
            SELECT 
                v.*,
                r.nombre as ruta_nombre,
                r.codigo as ruta_codigo,
                ve.placa as vehiculo_placa
            FROM viajes v
            LEFT JOIN rutas r ON v.ruta_id = r.id
            LEFT JOIN vehiculos ve ON v.vehiculo_id = ve.id
            WHERE v.conductor_id = $1 
            AND v.estado = 'en_progreso'
            ORDER BY v.fecha_salida DESC
            LIMIT 1
        `, [conductor_id]);
        
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
        console.error('❌ Error en obtenerViajeActivo:', error);
        res.status(500).json({
            success: false,
            error: 'Error al obtener viaje activo',
            message: error.message
        });
    }
};

// ════════════════════════════════════════════════════════
// 📊 OBTENER TODOS LOS VIAJES ACTIVOS
// ════════════════════════════════════════════════════════
const obtenerViajesActivos = async (req, res) => {
    try {
        const result = await query(`
            SELECT 
                v.*,
                c.nombre as conductor_nombre,
                r.nombre as ruta_nombre,
                r.codigo as ruta_codigo,
                ve.placa as vehiculo_placa,
                u.latitud as ultima_latitud,
                u.longitud as ultima_longitud,
                u.velocidad,
                u.direccion
            FROM viajes v
            LEFT JOIN conductores c ON v.conductor_id = c.id
            LEFT JOIN rutas r ON v.ruta_id = r.id
            LEFT JOIN vehiculos ve ON v.vehiculo_id = ve.id
            LEFT JOIN LATERAL (
                SELECT latitud, longitud, velocidad, direccion
                FROM ubicaciones_tiempo_real
                WHERE conductor_id = v.conductor_id
                ORDER BY timestamp DESC
                LIMIT 1
            ) u ON true
            WHERE v.estado = 'en_progreso'
            ORDER BY v.fecha_salida DESC
        `);
        
        res.json({
            success: true,
            data: result.rows,
            total: result.rowCount
        });
        
    } catch (error) {
        console.error('❌ Error en obtenerViajesActivos:', error);
        res.status(500).json({
            success: false,
            error: 'Error al obtener viajes activos',
            message: error.message
        });
    }
};

// ════════════════════════════════════════════════════════
// 📜 OBTENER HISTORIAL DE VIAJES
// ════════════════════════════════════════════════════════
const obtenerHistorialViajes = async (req, res) => {
    try {
        const { conductor_id, fecha_inicio, fecha_fin, limite } = req.query;
        
        let queryText = `
            SELECT 
                v.*,
                c.nombre as conductor_nombre,
                r.nombre as ruta_nombre,
                r.codigo as ruta_codigo,
                ve.placa as vehiculo_placa
            FROM viajes v
            LEFT JOIN conductores c ON v.conductor_id = c.id
            LEFT JOIN rutas r ON v.ruta_id = r.id
            LEFT JOIN vehiculos ve ON v.vehiculo_id = ve.id
            WHERE 1=1
        `;
        
        const params = [];
        let paramCount = 1;
        
        if (conductor_id) {
            queryText += ` AND v.conductor_id = $${paramCount}`;
            params.push(conductor_id);
            paramCount++;
        }
        
        if (fecha_inicio) {
            queryText += ` AND v.fecha_salida >= $${paramCount}`;
            params.push(fecha_inicio);
            paramCount++;
        }
        
        if (fecha_fin) {
            queryText += ` AND v.fecha_salida <= $${paramCount}`;
            params.push(fecha_fin);
            paramCount++;
        }
        
        queryText += ` ORDER BY v.fecha_salida DESC`;
        
        if (limite) {
            queryText += ` LIMIT $${paramCount}`;
            params.push(parseInt(limite));
        } else {
            queryText += ` LIMIT 50`;
        }
        
        const result = await query(queryText, params);
        
        res.json({
            success: true,
            data: result.rows,
            total: result.rowCount
        });
        
    } catch (error) {
        console.error('❌ Error en obtenerHistorialViajes:', error);
        res.status(500).json({
            success: false,
            error: 'Error al obtener historial de viajes',
            message: error.message
        });
    }
};

module.exports = {
    iniciarViaje,
    finalizarViaje,
    obtenerViajeActivo,
    obtenerViajesActivos,
    obtenerHistorialViajes
};