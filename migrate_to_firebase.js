// SCRIPT DE MIGRACION - PostgreSQL a Firebase
// migrate_to_firebase.js

const admin = require('firebase-admin');
const { Pool } = require('pg');
require('dotenv').config();

// Inicializar Firebase Admin
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`
});

const db = admin.firestore();
const auth = admin.auth();

// Configurar PostgreSQL
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// FUNCIONES DE MIGRACION

async function migrarRutas() {
    console.log('\\nMigrando rutas...');
    const result = await pool.query('SELECT * FROM rutas WHERE codigo IS NOT NULL ORDER BY id');

    let migrados = 0;
    for (const row of result.rows) {
        if (!row.codigo || !row.nombre) continue;

        await db.collection('rutas').doc(`ruta_${row.codigo}`).set({
            codigo: row.codigo,
            nombre: row.nombre,
            descripcion: row.descripcion || '',
            color: row.color || '#FF5722',
            tarifa: parseFloat(row.tarifa) || 1.0,
            activa: row.estado === 'activa',
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });
        migrados++;
    }
    console.log(`OK ${migrados} rutas migradas`);
}

async function migrarRutaPuntos() {
    console.log('\\nMigrando puntos de ruta...');
    const result = await pool.query(`
    SELECT rp.*, r.codigo as ruta_codigo
    FROM ruta_puntos rp
    JOIN rutas r ON rp.ruta_id = r.id
    WHERE r.codigo IS NOT NULL AND rp.latitud IS NOT NULL
    ORDER BY rp.ruta_id, rp.orden
  `);

    let migrados = 0;
    for (const row of result.rows) {
        await db.collection('puntos_control').add({
            ruta_id: `ruta_${row.ruta_codigo}`,
            nombre: `Punto ${row.orden}`,
            tipo: row.tipo || 'ida',
            orden: parseInt(row.orden) || 0,
            latitud: parseFloat(row.latitud),
            longitud: parseFloat(row.longitud),
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });
        migrados++;
    }
    console.log(`OK ${migrados} puntos de ruta migrados`);
}

async function migrarPuntosControl() {
    console.log('\\nMigrando puntos de control (paraderos)...');
    const result = await pool.query(`
    SELECT pc.*, r.codigo as ruta_codigo
    FROM puntos_control pc
    JOIN rutas r ON pc.ruta_id = r.id
    WHERE r.codigo IS NOT NULL AND pc.latitud IS NOT NULL
    ORDER BY pc.ruta_id, pc.orden
  `);

    let migrados = 0;
    for (const row of result.rows) {
        await db.collection('puntos_control').add({
            ruta_id: `ruta_${row.ruta_codigo}`,
            nombre: row.nombre,
            descripcion: row.descripcion || '',
            tipo: row.direccion || 'ida',
            orden: parseInt(row.orden) || 0,
            latitud: parseFloat(row.latitud),
            longitud: parseFloat(row.longitud),
            radio_metros: parseInt(row.radio_metros) || 50,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });
        migrados++;
    }
    console.log(`OK ${migrados} puntos de control migrados`);
}

async function migrarVehiculos() {
    console.log('\\nMigrando vehiculos...');
    const result = await pool.query(`
    SELECT v.*, c.licencia as conductor_licencia
    FROM vehiculos v
    LEFT JOIN conductores c ON v.conductor_id = c.id
    WHERE v.placa IS NOT NULL
    ORDER BY v.id
  `);

    let migrados = 0;
    for (const row of result.rows) {
        await db.collection('vehiculos').doc(`vehiculo_${row.id}`).set({
            placa: row.placa,
            modelo: row.modelo || 'N/A',
            capacidad: parseInt(row.capacidad) || 20,
            color: row.color || 'Blanco',
            activo: row.estado === 'operativo',
            conductor_licencia: row.conductor_licencia || null,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });
        migrados++;
    }
    console.log(`OK ${migrados} vehiculos migrados`);
}

async function migrarConductores() {
    console.log('\\nMigrando conductores...');
    const result = await pool.query(`
    SELECT c.*, r.codigo as ruta_codigo, v.id as vehiculo_id
    FROM conductores c
    LEFT JOIN rutas r ON c.ruta_id = r.id
    LEFT JOIN vehiculos v ON v.conductor_id = c.id
    WHERE c.email IS NOT NULL
    ORDER BY c.id
  `);

    let migrados = 0;
    for (const row of result.rows) {
        try {
            const userRecord = await auth.createUser({
                email: row.email,
                password: '123456',
                displayName: row.nombre,
                disabled: row.estado !== 'activo'
            });

            await db.collection('conductores').doc(userRecord.uid).set({
                nombre: row.nombre,
                licencia: row.licencia,
                email: row.email,
                telefono: row.telefono || '',
                vehiculo_id: row.vehiculo_id ? `vehiculo_${row.vehiculo_id}` : null,
                ruta_id: row.ruta_codigo ? `ruta_${row.ruta_codigo}` : null,
                activo: row.estado === 'activo',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });

            migrados++;
            console.log(`  OK ${row.nombre} (${row.email})`);
        } catch (error) {
            if (error.code === 'auth/email-already-exists') {
                console.log(`  WARN ${row.email} ya existe`);
                migrados++;
            } else {
                console.error(`  ERROR: ${error.message}`);
            }
        }
    }
    console.log(`OK ${migrados} conductores migrados`);
}

async function migrarGerentes() {
    console.log('\\nMigrando gerentes...');
    const result = await pool.query(`
    SELECT g.*, r.codigo as ruta_codigo
    FROM gerentes g
    LEFT JOIN rutas r ON g.ruta_id = r.id
    WHERE g.email IS NOT NULL
    ORDER BY g.id
  `);

    let migrados = 0;
    for (const row of result.rows) {
        try {
            const userRecord = await auth.createUser({
                email: row.email,
                password: '123456',
                displayName: row.nombre,
                disabled: row.estado !== 'activo'
            });

            await db.collection('gerentes').doc(userRecord.uid).set({
                nombre: row.nombre,
                email: row.email,
                telefono: row.telefono || '',
                ruta_id: row.ruta_codigo ? `ruta_${row.ruta_codigo}` : null,
                activo: row.estado === 'activo',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });

            migrados++;
            console.log(`  OK ${row.nombre} (${row.email})`);
        } catch (error) {
            if (error.code === 'auth/email-already-exists') {
                console.log(`  WARN ${row.email} ya existe`);
                migrados++;
            } else {
                console.error(`  ERROR: ${error.message}`);
            }
        }
    }
    console.log(`OK ${migrados} gerentes migrados`);
}

// EJECUTAR MIGRACION

async function main() {
    console.log('MIGRACION DE POSTGRESQL A FIREBASE');
    console.log('===================================');

    try {
        console.log('\\nVerificando conexion a PostgreSQL...');
        await pool.query('SELECT NOW()');
        console.log('OK Conectado a PostgreSQL');

        await migrarRutas();
        await migrarRutaPuntos();
        await migrarPuntosControl();
        await migrarVehiculos();
        await migrarConductores();
        await migrarGerentes();

        console.log('\\n===================================');
        console.log('MIGRACION COMPLETADA EXITOSAMENTE');
        console.log('===================================');
        console.log('\\nPROXIMOS PASOS:');
        console.log('1. Verificar datos en Firebase Console');
        console.log('2. Configurar reglas de seguridad');
        console.log('3. Probar la aplicacion movil');

    } catch (error) {
        console.error('\\nERROR durante la migracion:', error);
        process.exit(1);
    } finally {
        await pool.end();
        process.exit(0);
    }
}

main();
