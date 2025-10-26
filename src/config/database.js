// src/config/database.js
const { Pool } = require('pg');
require('dotenv').config();

// Configuración de la conexión
const connectionConfig = {
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
};

// Crear pool de conexiones
const pool = new Pool(
  process.env.DATABASE_URL
    ? connectionConfig
    : {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        database: process.env.DB_NAME || 'transporte_db',
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'admin123',
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
      }
);

// Evento: Conexión exitosa
pool.on('connect', () => {
  console.log('✅ Conectado a PostgreSQL');
});

// Evento: Error en la conexión
pool.on('error', (err) => {
  console.error('❌ Error en PostgreSQL:', err);
  process.exit(-1);
});

// Función para ejecutar queries
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('📊 Query ejecutado:', { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    console.error('❌ Error en query:', error);
    throw error;
  }
};

// Función para obtener un cliente (para transacciones)
const getClient = async () => {
  const client = await pool.connect();
  const query = client.query;
  const release = client.release;

  // Timeout de 5 segundos
  const timeout = setTimeout(() => {
    console.error('⚠️ Cliente no liberado después de 5 segundos');
  }, 5000);

  // Override del método release
  client.release = () => {
    clearTimeout(timeout);
    client.query = query;
    client.release = release;
    return release.apply(client);
  };

  return client;
};

// Función para verificar conexión
const testConnection = async () => {
  try {
    const result = await query('SELECT NOW()');
    console.log('✅ Conexión a DB verificada:', result.rows[0].now);
    return true;
  } catch (error) {
    console.error('❌ Error al conectar con DB:', error.message);
    return false;
  }
};

module.exports = {
  pool,
  query,
  getClient,
  testConnection
};