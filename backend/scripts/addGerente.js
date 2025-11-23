#!/usr/bin/env node
/**
 * Script para añadir un gerente a la tabla `gerentes`.
 * Uso: node scripts/addGerente.js --name "Nombre" --email gerente@transporte.com --password secret --ruta 1 --telefono "" 
 */

const bcrypt = require('bcrypt');
const { pool } = require('../src/config/database');

const argv = require('minimist')(process.argv.slice(2));

async function run() {
  const nombre = argv.name || argv.nombre;
  const email = argv.email;
  const password = argv.password;
  const ruta_id = argv.ruta || argv.ruta_id;
  const telefono = argv.telefono || '';

  if (!nombre || !email || !password || !ruta_id) {
    console.error('Uso: node scripts/addGerente.js --name "Nombre" --email gerente@... --password secret --ruta 1 [--telefono "..."]');
    process.exit(1);
  }

  try {
    const hash = await bcrypt.hash(password, 10);

    const insert = `INSERT INTO gerentes (nombre, email, telefono, password_hash, ruta_id, estado) VALUES ($1, $2, $3, $4, $5, 'activo') RETURNING id`;
    const res = await pool.query(insert, [nombre, email, telefono, hash, ruta_id]);

    console.log('✅ Gerente creado con id:', res.rows[0].id);
    process.exit(0);
  } catch (err) {
    console.error('❌ Error al crear gerente:', err.message);
    process.exit(1);
  }
}

run();
