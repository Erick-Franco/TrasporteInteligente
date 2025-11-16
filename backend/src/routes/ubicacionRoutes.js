// ============================================
// RUTAS DE ENDPOINTS - UBICACIONES GPS
// ============================================

const express = require('express');
const router = express.Router();
const {
    enviarUbicacion,
    getUltimaUbicacion,
    getHistorialUbicaciones,
    registrarParadero,
    limpiarUbicacionesAntiguas
} = require('../controllers/ubicacionController');

// POST /api/ubicaciones - Enviar ubicación GPS
router.post('/', enviarUbicacion);

// GET /api/ubicaciones/conductor/:conductorId/ultima - Última ubicación
router.get('/conductor/:conductorId/ultima', getUltimaUbicacion);

// GET /api/ubicaciones/viaje/:viajeId?limit=100 - Historial de ubicaciones
router.get('/viaje/:viajeId', getHistorialUbicaciones);

// POST /api/ubicaciones/paradero - Registrar paso por paradero
router.post('/paradero', registrarParadero);

// DELETE /api/ubicaciones/limpiar - Limpiar ubicaciones antiguas
router.delete('/limpiar', limpiarUbicacionesAntiguas);

module.exports = router;