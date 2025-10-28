// src/config/database.js
// Este archivo soporta dos modos:
// - Conexión real a PostgreSQL usando process.env.DATABASE_URL o variables DB_*
// - Modo "mock" seguro cuando no hay configuración de BD: evita que la app falle
//   en ambientes como despliegues sin DB configurada. En ese caso `query` devuelve
//   resultados vacíos ({ rowCount: 0, rows: [] }).

const { Pool } = require('pg');

const hasPgConfig = !!(process.env.DATABASE_URL || process.env.DB_HOST || process.env.DB_USER || process.env.DB_NAME);

if (hasPgConfig) {
  const poolConfig = process.env.DATABASE_URL
    ? { connectionString: process.env.DATABASE_URL, ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false }
    : {
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'transporte_inteligente',
        port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
        max: 10
      };

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