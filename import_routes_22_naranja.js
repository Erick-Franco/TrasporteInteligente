const admin = require('firebase-admin');
const fs = require('fs');

// Inicializar Firebase Admin
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`
});

const db = admin.firestore();

async function importarRuta22() {
    const filePath = 'mobile_app/lib/data/models/rutas/MapeaMiRuta22.kml';
    const rutaId = 'ruta_22';

    try {
        console.log(`\n📂 Importando Ruta 22...`);
        const content = fs.readFileSync(filePath, 'utf8');

        // Extraer nombre
        const nameMatch = content.match(/<name>(.*?)<\/name>/);
        const nombreRuta = nameMatch ? nameMatch[1] : 'Línea 22';

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

        // Crear documento de la ruta
        await db.collection('rutas').doc(rutaId).set({
            nombre: nombreRuta,
            codigo: '22',
            color: '#4CAF50', // Verde para ruta 22
            activa: true,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });

        // Eliminar puntos anteriores
        const puntosRef = db.collection('rutas').doc(rutaId).collection('puntos_control');
        const oldPoints = await puntosRef.get();
        const batch = db.batch();
        oldPoints.forEach(doc => batch.delete(doc.ref));
        await batch.commit();

        // Guardar puntos
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

        console.log(`✅ Ruta 22 importada: ${puntos.length} puntos`);

    } catch (error) {
        console.error('❌ Error importando ruta 22:', error.message);
    }
}

async function importarRutaNaranja() {
    const filePath = 'mobile_app/lib/data/models/rutas/MapeaMiRuta naranja.kml';
    const rutaId = 'ruta_naranja';

    try {
        console.log(`\n📂 Importando Ruta Naranja...`);
        const content = fs.readFileSync(filePath, 'utf8');

        // Extraer nombre
        const nameMatch = content.match(/<name>(.*?)<\/name>/);
        const nombreRuta = nameMatch ? nameMatch[1] : 'Línea Naranja';

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

        // Crear documento de la ruta
        await db.collection('rutas').doc(rutaId).set({
            nombre: nombreRuta,
            codigo: 'NARANJA',
            color: '#FF9800', // Naranja
            activa: true,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });

        // Eliminar puntos anteriores
        const puntosRef = db.collection('rutas').doc(rutaId).collection('puntos_control');
        const oldPoints = await puntosRef.get();
        const batch = db.batch();
        oldPoints.forEach(doc => batch.delete(doc.ref));
        await batch.commit();

        // Guardar puntos
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

        console.log(`✅ Ruta Naranja importada: ${puntos.length} puntos`);

    } catch (error) {
        console.error('❌ Error importando ruta naranja:', error.message);
    }
}

async function main() {
    await importarRuta22();
    await importarRutaNaranja();
    console.log('\n✅ Importación completada\n');
    process.exit(0);
}

main();
