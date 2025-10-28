// src/controllers/busController.js
const db = require('../config/database');

// Obtener todos los buses activos (usando la nueva vista)
const getBusesActivos = async (req, res) => {
  try {
    // Usar la vista creada en la base de datos: vista_buses_activos
    const result = await db.query('SELECT * FROM vista_buses_activos ORDER BY bus_id');
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

// Obtener buses de una ruta específica (usando la nueva vista)
const getBusesPorRuta = async (req, res) => {
  try {
    const { rutaId } = req.params;
  const result = await db.query('SELECT * FROM vista_buses_activos WHERE ruta_id = $1', [rutaId]);
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

// Obtener información de un bus específico (usando la nueva vista)
const getBusPorId = async (req, res) => {
  try {
    const { busId } = req.params;
  const result = await db.query('SELECT * FROM vista_buses_activos WHERE bus_id = $1', [busId]);

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

    if (!latitud || !longitud) {
      return res.status(400).json({ success: false, message: 'Latitud y longitud son requeridos' });
    }

    const result = await db.query(`
      INSERT INTO ubicaciones_tiempo_real (bus_id, latitud, longitud, velocidad, direccion)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [busId, latitud, longitud, velocidad || 0, direccion || 0]);

    if (req.io) {
      // La actualización principal se emite desde el simulador, 
      // pero podemos emitir una secundaria aquí si es necesario.
      // Por ahora, lo dejamos así para no duplicar eventos.
    }

    res.status(201).json({
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

// Obtener historial de ubicaciones de un bus
const getHistorialUbicaciones = async (req, res) => {
  try {
    const { busId } = req.params;
    const { limite = 100 } = req.query;

    const result = await db.query(
      'SELECT * FROM ubicaciones_tiempo_real WHERE bus_id = $1 ORDER BY fecha_registro DESC LIMIT $2',
      [busId, limite]
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
