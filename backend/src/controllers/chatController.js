// ============================================
// CONTROLADOR DE CHAT GLOBAL
// backend/src/controllers/chatController.js
// ============================================

const { query } = require('../config/database');

// Obtener historial de mensajes
const getHistorialMensajes = async (req, res) => {
    try {
        const { limit } = req.query;
        
        const result = await query(`
            SELECT 
                id,
                usuario_nombre,
                usuario_id,
                mensaje,
                tipo,
                timestamp
            FROM mensajes_chat
            ORDER BY timestamp DESC
            LIMIT $1
        `, [limit || 50]);
        
        // Revertir para que los más antiguos estén primero
        const mensajes = result.rows.reverse();
        
        res.json({ 
            success: true, 
            data: mensajes,
            total: result.rowCount
        });
    } catch (error) {
        console.error('Error en getHistorialMensajes:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener mensajes',
            message: error.message 
        });
    }
};

// ✅ ARREGLADO: Emitir mensaje UNA SOLA VEZ
const enviarMensaje = async (req, res) => {
    try {
        const { usuario_nombre, usuario_id, mensaje } = req.body;
        
        if (!usuario_nombre || !mensaje) {
            return res.status(400).json({
                success: false,
                error: 'Se requieren: usuario_nombre y mensaje'
            });
        }
        
        // Guardar en base de datos
        const result = await query(`
            INSERT INTO mensajes_chat (usuario_nombre, usuario_id, mensaje, tipo)
            VALUES ($1, $2, $3, 'texto')
            RETURNING *
        `, [usuario_nombre, usuario_id, mensaje]);
        
        const mensajeGuardado = result.rows[0];
        
        // ✅ EMITIR VIA WEBSOCKET UNA SOLA VEZ
        if (req.io) {
            const mensajeParaEmitir = {
                id: mensajeGuardado.id,
                usuario_nombre: mensajeGuardado.usuario_nombre,
                usuario_id: mensajeGuardado.usuario_id,
                mensaje: mensajeGuardado.mensaje,
                tipo: mensajeGuardado.tipo,
                timestamp: mensajeGuardado.timestamp
            };
            
            // Emitir solo una vez
            req.io.emit('chat-message', mensajeParaEmitir);
            
            console.log(`💬 Mensaje emitido via WebSocket: ${usuario_nombre}: ${mensaje}`);
        }
        
        res.json({ 
            success: true, 
            data: mensajeGuardado,
            message: 'Mensaje enviado'
        });
    } catch (error) {
        console.error('❌ Error en enviarMensaje:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al enviar mensaje',
            message: error.message 
        });
    }
};

// Limpiar mensajes antiguos (más de 7 días)
const limpiarMensajesAntiguos = async (req, res) => {
    try {
        const result = await query(`
            DELETE FROM mensajes_chat
            WHERE timestamp < NOW() - INTERVAL '7 days'
            RETURNING id
        `);
        
        res.json({ 
            success: true, 
            eliminados: result.rowCount,
            message: 'Mensajes antiguos eliminados'
        });
    } catch (error) {
        console.error('Error en limpiarMensajesAntiguos:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al limpiar mensajes',
            message: error.message 
        });
    }
};

// Guardar mensaje (usado internamente)
const guardarMensaje = async (usuario_nombre, usuario_id, mensaje, tipo = 'texto') => {
    try {
        const result = await query(`
            INSERT INTO mensajes_chat (usuario_nombre, usuario_id, mensaje, tipo)
            VALUES ($1, $2, $3, $4)
            RETURNING *
        `, [usuario_nombre, usuario_id, mensaje, tipo]);
        
        return result.rows[0];
    } catch (error) {
        console.error('Error al guardar mensaje:', error);
        throw error;
    }
};

module.exports = {
    getHistorialMensajes,
    enviarMensaje,
    limpiarMensajesAntiguos,
    guardarMensaje
};