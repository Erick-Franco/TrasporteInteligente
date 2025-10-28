// src/config/database.js
const { Pool } = require('pg');
require('dotenv').config();

// Configuración de la conexión
const connectionConfig = {
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false // Necesario para Supabase en Vercel
  }
};

// Crear pool de conexiones
const pool = new Pool(connectionConfig);

// Monitorear errores de conexión
pool.on('error', (err) => {
  console.error('Error inesperado en el pool de PostgreSQL:', err);
});

// Función para probar la conexión
const testConnection = async () => {
  try {
    const client = await pool.connect();
    console.log('Conexión a la base de datos exitosa');
    client.release();
    return true;
  } catch (err) {
    console.error('Error al conectar a la base de datos:', err.message);
    return false;
  }
};

// Ejecutar test de conexión al iniciar
testConnection();

// Función helper para ejecutar queries con mejor manejo de errores
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Query ejecutado:', { text, duration, rows: res.rowCount });
    return res;
  } catch (err) {
    console.error('Error ejecutando query:', text, err);
    throw err;
  }
};

module.exports = {
  query,
  pool,
  testConnection
};