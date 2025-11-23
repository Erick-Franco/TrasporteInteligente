#!/usr/bin/env node
/**
 * Script para resetear la contraseña de un gerente existente.
 * Uso:
 *   node scripts/resetGerentePassword.js --email gerente@dominio.com --password nuevacontra
 */

const bcrypt = require('bcrypt');
const argv = require('minimist')(process.argv.slice(2));
const { pool } = require('../src/config/database');

async function run() {
  const email = argv.email;
  const password = argv.password;

  if (!email || !password) {
    console.error('Uso: node scripts/resetGerentePassword.js --email gerente@dominio.com --password nuevacontra');
    process.exit(1);
  }

  try {
    const hash = await bcrypt.hash(password, 10);
    const res = await pool.query('UPDATE gerentes SET password_hash = $1 WHERE email = $2 RETURNING id, nombre, email', [hash, email]);
    if (res.rows.length === 0) {
      console.error('No se encontró gerente con ese email');
      process.exit(2);
    }

    console.log('✅ Contraseña actualizada para gerente:', res.rows[0].email);
    process.exit(0);
  } catch (err) {
    console.error('❌ Error al actualizar contraseña:', err.message);
    process.exit(1);
  }
}

run();
