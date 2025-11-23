// ════════════════════════════════════════════════════════
// 🔧 CONFIGURACIÓN DE LA APP - TRANSPORTE INTELIGENTE
// lib/config/constants.dart
// ════════════════════════════════════════════════════════

class AppConstants {
  // ════════════════════════════════════════════════════════
  // 🌐 CONFIGURACIÓN DE SERVIDOR
  // ════════════════════════════════════════════════════════

  // ⚠️ IMPORTANTE: Cambia según donde estés trabajando
  //
  // Para EMULADOR ANDROID: usa '10.0.2.2:3000'
  // Para DISPOSITIVO REAL: usa tu IP local (ej: '192.168.1.100:3000')
  // Para PRODUCCIÓN: usa tu dominio de Vercel

  // 🔴 DESARROLLO LOCAL (cambia según tu caso)
  static const bool isDevelopment = true; // ⬅️ Cambia a false en producción

  // ✅ TU IP CONFIGURADA: 192.168.1.69 (Wi-Fi)
  // Si cambias de red WiFi, deberás actualizar esta IP

  // URLs Base - CELULAR FÍSICO CONECTADO A LA MISMA RED WiFi
  static const String localBaseUrl = 'http://192.168.1.69:3000'; // ✅ TU IP
  static const String localWsUrl = 'ws://192.168.1.69:3000'; // ✅ TU IP

  // Si usas emulador Android, usa estas:
  // static const String localBaseUrl = 'http://10.0.2.2:3000';
  // static const String localWsUrl = 'ws://10.0.2.2:3000';

  static const String prodBaseUrl = 'https://trasporte-inteligente.vercel.app';
  static const String prodWsUrl = 'wss://trasporte-inteligente.vercel.app';

  // URLs activas (se cambian automáticamente)
  static String get baseUrl => isDevelopment ? localBaseUrl : prodBaseUrl;
  static String get wsUrl => isDevelopment ? localWsUrl : prodWsUrl;

  // ════════════════════════════════════════════════════════
  // 📡 ENDPOINTS - SEGÚN TU BACKEND NODE.JS
  // ════════════════════════════════════════════════════════

  // 🛣️ RUTAS
  static const String rutasEndpoint = '/api/rutas';
  static String rutaByIdEndpoint(int id) => '/api/rutas/$id';
  static String rutaPuntosEndpoint(int id, String tipo) =>
      '/api/rutas/$id/puntos?tipo=$tipo';
  static String rutaParaderosEndpoint(int id) => '/api/rutas/$id/paraderos';
    // Endpoint para guardar/actualizar puntos de una ruta (POST)
    static String rutaGuardarPuntosEndpoint(int id) => '/api/rutas/$id/puntos';

  // 🚌 BUSES EN TIEMPO REAL
  static const String busesActivosEndpoint = '/api/buses/activos';
  static String busesPorRutaEndpoint(int rutaId) => '/api/buses/ruta/$rutaId';
  static String busByIdEndpoint(int id) => '/api/buses/$id';
  static String busUbicacionEndpoint(int busId) =>
      '/api/buses/$busId/ubicacion';

  // 👨‍✈️ CONDUCTORES
  static const String conductoresEndpoint = '/api/conductores';
  static const String conductorLoginEndpoint = '/api/conductores/login';
  static String conductorByIdEndpoint(int id) => '/api/conductores/$id';
  static String conductorViajeActualEndpoint(int id) =>
      '/api/conductores/$id/viaje-actual';

  // ⚠️ ENDPOINTS LEGACY (para compatibilidad con auth_service.dart)
  static const String conductorInfoEndpoint =
      '/api/conductores/:id/mi-informacion';
  static const String conductorRutaEndpoint = '/api/conductores/:id/mi-ruta';
  static const String ubicacionesConductorEndpoint =
      '/api/ubicaciones/conductor/:conductor_id';

  // 🎯 VIAJES
  static const String viajesEndpoint = '/api/viajes';
  static const String viajesIniciarEndpoint = '/api/viajes/iniciar';
  static String viajesFinalizarEndpoint(int id) => '/api/viajes/$id/finalizar';
  static const String viajesActivosEndpoint = '/api/viajes/activos';
  static const String viajesHistorialEndpoint = '/api/viajes/historial';

  // 📍 UBICACIONES GPS
  static const String ubicacionesEndpoint = '/api/ubicaciones';
  static String ubicacionConductorEndpoint(int conductorId) =>
      '/api/ubicaciones/conductor/$conductorId/ultima';
  static String ubicacionViajeEndpoint(int viajeId) =>
      '/api/ubicaciones/viaje/$viajeId';

  // 🔔 EVENTOS DE PARADEROS
  static const String eventosParaderoEndpoint = '/api/eventos/paradero';
  static String eventosViajeEndpoint(int viajeId) =>
      '/api/eventos/viaje/$viajeId';
  static String busesProximosParaderoEndpoint(int paraderoId) =>
      '/api/paraderos/$paraderoId/buses-proximos';

  // 💬 CHAT GLOBAL
  static const String chatMensajesEndpoint = '/api/chat/mensajes';
  static const String chatEnviarEndpoint = '/api/chat/enviar';

  // ⚠️ ENDPOINT LEGACY (para compatibilidad con chat_service.dart)
  static const String chatEndpoint = '/api/chat/mensajes'; // Alias

  // 📊 DASHBOARD
  static const String dashboardResumenEndpoint = '/api/dashboard/resumen';
  static const String dashboardBusesEstadoEndpoint =
      '/api/dashboard/buses-estado';
  static const String dashboardRutasEstadisticasEndpoint =
      '/api/dashboard/rutas-estadisticas';

  // 🏥 HEALTH CHECK
  static const String healthEndpoint = '/api/health';

  // ════════════════════════════════════════════════════════
  // 🗺️ CONFIGURACIÓN DEL MAPA - JULIACA, PERÚ
  // ════════════════════════════════════════════════════════
  static const double defaultZoom = 13.5;
  static const double defaultLat = -15.4800; // Juliaca
  static const double defaultLng = -70.1450; // Juliaca

  // Zoom levels
  static const double minZoom = 10.0;
  static const double maxZoom = 18.0;
  static const double paraderoZoom = 16.0;

  // ════════════════════════════════════════════════════════
  // ⏱️ INTERVALOS DE ACTUALIZACIÓN (en segundos)
  // ════════════════════════════════════════════════════════
  static const int updateIntervalBuses = 5; // Actualizar buses cada 5 seg
  static const int updateIntervalLocation =
      3; // Enviar GPS cada 3 seg (conductor)
  static const int updateIntervalChat = 2; // Actualizar chat cada 2 seg
  static const int reconnectInterval = 5; // Reconectar WebSocket cada 5 seg

  // ════════════════════════════════════════════════════════
  // 💬 CONFIGURACIÓN DEL CHAT
  // ════════════════════════════════════════════════════════
  static const int maxMensajesChat = 100; // Mostrar últimos 100 mensajes
  static const int maxCaracteresMensaje =
      500; // Máximo 500 caracteres por mensaje
  static const int mensajesIniciales = 50; // Cargar 50 mensajes al inicio

  // ════════════════════════════════════════════════════════
  // 🔍 BÚSQUEDA Y PROXIMIDAD
  // ════════════════════════════════════════════════════════
  static const double radioBusquedaKm = 5.0; // Radio de búsqueda en kilómetros
  static const double distanciaParaderoMetros =
      50.0; // Distancia para detectar paradero
  static const double distanciaBusCercaMetros =
      500.0; // Bus "cercano" a menos de 500m

  // ════════════════════════════════════════════════════════
  // 🎨 COLORES POR DEFECTO DE RUTAS
  // ════════════════════════════════════════════════════════
  static const String defaultRouteColor = '#FF5722'; // Naranja por defecto

  // Colores predefinidos para rutas
  static const Map<String, String> routeColors = {
    'L18': '#E91E63', // Rosa
    'L22': '#2196F3', // Azul
    'LNB': '#FF9800', // Naranja
    'L55': '#4CAF50', // Verde
  };

  // ════════════════════════════════════════════════════════
  // ⚙️ CONFIGURACIÓN GENERAL
  // ════════════════════════════════════════════════════════
  static const int requestTimeout = 30; // Timeout HTTP en segundos
  static const int maxRetries = 3; // Reintentos máximos
  static const bool enableLogs = true; // Habilitar logs de debug

  // ════════════════════════════════════════════════════════
  // 📱 INFORMACIÓN DE LA APP
  // ════════════════════════════════════════════════════════
  static const String appName = 'Transporte Inteligente';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Sistema de tracking de transporte público en tiempo real';

  // ════════════════════════════════════════════════════════
  // 🔐 CLAVES (NO SUBIR A PRODUCCIÓN)
  // ════════════════════════════════════════════════════════
  // TODO: Mover a variables de entorno en producción
  static const String googleMapsApiKey = 'TU_API_KEY_AQUI'; // ⚠️ Reemplazar

  // ════════════════════════════════════════════════════════
  // 📝 MENSAJES DE ERROR
  // ════════════════════════════════════════════════════════
  static const String errorConexion =
      'Error de conexión. Verifica tu internet.';
  static const String errorServidor =
      'Error en el servidor. Intenta más tarde.';
  static const String errorTimeout =
      'La solicitud tardó demasiado. Intenta nuevamente.';
  static const String errorDesconocido = 'Ocurrió un error inesperado.';
  static const String errorLogin = 'Credenciales incorrectas.';
  static const String errorGPS = 'No se pudo obtener tu ubicación.';

  // ════════════════════════════════════════════════════════
  // 🎯 HELPER PARA OBTENER URL COMPLETA
  // ════════════════════════════════════════════════════════
  static String getFullUrl(String endpoint) => '$baseUrl$endpoint';

  // ════════════════════════════════════════════════════════
  // 🔧 MÉTODOS ÚTILES
  // ════════════════════════════════════════════════════════

  /// Obtiene el color de una ruta por su código
  static String getRouteColor(String codigo) {
    return routeColors[codigo] ?? defaultRouteColor;
  }

  /// Verifica si estamos en modo desarrollo
  static bool isLocalMode() => isDevelopment;

  /// Imprime logs solo si están habilitados
  static void log(String message) {
    if (enableLogs) {
      print('🔧 [AppConstants] $message');
    }
  }
}
