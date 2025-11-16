// ============================================
// RUTAS DE ENDPOINTS - RUTAS
// ============================================

const express = require('express');
const router = express.Router();
const {
    getAllRutas,
    getRutaById,
    getRutaPuntos,
    getRutaParaderos,
    getRutaEstadisticas
} = require('../controllers/rutaController');

// GET /api/rutas - Obtener todas las rutas
router.get('/', getAllRutas);

// GET /api/rutas/:id - Obtener detalles de una ruta
router.get('/:id', getRutaById);

// GET /api/rutas/:id/puntos?tipo=ida|vuelta - Obtener puntos GPS
router.get('/:id/puntos', getRutaPuntos);

// GET /api/rutas/:id/paraderos?direccion=ida|vuelta - Obtener paraderos
router.get('/:id/paraderos', getRutaParaderos);

// GET /api/rutas/:id/estadisticas - Obtener estadísticas
router.get('/:id/estadisticas', getRutaEstadisticas);

module.exports = router;