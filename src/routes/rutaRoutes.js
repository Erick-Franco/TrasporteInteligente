// src/routes/rutaRoutes.js
const express = require('express');
const router = express.Router();
const rutaController = require('../controllers/rutaController');

// GET /api/rutas - Obtener todas las rutas
router.get('/', rutaController.getRutas);

// GET /api/rutas/:rutaId - Obtener detalles de una ruta con coordenadas de ida y vuelta
router.get('/:rutaId', rutaController.getRutaConCoordenadas);

/*
// --- RUTAS DESACTIVADAS TEMPORALMENTE ---

// GET /api/rutas/paradas/cercanas - Buscar paradas cercanas
router.get('/paradas/cercanas', rutaController.getParadasCercanas);

// POST /api/rutas/calcular - Calcular mejor ruta
router.post('/calcular', rutaController.calcularMejorRuta);
*/

module.exports = router;
