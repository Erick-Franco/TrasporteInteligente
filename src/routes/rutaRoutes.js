// src/routes/rutaRoutes.js
const express = require('express');
const router = express.Router();
const rutaController = require('../controllers/rutaController');

// GET /api/rutas - Obtener todas las rutas
router.get('/', rutaController.getRutas);

// GET /api/rutas/geojson - Obtener todas las rutas en formato GeoJSON
router.get('/geojson', rutaController.getRutasGeoJSON);

// GET /api/rutas/:rutaId/coordenadas - Obtener coordenadas de una ruta específica
router.get('/:rutaId/coordenadas', rutaController.getRutaCoordenadas);

// GET /api/rutas/:rutaId - Obtener detalles de una ruta con paradas
router.get('/:rutaId', rutaController.getRutaConParadas);

// GET /api/rutas/paradas/cercanas - Buscar paradas cercanas
router.get('/paradas/cercanas', rutaController.getParadasCercanas);

// POST /api/rutas/calcular - Calcular mejor ruta
router.post('/calcular', rutaController.calcularMejorRuta);

module.exports = router;