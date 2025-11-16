// ============================================
// RUTAS DE ENDPOINTS - BUSES
// ============================================

const express = require('express');
const router = express.Router();
const {
    getBusesActivos,
    getBusesPorRuta,
    getBusById,
    getBusesCercanos
} = require('../controllers/busController');

// GET /api/buses/activos - Obtener todos los buses activos
router.get('/activos', getBusesActivos);

// GET /api/buses/cercanos?lat=-15.5&lng=-70.13&radio=1 - Buses cercanos
router.get('/cercanos', getBusesCercanos);

// GET /api/buses/ruta/:rutaId - Obtener buses de una ruta
router.get('/ruta/:rutaId', getBusesPorRuta);

// GET /api/buses/:busId - Obtener información de un bus
router.get('/:busId', getBusById);

module.exports = router;