const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Inicializar Firebase Admin
// Asegúrate de que este archivo existe y es correcto
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`
});

const db = admin.firestore();

async function importarKML(filePath, rutaId, tipo = 'ida') {
    try {
        console.log(`\n📂 Leyendo archivo KML: ${filePath}`);
        const content = fs.readFileSync(filePath, 'utf8');

        // Extraer nombre
        const nameMatch = content.match(/<name>(.*?)<\/name>/);
        const nombreRuta = nameMatch ? nameMatch[1] : rutaId;

        console.log(`   Nombre detectado: ${nombreRuta}`);

        // Extraer coordenadas
        const coordMatch = content.match(/<coordinates>([\s\S]*?)<\/coordinates>/);
        if (!coordMatch) {
            throw new Error('No se encontraron coordenadas en el KML');
        }

        const rawCoords = coordMatch[1].trim();
        // Las coordenadas en KML son "lon,lat,alt" o "lon,lat" separadas por espacio
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

        console.log(`   Puntos encontrados: ${puntos.length}`);

        // Crear documento de la ruta
        console.log(`\n💾 Guardando ruta ${rutaId} en Firestore...`);
        await db.collection('rutas').doc(rutaId).set({
            codigo: rutaId.replace('ruta_', ''),
            nombre: nombreRuta,
            descripcion: `Importada desde KML`,
            color: '#FF5722', // Color por defecto
            activa: true, // IMPORTANTE: Para que se muestre en la app
            created_at: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // Guardar puntos de control
        // Muestrear puntos para no saturar (ej. cada 3 puntos si son muchos)
        const paso = puntos.length > 500 ? 5 : 1;
        console.log(`   Subiendo puntos (muestreo: cada ${paso} puntos)...`);

        const batchSize = 400; // Límite de batch de Firestore es 500
        let batch = db.batch();
        let count = 0;
        let totalSubidos = 0;

        // Borrar puntos anteriores de esta ruta y tipo para evitar duplicados
        console.log('   Limpiando puntos anteriores...');
        const snapshot = await db.collection('puntos_control')
            .where('ruta_id', '==', rutaId)
            .where('tipo', '==', tipo)
            .get();

        const deleteBatchSize = 400;
        let deleteBatch = db.batch();
        let deleteCount = 0;

        for (const doc of snapshot.docs) {
            deleteBatch.delete(doc.ref);
            deleteCount++;
            if (deleteCount >= deleteBatchSize) {
                await deleteBatch.commit();
                deleteBatch = db.batch();
                deleteCount = 0;
            }
        }
        if (deleteCount > 0) await deleteBatch.commit();
        console.log('   Puntos anteriores eliminados.');

        // Subir nuevos puntos
        for (let i = 0; i < puntos.length; i += paso) {
            const punto = puntos[i];
            const docRef = db.collection('puntos_control').doc();

            batch.set(docRef, {
                ruta_id: rutaId,
                nombre: `Punto ${i}`,
                tipo: tipo,
                orden: i,
                latitud: punto.lat,
                longitud: punto.lon,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });

            count++;
            totalSubidos++;

            if (count >= batchSize) {
                await batch.commit();
                console.log(`   ... ${totalSubidos} puntos subidos`);
                batch = db.batch();
                count = 0;
            }
        }

        if (count > 0) {
            await batch.commit();
        }

        console.log(`✅ Importación completada: ${totalSubidos} puntos guardados para ${rutaId} (${tipo})`);

    } catch (error) {
        console.error('❌ Error importando KML:', error);
    }
}

// Ejecutar importación
async function run() {
    // Ruta 18
    const kml18 = 'd:/Programacion/transporte_inteligente/mobile_app/lib/data/models/rutas/MapeaMiRuta18.kml';
    await importarKML(kml18, 'ruta_18', 'ida');

    // Ruta 33
    const kml33 = 'd:/Programacion/transporte_inteligente/mobile_app/lib/data/models/rutas/MapeaMiRuta33.kml';
    await importarKML(kml33, 'ruta_33', 'ida');
}

run();
