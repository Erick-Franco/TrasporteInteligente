// ============================================
// RUTAS DE ENDPOINTS - CONDUCTORES
// backend/src/routes/conductorRoutes.js
// ============================================

const express = require('express');
const router = express.Router();
const {
    loginConductor,        // ✅ NUEVO - LOGIN
    getAllConductores,
    getConductorById,
    getViajeActual,
    iniciarViaje,
    finalizarViaje
} = require('../controllers/conductorController');

    asignarRutaYVehiculo,
} = require('../controllers/conductorController');

// Asignar ruta y vehículo a conductor
router.put('/:id/asignar', asignarRutaYVehiculo);

// ════════════════════════════════════════════════════════
// 🔐 AUTENTICACIÓN
// ════════════════════════════════════════════════════════

// POST /api/conductores/login - Login de conductor
router.post('/login', loginConductor);  // ✅ NUEVO

// ════════════════════════════════════════════════════════
// 👥 CONDUCTORES
// ════════════════════════════════════════════════════════

// GET /api/conductores - Obtener todos los conductores
router.get('/', getAllConductores);

// GET /api/conductores/:id - Obtener conductor por ID
router.get('/:id', getConductorById);

// GET /api/conductores/:id/viaje-actual - Obtener viaje actual
router.get('/:id/viaje-actual', getViajeActual);

// ════════════════════════════════════════════════════════
// 🚗 VIAJES
// ════════════════════════════════════════════════════════

// POST /api/conductores/viaje/iniciar - Iniciar viaje
router.post('/viaje/iniciar', iniciarViaje);

// PUT /api/conductores/viaje/:id/finalizar - Finalizar viaje
router.put('/viaje/:id/finalizar', finalizarViaje);

module.exports = router;