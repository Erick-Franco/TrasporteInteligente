// ════════════════════════════════════════════════════════
// 🔥 FIREBASE CONFIG - PANEL GERENTE
// panel-gerente/js/firebase-config.js
// ════════════════════════════════════════════════════════

// Configuración de Firebase (Extraída del proyecto transporte-inteligente-v2)
const firebaseConfig = {
  apiKey: "AIzaSyBgSrcCRQ6zKdnqmwwRNQHjFMcw4ycA-PA",
  authDomain: "transporte-inteligente-v2.firebaseapp.com",
  databaseURL: "https://transporte-inteligente-v2-default-rtdb.firebaseio.com",
  projectId: "transporte-inteligente-v2",
  storageBucket: "transporte-inteligente-v2.firebasestorage.app",
  messagingSenderId: "424113048334",
  appId: "1:424113048334:web:placeholder_id" // ⚠️ Reemplazar con App ID Web real si es necesario
};

// Inicializar Firebase
firebase.initializeApp(firebaseConfig);

// Referencias a servicios
const auth = firebase.auth();
const db = firebase.firestore();
const rtdb = firebase.database();

console.log('🔥 Firebase inicializado correctamente');
