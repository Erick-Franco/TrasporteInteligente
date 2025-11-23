// Test simple de conexion a Firestore
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

console.log('Inicializando Firebase Admin...');
console.log('Project ID:', serviceAccount.project_id);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`
});

const db = admin.firestore();

async function testFirestore() {
    try {
        console.log('\\nIntentando escribir un documento de prueba...');

        // Intentar escribir un documento simple
        await db.collection('test').doc('test_doc').set({
            mensaje: 'Hola desde Node.js',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log('OK Documento de prueba creado exitosamente!');

        // Leer el documento
        const doc = await db.collection('test').doc('test_doc').get();
        console.log('OK Documento leido:', doc.data());

        // Eliminar el documento de prueba
        await db.collection('test').doc('test_doc').delete();
        console.log('OK Documento de prueba eliminado');

        console.log('\\nFIRESTORE FUNCIONA CORRECTAMENTE!');
        console.log('El problema puede estar en la consulta a PostgreSQL o en los datos.');

    } catch (error) {
        console.error('\\nERROR al conectar con Firestore:');
        console.error('Codigo:', error.code);
        console.error('Mensaje:', error.message);
        console.error('\\nPosibles soluciones:');
        console.error('1. Espera 2-3 minutos despues de habilitar Firestore');
        console.error('2. Verifica que el Service Account tenga permisos de Editor');
        console.error('3. Verifica que Firestore este en modo Native (no Datastore)');
    } finally {
        process.exit(0);
    }
}

testFirestore();
