// src/controllers/asignacionesController.js
const db = require('../config/database');

// Obtener todas las asignaciones
const getAsignaciones = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM asignaciones_bus_conductor ORDER BY fecha_inicio DESC');
    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener asignaciones:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener asignaciones',
      error: error.message
    });
  }
};

module.exports = {
  getAsignaciones
};
