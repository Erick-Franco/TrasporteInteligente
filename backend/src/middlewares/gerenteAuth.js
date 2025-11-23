const { pool } = require('../config/database');
const jwt = require('jsonwebtoken');

/**
 * Middleware que verifica la identidad del gerente.
 * - Preferencia 1: header Authorization: Bearer <token> (JWT emitido por login)
 * - Preferencia 2: header x-gerente-email (legacy / simple)
 * Adjunta `req.gerente` con la fila de la tabla `gerentes` si existe y está activo.
 */
const verifyGerenteHeader = async (req, res, next) => {
  try {
    const auth = req.header('authorization');
    const emailHeader = req.header('x-gerente-email');

    // 1) JWT
    if (auth && auth.toLowerCase().startsWith('bearer ')) {
      const token = auth.split(' ')[1];
      try {
        const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');
        const gerenteId = payload.gerente_id;
        if (!gerenteId) return res.status(401).json({ success: false, error: 'Token inválido' });

        const result = await pool.query(`SELECT id, nombre, email, telefono, ruta_id, estado FROM gerentes WHERE id = $1 AND estado = 'activo'`, [gerenteId]);
        if (result.rows.length === 0) return res.status(401).json({ success: false, error: 'Gerente no encontrado o inactivo' });
        req.gerente = result.rows[0];
        return next();
      } catch (err) {
        console.error('❌ JWT inválido:', err.message);
        return res.status(401).json({ success: false, error: 'Token inválido' });
      }
    }

    // 2) Legacy: x-gerente-email
    if (emailHeader) {
      const result = await pool.query(
        `SELECT id, nombre, email, telefono, ruta_id, estado FROM gerentes WHERE email = $1 AND estado = 'activo'`,
        [emailHeader]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ success: false, error: 'Gerente no encontrado o inactivo' });
      }

      req.gerente = result.rows[0];
      return next();
    }

    // No credentials
    return res.status(401).json({ success: false, error: 'Credenciales de gerente requeridas (Authorization Bearer o x-gerente-email)' });
  } catch (error) {
    console.error('❌ Error en verifyGerenteHeader:', error);
    res.status(500).json({ success: false, error: 'Error en el servidor' });
  }
};

module.exports = { verifyGerenteHeader };
