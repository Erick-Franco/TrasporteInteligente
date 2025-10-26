// src/routes/conductoresRoutes.js
const express = require('express');
const router = express.Router();
const { getConductores } = require('../controllers/conductoresController');

// GET /api/conductores - Obtener todos los conductores
router.get('/', getConductores);

module.exports = router;
