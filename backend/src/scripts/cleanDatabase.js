// src/scripts/cleanDatabase.js
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5434,
  database: process.env.DB_NAME || 'transporte_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

async function cleanDatabase() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 LIMPIEZA DE BASE DE DATOS\n');
    console.log('⚠️  ADVERTENCIA: Esto eliminará TODOS los datos de las tablas relacionadas a rutas');
    console.log('📍 Base de datos:', process.env.DB_NAME || 'transporte_db');
    console.log('\n⏳ Esperando 3 segundos antes de continuar...\n');
    
    // Esperar 3 segundos para que el usuario pueda cancelar (Ctrl+C)
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    console.log('🗑️  Iniciando limpieza...\n');
    
    // Comenzar transacción
    await client.query('BEGIN');
    
    // Eliminar en orden correcto (respetando foreign keys)
    // 1. Eventos de puntos de control
    const eventosResult = await client.query('DELETE FROM eventos_puntos_control');
    console.log(`✅ ${eventosResult.rowCount} eventos de puntos de control eliminados`);
    
    // 2. Ubicaciones en tiempo real
    const ubicacionesResult = await client.query('DELETE FROM ubicaciones_tiempo_real');
    console.log(`✅ ${ubicacionesResult.rowCount} ubicaciones GPS eliminadas`);
    
    // 3. Viajes
    const viajesResult = await client.query('DELETE FROM viajes');
    console.log(`✅ ${viajesResult.rowCount} viajes eliminados`);
    
    // 4. Puntos de control (paraderos)
    const puntosControlResult = await client.query('DELETE FROM puntos_control');
    console.log(`✅ ${puntosControlResult.rowCount} puntos de control eliminados`);
    
    // 5. Puntos de ruta (trayectoria GPS)
    const rutaPuntosResult = await client.query('DELETE FROM ruta_puntos');
    console.log(`✅ ${rutaPuntosResult.rowCount} puntos de ruta eliminados`);
    
    // 6. Rutas
    const rutasResult = await client.query('DELETE FROM rutas');
    console.log(`✅ ${rutasResult.rowCount} rutas eliminadas`);
    
    // Confirmar transacción
    await client.query('COMMIT');
    
    console.log('\n✨ ¡Base de datos limpiada exitosamente!');
    console.log('📊 Ahora puedes ejecutar insertAllRutas.js');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error durante la limpieza:', error.message);
    console.error('\nStack:', error.stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
    console.log('\n🔌 Desconectado de PostgreSQL');
  }
}

cleanDatabase();