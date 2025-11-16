// ============================================
// RUTAS DE ENDPOINTS - CHAT GLOBAL
// ============================================

const express = require('express');
const router = express.Router();
const {
    getHistorialMensajes,
    enviarMensaje,
    limpiarMensajesAntiguos
} = require('../controllers/chatController');

// GET /api/chat/mensajes?limit=50 - Obtener historial
router.get('/mensajes', getHistorialMensajes);

// POST /api/chat/enviar - Enviar mensaje (también funciona por WebSocket)
router.post('/enviar', enviarMensaje);

// DELETE /api/chat/limpiar - Limpiar mensajes antiguos
router.delete('/limpiar', limpiarMensajesAntiguos);

module.exports = router;