// ════════════════════════════════════════════════════════
// ⚙️ CONFIGURACIÓN - PANEL GERENTE
// panel-gerente/js/config.js
// ════════════════════════════════════════════════════════

const CONFIG = {
  // URL del backend (ajusta según tu servidor)
  // ⚠️ IMPORTANTE: Usa la misma IP que tu app Flutter
  API_URL: 'http://192.168.1.69:3000/api',  // ← Tu IP WiFi
  WS_URL: 'http://192.168.1.69:3000',        // ← Tu IP WiFi
  
  // Intervalo de actualización (en milisegundos)
  UPDATE_INTERVAL: 5000, // 5 segundos
  
  // Configuración del mapa
  MAP: {
    DEFAULT_CENTER: [-15.5000, -70.1333], // Juliaca, Perú
    DEFAULT_ZOOM: 13,
    MAX_ZOOM: 18,
    MIN_ZOOM: 11
  },
  
  // Iconos de buses (colores)
  BUS_COLORS: {
    default: '#3B82F6',    // Azul
    moving: '#10B981',     // Verde
    stopped: '#EF4444',    // Rojo
    slow: '#F59E0B'        // Amarillo
  },
  
  // LocalStorage keys
  STORAGE: {
    GERENTE: 'gerente_data',
    TOKEN: 'gerente_token'
  },
  
  // Mensajes
  MESSAGES: {
    LOGIN_SUCCESS: '¡Bienvenido!',
    LOGIN_ERROR: 'Credenciales inválidas',
    CONNECTION_ERROR: 'Error de conexión',
    NO_CONDUCTORS: 'No hay conductores activos en este momento',
    LOADING: 'Cargando...'
  }
};

// Exportar configuración
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CONFIG;
}