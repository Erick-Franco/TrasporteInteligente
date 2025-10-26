// src/controllers/conductoresController.js
const db = require('../config/database');

// Obtener todos los conductores
const getConductores = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM conductores ORDER BY apellidos, nombres');
    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener conductores:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener conductores',
      error: error.message
    });
  }
};

module.exports = {
  getConductores
};
