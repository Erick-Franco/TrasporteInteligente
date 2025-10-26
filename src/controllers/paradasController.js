// src/controllers/paradasController.js
const db = require('../config/database');

// Obtener todas las paradas
const getParadas = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM paradas ORDER BY id');
    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener paradas:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener paradas',
      error: error.message
    });
  }
};

module.exports = {
  getParadas
};
