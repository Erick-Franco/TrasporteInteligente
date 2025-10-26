// src/controllers/busesActivosController.js
const db = require('../config/database');

// Obtener todos los buses activos desde la vista
const getBusesActivos = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM vista_buses_activos');
    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener buses activos:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener buses activos',
      error: error.message
    });
  }
};

module.exports = {
  getBusesActivos
};
