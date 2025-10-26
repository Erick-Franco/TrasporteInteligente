// src/controllers/rutaParadasController.js
const db = require('../config/database');

// Obtener todas las relaciones de ruta-parada
const getRutaParadas = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM ruta_paradas ORDER BY ruta_id, orden');
    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener ruta_paradas:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener las paradas de las rutas',
      error: error.message
    });
  }
};

module.exports = {
  getRutaParadas
};
