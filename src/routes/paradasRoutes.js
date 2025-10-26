// src/routes/paradasRoutes.js
const express = require('express');
const router = express.Router();
const { getParadas } = require('../controllers/paradasController');

// GET /api/paradas - Obtener todas las paradas
router.get('/', getParadas);

module.exports = router;
