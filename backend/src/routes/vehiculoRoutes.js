// ============================================
// RUTAS DE VEHÍCULOS
// backend/src/routes/vehiculoRoutes.js
// ============================================

const express = require('express');
const router = express.Router();
const { getAllVehiculos } = require('../controllers/vehiculoController');

// GET /api/vehiculos - Obtener todos los vehiculos
router.get('/', getAllVehiculos);

module.exports = router;
