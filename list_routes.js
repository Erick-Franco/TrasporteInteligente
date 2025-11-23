const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`
});

const db = admin.firestore();

async function listarRutas() {
    try {
        console.log('\n📋 Listando rutas en Firebase...\n');
        const snapshot = await db.collection('rutas').get();

        if (snapshot.empty) {
            console.log('❌ No hay rutas en Firebase');
            return;
        }

        console.log(`✅ Total de rutas: ${snapshot.size}\n`);

        snapshot.forEach(doc => {
            const data = doc.data();
            console.log(`🚌 ${doc.id}`);
            console.log(`   Nombre: ${data.nombre || 'Sin nombre'}`);
            console.log(`   Código: ${data.codigo || 'Sin código'}`);
            console.log(`   Color: ${data.color || 'Sin color'}`);
            console.log('');
        });

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

listarRutas();
