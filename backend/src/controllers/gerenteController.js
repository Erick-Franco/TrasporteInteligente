// ════════════════════════════════════════════════════════
// 🏢 CONTROLLER DE GERENTES - TRANSPORTE INTELIGENTE
// backend/src/controllers/gerenteController.js
// ════════════════════════════════════════════════════════

const { pool } = require('../config/database');
const bcrypt = require('bcrypt');

// ════════════════════════════════════════════════════════
// 🔐 LOGIN DEL GERENTE
// ════════════════════════════════════════════════════════

const loginGerente = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email y contraseña son requeridos'
      });
    }

    console.log(`🔐 Intento de login gerente: ${email}`);

    // Buscar gerente por email con su ruta asignada
    const result = await pool.query(
      `SELECT 
        g.id,
        g.nombre,
        g.email,
        g.telefono,
        g.password_hash,
        g.ruta_id,
        g.estado,
        r.codigo as ruta_codigo,
        r.nombre as ruta_nombre,
        r.color as ruta_color,
        r.descripcion as ruta_descripcion
       FROM gerentes g
       LEFT JOIN rutas r ON g.ruta_id = r.id
       WHERE g.email = $1 AND g.estado = 'activo'`,
      [email]
    );

    if (result.rows.length === 0) {
      console.log(`❌ Gerente no encontrado: ${email}`);
      return res.status(401).json({
        success: false,
        error: 'Credenciales inválidas'
      });
    }

    const gerente = result.rows[0];

    // Verificar contraseña
    const validPassword = await bcrypt.compare(password, gerente.password_hash);
    
    if (!validPassword) {
      console.log(`❌ Contraseña incorrecta para: ${email}`);
      return res.status(401).json({
        success: false,
        error: 'Credenciales inválidas'
      });
    }

    // No enviar el hash de la contraseña al cliente
    delete gerente.password_hash;

    console.log(`✅ Login exitoso: ${gerente.nombre} - ${gerente.ruta_codigo}`);

    res.json({
      success: true,
      message: 'Login exitoso',
      gerente: gerente
    });

  } catch (error) {
    console.error('❌ Error en login gerente:', error);
    res.status(500).json({
      success: false,
      error: 'Error en el servidor',
      details: error.message
    });
  }
};

// ════════════════════════════════════════════════════════
// 🚌 OBTENER CONDUCTORES ACTIVOS DE UNA LÍNEA
// ════════════════════════════════════════════════════════

const getConductoresActivos = async (req, res) => {
  try {
    const { ruta_id } = req.params;

    console.log(`📍 Obteniendo conductores activos de ruta ${ruta_id}`);

    const result = await pool.query(
      `SELECT 
        c.id as conductor_id,
        c.nombre as conductor_nombre,
        c.licencia,
        c.telefono,
        c.email,
        v.id as vehiculo_id,
        v.placa,
        v.modelo,
        v.capacidad,
        v.color as vehiculo_color,
        vi.id as viaje_id,
        vi.fecha_salida,
        vi.estado as viaje_estado,
        utr.latitud,
        utr.longitud,
        utr.velocidad,
        utr.direccion,
        utr.altitud,
        utr.timestamp as ultima_actualizacion
      FROM viajes vi
      JOIN conductores c ON vi.conductor_id = c.id
      JOIN vehiculos v ON vi.vehiculo_id = v.id
      LEFT JOIN LATERAL (
        SELECT * FROM ubicaciones_tiempo_real
        WHERE conductor_id = c.id
        ORDER BY timestamp DESC
        LIMIT 1
      ) utr ON true
      WHERE vi.ruta_id = $1 AND vi.estado = 'en_progreso'
      ORDER BY c.nombre`,
      [ruta_id]
    );

    console.log(`✅ ${result.rows.length} conductores activos encontrados`);

    res.json({
      success: true,
      total: result.rows.length,
      conductores: result.rows
    });

  } catch (error) {
    console.error('❌ Error obteniendo conductores:', error);
    res.status(500).json({
      success: false,
      error: 'Error en el servidor',
      details: error.message
    });
  }
};

// ════════════════════════════════════════════════════════
// 🗺️ OBTENER RUTA COMPLETA (PUNTOS GPS + PARADEROS)
// ════════════════════════════════════════════════════════

const getRutaCompleta = async (req, res) => {
  try {
    const { ruta_id } = req.params;
    const { tipo } = req.query; // 'ida' o 'vuelta' (opcional)

    console.log(`🗺️ Obteniendo ruta completa: ${ruta_id} (tipo: ${tipo || 'todas'})`);

    // 1. Información básica de la ruta
    const rutaInfo = await pool.query(
      'SELECT * FROM rutas WHERE id = $1',
      [ruta_id]
    );

    if (rutaInfo.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Ruta no encontrada'
      });
    }

    // 2. Puntos GPS de la ruta (trayectoria completa)
    let queryPuntosGPS = `
      SELECT latitud, longitud, orden, tipo
      FROM ruta_puntos
      WHERE ruta_id = $1
    `;
    const paramsPuntosGPS = [ruta_id];

    if (tipo && (tipo === 'ida' || tipo === 'vuelta')) {
      queryPuntosGPS += ' AND tipo = $2';
      paramsPuntosGPS.push(tipo);
    }

    queryPuntosGPS += ' ORDER BY orden';

    const puntosGPS = await pool.query(queryPuntosGPS, paramsPuntosGPS);

    // 3. Puntos de control (paraderos)
    let queryPuntosControl = `
      SELECT id, nombre, descripcion, latitud, longitud, radio_metros, orden, tipo, direccion
      FROM puntos_control
      WHERE ruta_id = $1
    `;
    const paramsPuntosControl = [ruta_id];

    if (tipo && (tipo === 'ida' || tipo === 'vuelta')) {
      queryPuntosControl += ' AND direccion = $2';
      paramsPuntosControl.push(tipo);
    }

    queryPuntosControl += ' ORDER BY orden';

    const puntosControl = await pool.query(queryPuntosControl, paramsPuntosControl);

    console.log(`✅ Ruta ${rutaInfo.rows[0].codigo}: ${puntosGPS.rows.length} puntos GPS, ${puntosControl.rows.length} paraderos`);

    res.json({
      success: true,
      ruta: rutaInfo.rows[0],
      puntos_gps: puntosGPS.rows,
      paraderos: puntosControl.rows,
      estadisticas: {
        total_puntos_gps: puntosGPS.rows.length,
        total_paraderos: puntosControl.rows.length
      }
    });

  } catch (error) {
    console.error('❌ Error obteniendo ruta completa:', error);
    res.status(500).json({
      success: false,
      error: 'Error en el servidor',
      details: error.message
    });
  }
};

// ════════════════════════════════════════════════════════
// 📊 OBTENER ESTADÍSTICAS DE LA LÍNEA
// ════════════════════════════════════════════════════════

const getEstadisticasLinea = async (req, res) => {
  try {
    const { ruta_id } = req.params;

    console.log(`📊 Obteniendo estadísticas de ruta ${ruta_id}`);

    // Total de conductores activos
    const conductoresActivos = await pool.query(
      `SELECT COUNT(*) as total
       FROM viajes
       WHERE ruta_id = $1 AND estado = 'en_progreso'`,
      [ruta_id]
    );

    // Total de viajes completados hoy
    const viajesHoy = await pool.query(
      `SELECT COUNT(*) as total
       FROM viajes
       WHERE ruta_id = $1 
       AND fecha_salida::date = CURRENT_DATE
       AND estado = 'completado'`,
      [ruta_id]
    );

    // Promedio de velocidad
    const promedioVelocidad = await pool.query(
      `SELECT AVG(utr.velocidad) as promedio
       FROM ubicaciones_tiempo_real utr
       JOIN viajes v ON utr.ruta_id = v.ruta_id
       WHERE v.ruta_id = $1 AND v.estado = 'en_progreso'
       AND utr.timestamp > NOW() - INTERVAL '5 minutes'`,
      [ruta_id]
    );

    // Total de paraderos
    const totalParaderos = await pool.query(
      'SELECT COUNT(*) as total FROM puntos_control WHERE ruta_id = $1',
      [ruta_id]
    );

    res.json({
      success: true,
      estadisticas: {
        conductores_activos: parseInt(conductoresActivos.rows[0].total),
        viajes_completados_hoy: parseInt(viajesHoy.rows[0].total),
        velocidad_promedio: parseFloat(promedioVelocidad.rows[0].promedio || 0).toFixed(1),
        total_paraderos: parseInt(totalParaderos.rows[0].total)
      }
    });

  } catch (error) {
    console.error('❌ Error obteniendo estadísticas:', error);
    res.status(500).json({
      success: false,
      error: 'Error en el servidor',
      details: error.message
    });
  }
};

// ════════════════════════════════════════════════════════
// 📤 EXPORTAR FUNCIONES
// ════════════════════════════════════════════════════════

module.exports = {
  loginGerente,
  getConductoresActivos,
  getRutaCompleta,
  getEstadisticasLinea
};