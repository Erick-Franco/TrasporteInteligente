// ============================================
// CONTROLADOR DE RUTAS
// ============================================

const { query, pool } = require('../config/database');

// Obtener todas las rutas activas
const getAllRutas = async (req, res) => {
    try {
            // Si el request proviene de un gerente (Authorization Bearer JWT o header x-gerente-email), devolver solo su ruta
            const authHeader = req.header('authorization');
            const gerenteEmail = req.header('x-gerente-email');

            // Intentar JWT first
            if (authHeader && authHeader.toLowerCase().startsWith('bearer ')) {
                const token = authHeader.split(' ')[1];
                try {
                    const jwt = require('jsonwebtoken');
                    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');
                    if (payload && payload.gerente_id) {
                        const g = await pool.query(`SELECT id, nombre, email, ruta_id FROM gerentes WHERE id = $1 AND estado = 'activo'`, [payload.gerente_id]);
                        if (g.rows.length === 0) return res.status(401).json({ success: false, error: 'Gerente no encontrado o inactivo' });
                        const rutaId = g.rows[0].ruta_id;
                        const result = await query(`SELECT id, codigo, nombre, descripcion, color, tarifa, estado FROM rutas WHERE id = $1 AND estado = 'activa'`, [rutaId]);
                        return res.json({ success: true, data: result.rows, total: result.rowCount });
                    }
                } catch (err) {
                    // token inválido -> seguir sin filtrar
                    console.error('JWT inválido en getAllRutas:', err.message);
                }
            }

            // Fallback: header email
            if (gerenteEmail) {
                const g = await pool.query(`SELECT id, nombre, email, ruta_id FROM gerentes WHERE email = $1 AND estado = 'activo'`, [gerenteEmail]);
                if (g.rows.length === 0) {
                    return res.status(401).json({ success: false, error: 'Gerente no encontrado o inactivo' });
                }
                const rutaId = g.rows[0].ruta_id;
                const result = await query(`SELECT id, codigo, nombre, descripcion, color, tarifa, estado FROM rutas WHERE id = $1 AND estado = 'activa'`, [rutaId]);
                return res.json({ success: true, data: result.rows, total: result.rowCount });
            }

        // Si no es gerente, devolver todas las rutas activas
        const result = await query(`
            SELECT id, codigo, nombre, descripcion, color, tarifa, estado 
            FROM rutas 
            WHERE estado = 'activa'
            ORDER BY codigo
        `);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount
        });
    } catch (error) {
        console.error('Error en getAllRutas:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener rutas',
            message: error.message 
        });
    }
};

// Obtener detalles de una ruta específica
const getRutaById = async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await query(`
            SELECT * FROM rutas WHERE id = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                error: 'Ruta no encontrada' 
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0] 
        });
    } catch (error) {
        console.error('Error en getRutaById:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener ruta',
            message: error.message 
        });
    }
};

// Obtener puntos GPS de la ruta (trayectoria completa)
const getRutaPuntos = async (req, res) => {
    try {
        const { id } = req.params;
        const { tipo } = req.query; // 'ida' o 'vuelta'
        
        // Validar tipo
        if (tipo && !['ida', 'vuelta'].includes(tipo)) {
            return res.status(400).json({
                success: false,
                error: 'Tipo debe ser "ida" o "vuelta"'
            });
        }
        
        const result = await query(`
            SELECT latitud, longitud, orden, tipo 
            FROM ruta_puntos 
            WHERE ruta_id = $1 AND tipo = $2
            ORDER BY orden
        `, [id, tipo || 'ida']);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount,
            ruta_id: id,
            tipo: tipo || 'ida'
        });
    } catch (error) {
        console.error('Error en getRutaPuntos:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener puntos de ruta',
            message: error.message 
        });
    }
};

// Obtener paraderos de una ruta
const getRutaParaderos = async (req, res) => {
    try {
        const { id } = req.params;
        const { direccion } = req.query; // 'ida' o 'vuelta'
        
        let queryText = `
            SELECT id, nombre, descripcion, latitud, longitud, orden, direccion, radio_metros
            FROM puntos_control 
            WHERE ruta_id = $1
        `;
        
        const params = [id];
        
        if (direccion) {
            queryText += ` AND direccion = $2`;
            params.push(direccion);
        }
        
        queryText += ` ORDER BY orden`;
        
        const result = await query(queryText, params);
        
        res.json({ 
            success: true, 
            data: result.rows,
            total: result.rowCount,
            ruta_id: id
        });
    } catch (error) {
        console.error('Error en getRutaParaderos:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener paraderos',
            message: error.message 
        });
    }
};

// Obtener estadísticas de una ruta
const getRutaEstadisticas = async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await query(`
            SELECT 
                r.codigo,
                r.nombre,
                r.color,
                COUNT(DISTINCT CASE WHEN rp.tipo = 'ida' THEN rp.id END) as puntos_ida,
                COUNT(DISTINCT CASE WHEN rp.tipo = 'vuelta' THEN rp.id END) as puntos_vuelta,
                COUNT(DISTINCT pc.id) as total_paraderos,
                COUNT(DISTINCT v.id) as buses_activos
            FROM rutas r
            LEFT JOIN ruta_puntos rp ON r.id = rp.ruta_id
            LEFT JOIN puntos_control pc ON r.id = pc.ruta_id
            LEFT JOIN viajes v ON r.id = v.ruta_id AND v.estado = 'en_progreso'
            WHERE r.id = $1
            GROUP BY r.id, r.codigo, r.nombre, r.color
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                error: 'Ruta no encontrada' 
            });
        }
        
        res.json({ 
            success: true, 
            data: result.rows[0] 
        });
    } catch (error) {
        console.error('Error en getRutaEstadisticas:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Error al obtener estadísticas',
            message: error.message 
        });
    }
};

// Obtener la(s) ruta(s) asignada(s) al gerente autenticado
const getGerenteRuta = async (req, res) => {
    try {
        // req.gerente puede venir del middleware verifyGerenteHeader
        if (!req.gerente || !req.gerente.ruta_id) {
            return res.status(403).json({ success: false, error: 'No autorizado o gerente sin ruta asignada' });
        }

        const rutaId = req.gerente.ruta_id;
        const result = await query(`SELECT id, codigo, nombre, descripcion, color, tarifa, estado FROM rutas WHERE id = $1 AND estado = 'activa'`, [rutaId]);
        return res.json({ success: true, data: result.rows, total: result.rowCount });
    } catch (error) {
        console.error('Error en getGerenteRuta:', error);
        res.status(500).json({ success: false, error: 'Error al obtener ruta del gerente', message: error.message });
    }
};

// (Export will be declared after all functions are defined)

// Guardar/actualizar puntos de una ruta (batch)
const saveRutaPuntos = async (req, res) => {
    const client = await require('../config/database').pool.connect();
    try {
        const { id } = req.params;
        const { tipo, puntos } = req.body;

        if (!tipo || !['ida', 'vuelta'].includes(tipo)) {
            return res.status(400).json({ success: false, error: 'Tipo inválido. Debe ser "ida" o "vuelta"' });
        }

        if (!Array.isArray(puntos) || puntos.length === 0) {
            return res.status(400).json({ success: false, error: 'Puntos inválidos. Debe ser un array no vacío.' });
        }

        await client.query('BEGIN');

        // Eliminar puntos existentes para la ruta y tipo
        await client.query(`DELETE FROM ruta_puntos WHERE ruta_id = $1 AND tipo = $2`, [id, tipo]);

        // Insertar nuevos puntos en orden
        const insertText = `INSERT INTO ruta_puntos (ruta_id, latitud, longitud, orden, tipo) VALUES ($1, $2, $3, $4, $5)`;
        for (let i = 0; i < puntos.length; i++) {
            const p = puntos[i];
            const lat = parseFloat(p.latitud);
            const lng = parseFloat(p.longitud);
            const orden = p.orden != null ? parseInt(p.orden) : i + 1;

            if (isNaN(lat) || isNaN(lng)) {
                await client.query('ROLLBACK');
                return res.status(400).json({ success: false, error: `Coordenadas inválidas en índice ${i}` });
            }

            await client.query(insertText, [id, lat, lng, orden, tipo]);
        }

        await client.query('COMMIT');

        return res.json({ success: true, message: 'Puntos guardados correctamente', ruta_id: id, tipo });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error en saveRutaPuntos:', error);
        return res.status(500).json({ success: false, error: 'Error al guardar puntos', message: error.message });
    } finally {
        client.release();
    }
};

    // Exportar funciones (incluye saveRutaPuntos)
    module.exports = {
        getAllRutas,
        getRutaById,
        getRutaPuntos,
        getRutaParaderos,
        getRutaEstadisticas,
           getGerenteRuta,
           saveRutaPuntos
    };