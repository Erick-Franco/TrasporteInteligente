// ============================================
// CONFIGURACIÓN DE BASE DE DATOS
// ============================================

const { Pool } = require('pg');
require('dotenv').config();

// Crear pool de conexiones
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5434,
    database: process.env.DB_NAME || 'transporte_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '123456',
    max: 20, // Máximo de conexiones
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

// Verificar conexión al iniciar
pool.on('connect', () => {
    console.log('✅ Conectado a PostgreSQL');
});

pool.on('error', (err) => {
    console.error('❌ Error en PostgreSQL:', err.message);
    process.exit(-1);
});

// Función auxiliar para ejecutar queries
const query = async (text, params) => {
    const start = Date.now();
    try {
        const result = await pool.query(text, params);
        const duration = Date.now() - start;
        console.log('📊 Query ejecutada', { text: text.substring(0, 50), duration, rows: result.rowCount });
        return result;
    } catch (error) {
        console.error('❌ Error en query:', error.message);
        throw error;
    }
};

// Función para verificar la conexión
const testConnection = async () => {
    try {
        const result = await pool.query('SELECT NOW()');
        console.log('✅ Conexión DB verificada:', result.rows[0].now);
        return true;
    } catch (error) {
        console.error('❌ Error al conectar:', error.message);
        return false;
    }
};

module.exports = {
    pool,
    query,
    testConnection
};