// ════════════════════════════════════════════════════════
// 🏢 RUTAS DE GERENTES - TRANSPORTE INTELIGENTE
// backend/src/routes/gerenteRoutes.js
// ════════════════════════════════════════════════════════

const express = require('express');
const router = express.Router();
const gerenteController = require('../controllers/gerenteController'); // ✅ CORREGIDO: Mayúscula G

// ════════════════════════════════════════════════════════
// 🔐 AUTENTICACIÓN
// ════════════════════════════════════════════════════════

/**
 * POST /api/gerente/login
 * Login del gerente
 * Body: { email, password }
 */
router.post('/login', gerenteController.loginGerente);

// ════════════════════════════════════════════════════════
// 🚌 DATOS DE LA LÍNEA
// ════════════════════════════════════════════════════════

/**
 * GET /api/gerente/:ruta_id/conductores-activos
 * Obtener todos los conductores activos de una línea específica
 */
router.get('/:ruta_id/conductores-activos', gerenteController.getConductoresActivos);

/**
 * GET /api/gerente/:ruta_id/ruta-completa
 * Obtener ruta completa con puntos GPS y paraderos
 * Query params: ?tipo=ida | ?tipo=vuelta (opcional)
 */
router.get('/:ruta_id/ruta-completa', gerenteController.getRutaCompleta);

/**
 * GET /api/gerente/:ruta_id/estadisticas
 * Obtener estadísticas de la línea
 */
router.get('/:ruta_id/estadisticas', gerenteController.getEstadisticasLinea);

module.exports = router;