// src/routes/rutaParadasRoutes.js
const express = require('express');
const router = express.Router();
const { getRutaParadas } = require('../controllers/rutaParadasController');

// GET /api/ruta-paradas - Obtener todas las paradas de las rutas
router.get('/', getRutaParadas);

module.exports = router;
