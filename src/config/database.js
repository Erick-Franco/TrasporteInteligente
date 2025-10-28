// src/config/database.js
// Este archivo soporta dos modos:
// - Conexión real a PostgreSQL usando process.env.DATABASE_URL o variables DB_*
// - Modo "mock" seguro cuando no hay configuración de BD: evita que la app falle
//   en ambientes como despliegues sin DB configurada. En ese caso `query` devuelve
//   resultados vacíos ({ rowCount: 0, rows: [] }).

const { Pool } = require('pg');

const hasPgConfig = !!(process.env.DATABASE_URL || process.env.DB_HOST || process.env.DB_USER || process.env.DB_NAME);

if (hasPgConfig) {
  // Preferir DATABASE_URL (ej. Supabase).
  // Por defecto habilitamos SSL con `rejectUnauthorized: false` para evitar
  // errores como "self-signed certificate in certificate chain" en providers
  // gestionados. Si se quiere verificación estricta, establecer DB_SSL=strict.
  let poolConfig;
  if (process.env.DATABASE_URL) {
    const useSsl = process.env.DB_SSL === 'false' ? false : { rejectUnauthorized: process.env.DB_SSL === 'strict' };

    // Si no se pide estricticidad, permitir certificados autofirmados a nivel de Node
    // (esto evita el error "self-signed certificate in certificate chain" cuando
    // el proveedor usa certificados no verificados). Puedes forzar verificación
    // estableciendo DB_SSL=strict en el entorno.
    if (process.env.DB_SSL !== 'strict') {
      process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
    }

    poolConfig = { connectionString: process.env.DATABASE_URL, ssl: useSsl };
  } else {
    const useSsl = process.env.DB_SSL === 'true' ? { rejectUnauthorized: process.env.DB_SSL === 'strict' } : false;
    poolConfig = {
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'transporte_inteligente',
      port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
      max: 10,
      ssl: useSsl
    };
  }

  const pool = new Pool(poolConfig);

  // Exportar pool directamente (tiene .query que devuelve { rows, rowCount })
  module.exports = pool;
} else {
  console.warn('⚠️  No database configuration found (DATABASE_URL or DB_HOST/DB_NAME). Using mock DB that returns empty results. Configure DB in environment for real data.');

  // Mock que evita caída de la app en entornos sin DB.
  const mock = {
    query: async (/* sql, params */) => {
      return { rowCount: 0, rows: [] };
    }
  };

  module.exports = mock;
}