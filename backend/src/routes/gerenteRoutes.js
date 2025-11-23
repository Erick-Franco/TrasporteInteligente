// ════════════════════════════════════════════════════════
// 🏢 RUTAS DE GERENTES - TRANSPORTE INTELIGENTE
// backend/src/routes/gerenteRoutes.js
// ════════════════════════════════════════════════════════

const express = require('express');
const router = express.Router();
const gerenteController = require('../controllers/gerenteController'); // ✅ CORREGIDO: Mayúscula G
const rutaController = require('../controllers/rutaController');
const { verifyGerenteHeader } = require('../middlewares/gerenteAuth');

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
// Protected version: use header `x-gerente-email` to identify gerente and his ruta
router.get('/me/conductores-activos', verifyGerenteHeader, gerenteController.getConductoresActivos);
// Legacy route (still accepted) but protected: gerente header must match ruta or middleware will restrict
router.get('/:ruta_id/conductores-activos', verifyGerenteHeader, gerenteController.getConductoresActivos);

/**
 * GET /api/gerente/:ruta_id/ruta-completa
 * Obtener ruta completa con puntos GPS y paraderos
 * Query params: ?tipo=ida | ?tipo=vuelta (opcional)
 */
router.get('/me/ruta-completa', verifyGerenteHeader, gerenteController.getRutaCompleta);
router.get('/:ruta_id/ruta-completa', verifyGerenteHeader, gerenteController.getRutaCompleta);

/**
 * GET /api/gerente/me/rutas
 * Obtener la(s) ruta(s) asignada(s) al gerente autenticado
 */
router.get('/me/rutas', verifyGerenteHeader, rutaController.getGerenteRuta);

/**
 * GET /api/gerente/:ruta_id/estadisticas
 * Obtener estadísticas de la línea
 */
router.get('/me/estadisticas', verifyGerenteHeader, gerenteController.getEstadisticasLinea);
router.get('/:ruta_id/estadisticas', verifyGerenteHeader, gerenteController.getEstadisticasLinea);

module.exports = router;