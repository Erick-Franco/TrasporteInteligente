// src/controllers/rutaController.js
const db = require('../config/database');

// Obtener coordenadas de una ruta
const getRutaCoordenadas = async (req, res) => {
  try {
    const { rutaId } = req.params;

    // Obtener información básica de la ruta
    const rutaResult = await db.query(`
      SELECT * FROM rutas WHERE id = $1
    `, [rutaId]);

    if (rutaResult.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ruta no encontrada'
      });
    }

    // Obtener coordenadas ordenadas de la ruta
    const coordenadasResult = await db.query(`
      SELECT latitud, longitud, orden
      FROM coordenadas_ruta
      WHERE ruta_id = $1
      ORDER BY orden
    `, [rutaId]);

    // Formatear como GeoJSON LineString
    const geoJSON = {
      type: "Feature",
      properties: {
        ...rutaResult.rows[0],
        total_coordenadas: coordenadasResult.rowCount
      },
      geometry: {
        type: "LineString",
        coordinates: coordenadasResult.rows.map(coord => [coord.longitud, coord.latitud])
      }
    };

    res.json({
      success: true,
      data: geoJSON
    });
  } catch (error) {
    console.error('Error al obtener coordenadas:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener coordenadas de la ruta',
      error: error.message
    });
  }
};

// Obtener todas las rutas en formato GeoJSON
const getRutasGeoJSON = async (req, res) => {
  try {
    // Obtener todas las rutas activas
    const rutasResult = await db.query(`
      SELECT id, nombre, descripcion, color, activa
      FROM rutas
      WHERE activa = true
      ORDER BY nombre
    `);

    // Para cada ruta, obtener sus coordenadas
    const features = await Promise.all(rutasResult.rows.map(async (ruta) => {
      const coordenadasResult = await db.query(`
        SELECT latitud, longitud, orden
        FROM coordenadas_ruta
        WHERE ruta_id = $1
        ORDER BY orden
      `, [ruta.id]);

      return {
        type: "Feature",
        properties: {
          ...ruta,
          total_coordenadas: coordenadasResult.rowCount
        },
        geometry: {
          type: "LineString",
          coordinates: coordenadasResult.rows.map(coord => [coord.longitud, coord.latitud])
        }
      };
    }));

    const geoJSON = {
      type: "FeatureCollection",
      features: features
    };

    res.json({
      success: true,
      data: geoJSON
    });
  } catch (error) {
    console.error('Error al obtener rutas GeoJSON:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener rutas en formato GeoJSON',
      error: error.message
    });
  }
};

// Obtener todas las rutas
const getRutas = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT 
        r.*,
        COUNT(DISTINCT b.id) AS total_buses,
        COUNT(DISTINCT rp.parada_id) AS total_paradas
      FROM rutas r
      LEFT JOIN buses b ON r.id = b.ruta_id AND b.estado = 'activo'
      LEFT JOIN ruta_paradas rp ON r.id = rp.ruta_id
      WHERE r.activa = true
      GROUP BY r.id
      ORDER BY r.nombre
    `);

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

// Obtener detalles de una ruta con sus paradas
const getRutaConParadas = async (req, res) => {
  try {
    const { rutaId } = req.params;

    // Obtener información de la ruta
    const rutaResult = await db.query(`
      SELECT * FROM rutas WHERE id = $1
    `, [rutaId]);

    if (rutaResult.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ruta no encontrada'
      });
    }

    // Obtener paradas de la ruta
    const paradasResult = await db.query(`
      SELECT 
        p.*,
        rp.orden,
        rp.tiempo_estimado,
        rp.distancia_km
      FROM paradas p
      JOIN ruta_paradas rp ON p.id = rp.parada_id
      WHERE rp.ruta_id = $1
      ORDER BY rp.orden
    `, [rutaId]);

    res.json({
      success: true,
      data: {
        ...rutaResult.rows[0],
        paradas: paradasResult.rows
      }
    });
  } catch (error) {
    console.error('Error al obtener ruta:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener detalles de la ruta',
      error: error.message
    });
  }
};

// Buscar paradas cercanas a una ubicación
const getParadasCercanas = async (req, res) => {
  try {
    const { latitud, longitud, radio = 2 } = req.query;

    if (!latitud || !longitud) {
      return res.status(400).json({
        success: false,
        message: 'Latitud y longitud son requeridos'
      });
    }

    const result = await db.query(`
      SELECT 
        p.*,
        calcular_distancia($1, $2, p.latitud, p.longitud) AS distancia_km,
        r.nombre AS ruta_nombre,
        r.color AS ruta_color
      FROM paradas p
      LEFT JOIN ruta_paradas rp ON p.id = rp.parada_id
      LEFT JOIN rutas r ON rp.ruta_id = r.id
      WHERE calcular_distancia($1, $2, p.latitud, p.longitud) < $3
        AND p.activa = true
      ORDER BY distancia_km
    `, [latitud, longitud, radio]);

    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    console.error('Error al buscar paradas:', error);
    res.status(500).json({
      success: false,
      message: 'Error al buscar paradas cercanas',
      error: error.message
    });
  }
};

// Calcular mejor ruta entre dos puntos
const calcularMejorRuta = async (req, res) => {
  try {
    const { latitud_origen, longitud_origen, latitud_destino, longitud_destino } = req.body;

    if (!latitud_origen || !longitud_origen || !latitud_destino || !longitud_destino) {
      return res.status(400).json({
        success: false,
        message: 'Coordenadas de origen y destino son requeridas'
      });
    }

    // Buscar parada más cercana al origen
    const paradaOrigenResult = await db.query(`
      SELECT 
        p.*,
        r.id AS ruta_id,
        r.nombre AS ruta_nombre,
        r.color AS ruta_color,
        calcular_distancia($1, $2, p.latitud, p.longitud) AS distancia
      FROM paradas p
      JOIN ruta_paradas rp ON p.id = rp.parada_id
      JOIN rutas r ON rp.ruta_id = r.id
      WHERE r.activa = true
      ORDER BY distancia
      LIMIT 1
    `, [latitud_origen, longitud_origen]);

    // Buscar parada más cercana al destino
    const paradaDestinoResult = await db.query(`
      SELECT 
        p.*,
        r.id AS ruta_id,
        r.nombre AS ruta_nombre,
        r.color AS ruta_color,
        calcular_distancia($1, $2, p.latitud, p.longitud) AS distancia
      FROM paradas p
      JOIN ruta_paradas rp ON p.id = rp.parada_id
      JOIN rutas r ON rp.ruta_id = r.id
      WHERE r.activa = true
      ORDER BY distancia
      LIMIT 1
    `, [latitud_destino, longitud_destino]);

    if (paradaOrigenResult.rowCount === 0 || paradaDestinoResult.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'No se encontraron rutas para esa ubicación'
      });
    }

    const paradaOrigen = paradaOrigenResult.rows[0];
    const paradaDestino = paradaDestinoResult.rows[0];

    // Calcular distancia total
    const distanciaTotal = await db.query(`
      SELECT calcular_distancia($1, $2, $3, $4) AS distancia
    `, [latitud_origen, longitud_origen, latitud_destino, longitud_destino]);

    const distanciaKm = parseFloat(distanciaTotal.rows[0].distancia);
    const tiempoEstimado = Math.ceil((distanciaKm / 20) * 60); // 20 km/h promedio
    const tarifa = 2.50; // Tarifa base fija

    res.json({
      success: true,
      data: {
        distancia_km: distanciaKm.toFixed(2),
        tiempo_estimado_minutos: tiempoEstimado,
        tarifa,
        parada_origen: paradaOrigen,
        parada_destino: paradaDestino,
        requiere_transbordo: paradaOrigen.ruta_id !== paradaDestino.ruta_id,
        rutas_sugeridas: [paradaOrigen.ruta_nombre]
      }
    });
  } catch (error) {
    console.error('Error al calcular ruta:', error);
    res.status(500).json({
      success: false,
      message: 'Error al calcular la mejor ruta',
      error: error.message
    });
  }
};

module.exports = {
  getRutas,
  getRutaConParadas,
  getParadasCercanas,
  calcularMejorRuta,
  getRutaCoordenadas,
  getRutasGeoJSON
};
