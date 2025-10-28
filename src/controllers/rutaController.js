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
    const rutaResult = await db.query('SELECT * FROM rutas WHERE id = $1', [rutaId]);

    if (rutaResult.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ruta no encontrada'
      });
    }

    const rutaInfo = rutaResult.rows[0];
    // 2. Obtener paradas vinculadas a la ruta
    const paradasResult = await db.query(
      `SELECT p.*, rp.orden, rp.tiempo_estimado, rp.distancia_km, rp.es_parada_principal
       FROM ruta_paradas rp
       JOIN paradas p ON rp.parada_id = p.id
       WHERE rp.ruta_id = $1
       ORDER BY rp.orden ASC`,
      [rutaId]
    );

    // 3. Obtener coordenadas (trayecto) de la ruta si existen
    const coordsResult = await db.query(
      'SELECT latitud, longitud, orden FROM coordenadas_ruta WHERE ruta_id = $1 ORDER BY orden ASC',
      [rutaId]
    );

    // 4. Ensamblar la respuesta final
    res.json({
      success: true,
      data: {
        ...rutaInfo,
        paradas: paradasResult.rows,
        coordenadas: coordsResult.rows
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