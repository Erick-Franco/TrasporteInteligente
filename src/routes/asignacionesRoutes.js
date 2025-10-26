// src/routes/asignacionesRoutes.js
const express = require('express');
const router = express.Router();
const { getAsignaciones } = require('../controllers/asignacionesController');

// GET /api/asignaciones - Obtener todas las asignaciones
router.get('/', getAsignaciones);

module.exports = router;
