// src/controllers/rutaController.js
const db = require('../config/database');

// Obtener todas las rutas (versión simplificada para nuevo esquema)
const getRutas = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM rutas WHERE activa = true ORDER BY nombre');
    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener rutas:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener rutas',
      error: error.message
    });
  }
};

// Obtener detalles de una ruta con sus coordenadas de IDA y VUELTA
const getRutaConCoordenadas = async (req, res) => {
  try {
    const { rutaId } = req.params;

    // 1. Obtener información de la ruta
    const rutaResult = await db.query('SELECT * FROM rutas WHERE ruta_id = $1', [rutaId]);

    if (rutaResult.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ruta no encontrada'
      });
    }

    const rutaInfo = rutaResult.rows[0];

    // 2. Obtener coordenadas de IDA
    const idaResult = await db.query(`
      SELECT latitud, longitud, nombre_referencia, es_parada, orden
      FROM ruta_coordenadas
      WHERE ruta_id = $1 AND direccion = 'ida'
      ORDER BY orden ASC;
    `, [rutaId]);

    // 3. Obtener coordenadas de VUELTA
    const vueltaResult = await db.query(`
      SELECT latitud, longitud, nombre_referencia, es_parada, orden
      FROM ruta_coordenadas
      WHERE ruta_id = $1 AND direccion = 'vuelta'
      ORDER BY orden ASC;
    `, [rutaId]);

    // 4. Ensamblar la respuesta final
    res.json({
      success: true,
      data: {
        ...rutaInfo,
        ida: idaResult.rows,
        vuelta: vueltaResult.rows
      }
    });

  } catch (error) {
    console.error('Error al obtener ruta con coordenadas:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener detalles de la ruta',
      error: error.message
    });
  }
};

/*
// --- FUNCIONES DESACTIVADAS TEMPORALMENTE ---
// La lógica para buscar paradas cercanas y calcular rutas ha cambiado 
// significativamente con el nuevo esquema y necesita ser re-implementada.

const getParadasCercanas = async (req, res) => {
  res.status(501).json({ message: 'Funcionalidad no implementada para el nuevo esquema.' });
};

const calcularMejorRuta = async (req, res) => {
  res.status(501).json({ message: 'Funcionalidad no implementada para el nuevo esquema.' });
};
*/

module.exports = {
  getRutas,
  getRutaConCoordenadas,
  // getParadasCercanas,
  // calcularMejorRuta
};