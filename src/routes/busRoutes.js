// src/routes/busRoutes.js
const express = require('express');
const router = express.Router();
const busController = require('../controllers/busController');

// GET /api/buses - Obtener todos los buses activos
router.get('/', busController.getBusesActivos);

// GET /api/buses/:busId - Obtener un bus específico
router.get('/:busId', busController.getBusPorId);

// GET /api/buses/ruta/:rutaId - Obtener buses de una ruta
router.get('/ruta/:rutaId', busController.getBusesPorRuta);

// POST /api/buses/:busId/ubicacion - Actualizar ubicación (GPS Tracker)
router.post('/:busId/ubicacion', busController.actualizarUbicacion);

// GET /api/buses/:busId/historial - Obtener historial de ubicaciones
router.get('/:busId/historial', busController.getHistorialUbicaciones);

module.exports = router;