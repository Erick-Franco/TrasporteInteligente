// src/routes/busesActivosRoutes.js
const express = require('express');
const router = express.Router();
const { getBusesActivos } = require('../controllers/busesActivosController');

// GET /api/buses-activos - Obtener todos los buses activos
router.get('/', getBusesActivos);

module.exports = router;
