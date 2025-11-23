const admin = require('firebase-admin');
const fs = require('fs');

// Inicializar Firebase Admin
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`
});

const db = admin.firestore();

async function reimportarRuta18() {
    const filePath = 'mobile_app/lib/data/models/rutas/MapeaMiRuta18.kml';
    const rutaId = 'ruta_18';

    try {
        console.log(`\n📂 Re-importando Ruta 18...`);
        const content = fs.readFileSync(filePath, 'utf8');

        // Extraer nombre
        const nameMatch = content.match(/<name>(.*?)<\/name>/);
        const nombreRuta = nameMatch ? nameMatch[1] : 'Línea 18';

        // Extraer coordenadas
        const coordMatch = content.match(/<coordinates>([\s\S]*?)<\/coordinates>/);
        if (!coordMatch) {
            throw new Error('No se encontraron coordenadas en el KML');
        }

        const rawCoords = coordMatch[1].trim();
        const puntos = rawCoords.split(/\s+/).map(p => {
            const parts = p.split(',');
            if (parts.length >= 2) {
                return {
                    lon: parseFloat(parts[0]),
                    lat: parseFloat(parts[1])
                };
            }
            return null;
        }).filter(p => p !== null);

        console.log(`   Nombre: ${nombreRuta}`);
        console.log(`   Puntos encontrados: ${puntos.length}`);

        // Actualizar documento de la ruta (mantener datos existentes)
        await db.collection('rutas').doc(rutaId).set({
            nombre: nombreRuta,
            codigo: '18',
            color: '#FF5722', // Rojo para ruta 18
            activa: true,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // Eliminar puntos anteriores
        console.log('   Limpiando puntos anteriores...');
        const puntosRef = db.collection('rutas').doc(rutaId).collection('puntos_control');
        const oldPoints = await puntosRef.get();
        const batch = db.batch();
        oldPoints.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
        console.log('   Puntos anteriores eliminados.');

        // Guardar puntos nuevos
        console.log('   Guardando nuevos puntos...');
        let orden = 0;
        for (const punto of puntos) {
            await puntosRef.add({
                latitud: punto.lat,
                longitud: punto.lon,
                orden: orden++,
                tipo: 'ida',
                es_paradero: false
            });
        }

        console.log(`✅ Ruta 18 re-importada exitosamente: ${puntos.length} puntos`);

    } catch (error) {
        console.error('❌ Error re-importando ruta 18:', error.message);
    }

    process.exit(0);
}

reimportarRuta18();
