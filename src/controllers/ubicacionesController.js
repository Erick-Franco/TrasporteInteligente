// src/controllers/ubicacionesController.js
const db = require('../config/database');

// Obtener las últimas 100 ubicaciones
const getUbicaciones = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM ubicaciones_tiempo_real ORDER BY fecha_registro DESC LIMIT 100');
    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener ubicaciones:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener ubicaciones',
      error: error.message
    });
  }
};

module.exports = {
  getUbicaciones
};
