const express = require('express');
const router = express.Router();
const eventoController = require('../controllers/eventoController');

// ✅ FORMATO CORRECTO
router.get('/recientes', eventoController.getEventosRecientes);
router.get('/puntos-control', eventoController.getEventosPuntosControl);
router.get('/estadisticas', eventoController.getEstadisticasEventos);

module.exports = router;