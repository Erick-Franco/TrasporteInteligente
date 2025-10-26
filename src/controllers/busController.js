// src/controllers/busController.js
const db = require('../config/database');

// Obtener todos los buses activos
const getBusesActivos = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT * FROM vista_buses_activos
      ORDER BY bus_id
    `);

    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener buses:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener buses activos',
      error: error.message
    });
  }
};

// Obtener buses de una ruta específica
const getBusesPorRuta = async (req, res) => {
  try {
    const { rutaId } = req.params;

    const result = await db.query(`
      SELECT * FROM vista_buses_activos
      WHERE ruta_id = $1
    `, [rutaId]);

    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener buses por ruta:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener buses de la ruta',
      error: error.message
    });
  }
};

// Obtener información de un bus específico
const getBusPorId = async (req, res) => {
  try {
    const { busId } = req.params;

    const result = await db.query(`
      SELECT * FROM vista_buses_activos
      WHERE bus_id = $1
    `, [busId]);

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Bus no encontrado'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error al obtener bus:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener información del bus',
      error: error.message
    });
  }
};

// Actualizar ubicación de un bus (para GPS Tracker)
const actualizarUbicacion = async (req, res) => {
  try {
    const { busId } = req.params;
    const { latitud, longitud, velocidad, direccion } = req.body;

    // Validar datos
    if (!latitud || !longitud) {
      return res.status(400).json({
        success: false,
        message: 'Latitud y longitud son requeridos'
      });
    }

    // Insertar nueva ubicación
    const result = await db.query(`
      INSERT INTO ubicaciones_tiempo_real 
      (bus_id, latitud, longitud, velocidad, direccion)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [busId, latitud, longitud, velocidad || 0, direccion || 0]);

    // Emitir evento via Socket.IO (lo haremos después)
    if (req.io) {
      req.io.emit('bus-update', {
        bus_id: busId,
        latitud,
        longitud,
        velocidad,
        timestamp: new Date()
      });
    }

    res.json({
      success: true,
      message: 'Ubicación actualizada',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error al actualizar ubicación:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar ubicación',
      error: error.message
    });
  }
};

// Obtener historial de ubicaciones
const getHistorialUbicaciones = async (req, res) => {
  try {
    const { busId } = req.params;
    const { limite = 50 } = req.query;

    const result = await db.query(
        'SELECT bus_id, latitud, longitud, velocidad, direccion, fecha_registro FROM ubicaciones_tiempo_real WHERE bus_id = $1 ORDER BY fecha_registro DESC',
        [busId]
    );


    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al obtener historial:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener historial de ubicaciones',
      error: error.message
    });
  }
};

module.exports = {
  getBusesActivos,
  getBusesPorRuta,
  getBusPorId,
  actualizarUbicacion,
  getHistorialUbicaciones
};