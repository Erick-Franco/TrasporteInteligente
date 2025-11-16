// ============================================
// RUTAS DE VIAJES
// backend/src/routes/viajesRoutes.js
// ============================================

const express = require('express');
const router = express.Router();
const {
    iniciarViaje,
    finalizarViaje,
    obtenerViajeActivo,
    obtenerViajesActivos,
    obtenerHistorialViajes
} = require('../controllers/viajesController');

// ════════════════════════════════════════════════════════
// 🚀 POST /api/viajes/iniciar - Iniciar un viaje
// ════════════════════════════════════════════════════════
// Body: { vehiculo_id, ruta_id, conductor_id }
router.post('/iniciar', iniciarViaje);

// ════════════════════════════════════════════════════════
// 🛑 PUT /api/viajes/:id/finalizar - Finalizar un viaje
// ════════════════════════════════════════════════════════
router.put('/:id/finalizar', finalizarViaje);

// ════════════════════════════════════════════════════════
// 📋 GET /api/viajes/conductor/:conductor_id/activo
// Obtener viaje activo de un conductor
// ════════════════════════════════════════════════════════
router.get('/conductor/:conductor_id/activo', obtenerViajeActivo);

// ════════════════════════════════════════════════════════
// 📊 GET /api/viajes/activos - Obtener todos los viajes activos
// ════════════════════════════════════════════════════════
router.get('/activos', obtenerViajesActivos);

// ════════════════════════════════════════════════════════
// 📜 GET /api/viajes/historial - Obtener historial de viajes
// Query params: conductor_id, fecha_inicio, fecha_fin, limite
// ════════════════════════════════════════════════════════
router.get('/historial', obtenerHistorialViajes);

module.exports = router;