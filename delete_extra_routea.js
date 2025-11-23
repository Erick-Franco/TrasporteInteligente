// delete_extra_routes.js
// ------------------------------------------------
// Elimina todas las rutas y sus puntos de control excepto la ruta especificada.
// ------------------------------------------------
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`,
});

const db = admin.firestore();

// Cambia este ID por la ruta que **quieres conservar** (por ejemplo, 'ruta_18')
const RUTA_A_CONSERVAR = 'ruta_18';

async function borrarRutasExtras() {
    try {
        console.log('🔎 Buscando rutas a borrar...');
        const rutasSnap = await db.collection('rutas').get();

        // Borrar rutas que no sean la deseada
        const batch = db.batch();
        let rutasBorradas = 0;

        rutasSnap.forEach(doc => {
            if (doc.id !== RUTA_A_CONSERVAR) {
                batch.delete(doc.ref);
                rutasBorradas++;
            }
        });

        // Borrar puntos de control de rutas eliminadas
        const puntosSnap = await db.collection('puntos_control')
            .where('ruta_id', '!=', RUTA_A_CONSERVAR)
            .get();

        puntosSnap.forEach(doc => batch.delete(doc.ref));

        await batch.commit();
        console.log(`✅ Borradas ${rutasBorradas} rutas y sus puntos de control.`);
        console.log('✅ Operación completada.');
    } catch (err) {
        console.error('❌ Error al borrar rutas:', err);
    } finally {
        process.exit();
    }
}

borrarRutasExtras();