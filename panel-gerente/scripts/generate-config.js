// Generador simple de `js/config.js` a partir de env vars en tiempo de build.
// Uso: `node scripts/generate-config.js` en el directorio `panel-gerente`.

const fs = require('fs');
const path = require('path');

const apiUrl = process.env.API_URL || 'http://localhost:3000/api';
const wsUrl = process.env.WS_URL || 'http://localhost:3000';

const content = `// Auto-generado por scripts/generate-config.js\nconst CONFIG = {\n  API_URL: '${apiUrl}',\n  WS_URL: '${wsUrl}',\n  UPDATE_INTERVAL: 5000,\n  MAP: { DEFAULT_CENTER: [-15.5000, -70.1333], DEFAULT_ZOOM: 13, MAX_ZOOM: 18, MIN_ZOOM: 11 },\n  BUS_COLORS: { default: '#3B82F6', moving: '#10B981', stopped: '#EF4444', slow: '#F59E0B' },\n  STORAGE: { GERENTE: 'gerente_data', TOKEN: 'gerente_token' },\n  MESSAGES: { LOGIN_SUCCESS: '¡Bienvenido!', LOGIN_ERROR: 'Credenciales inválidas', CONNECTION_ERROR: 'Error de conexión', NO_CONDUCTORS: 'No hay conductores activos en este momento', LOADING: 'Cargando...' }\n};\n\nif (typeof module !== 'undefined' && module.exports) module.exports = CONFIG;\n`;

const outPath = path.join(__dirname, '..', 'js', 'config.js');

fs.writeFileSync(outPath, content, 'utf8');
console.log(`✅ config.js generado en ${outPath}`);
