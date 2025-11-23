// ════════════════════════════════════════════════════════
// 🌐 SERVICIO API REST - TRANSPORTE INTELIGENTE
// lib/services/api_service.dart
// ════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Cliente HTTP con timeout
  final _client = http.Client();
  final _timeout = Duration(seconds: AppConstants.requestTimeout);

  // ════════════════════════════════════════════════════════
  // 🔧 MÉTODOS GENÉRICOS HTTP
  // ════════════════════════════════════════════════════════

  /// GET request genérico
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');

      if (AppConstants.enableLogs) {
        print('📤 GET: $url');
      }

      final response = await _client.get(url).timeout(_timeout);

      if (AppConstants.enableLogs) {
        print(
            '📥 Response ${response.statusCode}: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          'Error ${response.statusCode}',
          response.statusCode,
          response.body,
        );
      }
    } on TimeoutException {
      throw ApiException(AppConstants.errorTimeout, 408, 'Request timeout');
    } catch (e) {
      print('❌ Error en GET $endpoint: $e');
      rethrow;
    }
  }

  /// POST request genérico
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');

      if (AppConstants.enableLogs) {
        print('📤 POST: $url');
        print('📦 Body: ${json.encode(body)}');
      }

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (AppConstants.enableLogs) {
        print('📥 Response ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          'Error ${response.statusCode}',
          response.statusCode,
          response.body,
        );
      }
    } on TimeoutException {
      throw ApiException(AppConstants.errorTimeout, 408, 'Request timeout');
    } catch (e) {
      print('❌ Error en POST $endpoint: $e');
      rethrow;
    }
  }

  /// PUT request genérico
  Future<Map<String, dynamic>> _put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');

      if (AppConstants.enableLogs) {
        print('📤 PUT: $url');
        print('📦 Body: ${json.encode(body)}');
      }

      final response = await _client
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (AppConstants.enableLogs) {
        print('📥 Response ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          'Error ${response.statusCode}',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      print('❌ Error en PUT $endpoint: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🛣️ ENDPOINTS DE RUTAS
  // ════════════════════════════════════════════════════════

  /// Obtener todas las rutas activas
  Future<List<dynamic>> getRutas() async {
    try {
      final result = await _get(AppConstants.rutasEndpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener rutas: $e');
      return [];
    }
  }

  /// Obtener una ruta específica por ID
  Future<Map<String, dynamic>?> getRutaById(int rutaId) async {
    try {
      final result = await _get(AppConstants.rutaByIdEndpoint(rutaId));
      return result['data'];
    } catch (e) {
      print('❌ Error al obtener ruta $rutaId: $e');
      return null;
    }
  }

  /// Obtener puntos GPS de una ruta (trayectoria)
  /// @param tipo: 'ida' o 'vuelta'
  Future<List<dynamic>> getRutaPuntos(int rutaId, String tipo) async {
    try {
      final result = await _get(AppConstants.rutaPuntosEndpoint(rutaId, tipo));
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener puntos de ruta $rutaId: $e');
      return [];
    }
  }

  /// Obtener paraderos de una ruta
  Future<List<dynamic>> getRutaParaderos(int rutaId) async {
    try {
      final result = await _get(AppConstants.rutaParaderosEndpoint(rutaId));
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener paraderos de ruta $rutaId: $e');
      return [];
    }
  }

  /// Guardar/actualizar puntos de una ruta (batch)
  /// body: { tipo: 'ida'|'vuelta', puntos: [ {latitud, longitud, orden}, ... ] }
  Future<bool> guardarRutaPuntos({
    required int rutaId,
    required String tipo,
    required List<Map<String, dynamic>> puntos,
  }) async {
    try {
      final result = await _post(
        AppConstants.rutaGuardarPuntosEndpoint(rutaId),
        {
          'tipo': tipo,
          'puntos': puntos,
        },
      );
      return result['success'] == true;
    } catch (e) {
      print('❌ Error guardando puntos de ruta $rutaId: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🚌 ENDPOINTS DE BUSES
  // ════════════════════════════════════════════════════════

  /// Obtener todos los buses activos con ubicación GPS
  Future<List<dynamic>> getBusesActivos() async {
    try {
      final result = await _get(AppConstants.busesActivosEndpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener buses activos: $e');
      return [];
    }
  }

  /// Obtener buses de una ruta específica
  Future<List<dynamic>> getBusesPorRuta(int rutaId) async {
    try {
      final result = await _get(AppConstants.busesPorRutaEndpoint(rutaId));
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener buses de ruta $rutaId: $e');
      return [];
    }
  }

  /// Obtener información de un bus específico
  Future<Map<String, dynamic>?> getBusById(int busId) async {
    try {
      final result = await _get(AppConstants.busByIdEndpoint(busId));
      return result['data'];
    } catch (e) {
      print('❌ Error al obtener bus $busId: $e');
      return null;
    }
  }

  /// Actualizar ubicación de un bus (usado por conductor)
  Future<bool> actualizarUbicacionBus({
    required int busId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
  }) async {
    try {
      final result = await _post(
        AppConstants.busUbicacionEndpoint(busId),
        {
          'latitud': latitud,
          'longitud': longitud,
          'velocidad': velocidad,
          'direccion': direccion,
        },
      );
      return result['success'] == true;
    } catch (e) {
      print('❌ Error actualizando ubicación bus $busId: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 👨‍✈️ ENDPOINTS DE CONDUCTORES
  // ════════════════════════════════════════════════════════

  /// Login del conductor
  Future<Map<String, dynamic>?> loginConductor({
    required String licencia,
    required String password,
  }) async {
    try {
      final result = await _post(
        AppConstants.conductorLoginEndpoint,
        {
          'licencia': licencia,
          'password': password,
        },
      );
      return result['data'];
    } catch (e) {
      print('❌ Error en login conductor: $e');
      return null;
    }
  }

  /// Obtener información del conductor
  Future<Map<String, dynamic>?> getConductorById(int conductorId) async {
    try {
      final result =
          await _get(AppConstants.conductorByIdEndpoint(conductorId));
      return result['data'];
    } catch (e) {
      print('❌ Error al obtener conductor $conductorId: $e');
      return null;
    }
  }

  /// Obtener viaje actual del conductor
  Future<Map<String, dynamic>?> getViajeActualConductor(int conductorId) async {
    try {
      final result =
          await _get(AppConstants.conductorViajeActualEndpoint(conductorId));
      return result['data'];
    } catch (e) {
      print('❌ Error al obtener viaje actual: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎯 ENDPOINTS DE VIAJES - COMPLETOS Y ACTUALIZADOS
  // ════════════════════════════════════════════════════════

  /// Iniciar un viaje
  Future<Map<String, dynamic>?> iniciarViaje({
    required int vehiculoId,
    required int rutaId,
    required int conductorId,
  }) async {
    try {
      print('🚀 API: Iniciando viaje...');
      print('   Vehículo: $vehiculoId');
      print('   Ruta: $rutaId');
      print('   Conductor: $conductorId');

      final result = await _post(
        AppConstants.viajesIniciarEndpoint,
        {
          'vehiculo_id': vehiculoId,
          'ruta_id': rutaId,
          'conductor_id': conductorId,
        },
      );

      if (result['success'] == true && result['data'] != null) {
        print('✅ API: Viaje iniciado correctamente');
        print('   Viaje ID: ${result['data']['id']}');
        return result['data'];
      }

      print('⚠️ API: Respuesta inesperada al iniciar viaje');
      return null;
    } catch (e) {
      print('❌ Error al iniciar viaje: $e');
      return null;
    }
  }

  /// Finalizar un viaje
  Future<bool> finalizarViaje(int viajeId) async {
    try {
      print('🛑 API: Finalizando viaje $viajeId...');

      final result = await _put(
        AppConstants.viajesFinalizarEndpoint(viajeId),
        {},
      );

      if (result['success'] == true) {
        print('✅ API: Viaje finalizado correctamente');
        return true;
      }

      print('⚠️ API: Respuesta inesperada al finalizar viaje');
      return false;
    } catch (e) {
      print('❌ Error al finalizar viaje $viajeId: $e');
      return false;
    }
  }

  /// Obtener viaje activo de un conductor específico
  Future<Map<String, dynamic>?> getViajeActivoConductor(int conductorId) async {
    try {
      final result = await _get('/api/viajes/conductor/$conductorId/activo');
      return result['data'];
    } catch (e) {
      print('❌ Error al obtener viaje activo del conductor $conductorId: $e');
      return null;
    }
  }

  /// Obtener todos los viajes activos
  Future<List<dynamic>> getViajesActivos() async {
    try {
      final result = await _get(AppConstants.viajesActivosEndpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener viajes activos: $e');
      return [];
    }
  }

  /// Obtener historial de viajes
  Future<List<dynamic>> getHistorialViajes({
    int? conductorId,
    String? fechaInicio,
    String? fechaFin,
    int? limite,
  }) async {
    try {
      String endpoint = AppConstants.viajesHistorialEndpoint;
      final params = <String>[];

      if (conductorId != null) params.add('conductor_id=$conductorId');
      if (fechaInicio != null) params.add('fecha_inicio=$fechaInicio');
      if (fechaFin != null) params.add('fecha_fin=$fechaFin');
      if (limite != null) params.add('limite=$limite');

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final result = await _get(endpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener historial de viajes: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  // 📍 ENDPOINTS DE UBICACIONES GPS
  // ════════════════════════════════════════════════════════

  /// Enviar ubicación GPS del conductor
  Future<bool> enviarUbicacionConductor({
    required int conductorId,
    required int vehiculoId,
    required int rutaId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
  }) async {
    try {
      final result = await _post(
        AppConstants.ubicacionesEndpoint,
        {
          'conductor_id': conductorId,
          'vehiculo_id': vehiculoId,
          'ruta_id': rutaId,
          'latitud': latitud,
          'longitud': longitud,
          'velocidad': velocidad,
          'direccion': direccion,
        },
      );
      return result['success'] == true;
    } catch (e) {
      print('❌ Error enviando ubicación conductor: $e');
      return false;
    }
  }

  /// Obtener última ubicación de un conductor
  Future<Map<String, dynamic>?> getUltimaUbicacionConductor(
      int conductorId) async {
    try {
      final result =
          await _get(AppConstants.ubicacionConductorEndpoint(conductorId));
      return result['data'];
    } catch (e) {
      print('❌ Error al obtener ubicación conductor $conductorId: $e');
      return null;
    }
  }

  /// Obtener historial de ubicaciones de un viaje
  Future<List<dynamic>> getHistorialUbicacionesViaje(int viajeId) async {
    try {
      final result = await _get(AppConstants.ubicacionViajeEndpoint(viajeId));
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener ubicaciones viaje $viajeId: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔔 ENDPOINTS DE EVENTOS DE PARADEROS
  // ════════════════════════════════════════════════════════

  /// Registrar paso por paradero
  Future<bool> registrarEventoParadero({
    required int viajeId,
    required int puntoControlId,
    required double latitud,
    required double longitud,
  }) async {
    try {
      final result = await _post(
        AppConstants.eventosParaderoEndpoint,
        {
          'viaje_id': viajeId,
          'punto_control_id': puntoControlId,
          'latitud': latitud,
          'longitud': longitud,
        },
      );
      return result['success'] == true;
    } catch (e) {
      print('❌ Error registrando evento paradero: $e');
      return false;
    }
  }

  /// Obtener eventos de un viaje
  Future<List<dynamic>> getEventosViaje(int viajeId) async {
    try {
      final result = await _get(AppConstants.eventosViajeEndpoint(viajeId));
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener eventos viaje $viajeId: $e');
      return [];
    }
  }

  /// Obtener buses próximos a llegar a un paradero
  Future<List<dynamic>> getBusesProximosParadero(int paraderoId) async {
    try {
      final result =
          await _get(AppConstants.busesProximosParaderoEndpoint(paraderoId));
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener buses próximos paradero $paraderoId: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  // 💬 ENDPOINTS DE CHAT
  // ════════════════════════════════════════════════════════

  /// Obtener mensajes del chat
  Future<List<dynamic>> getMensajesChat({int limit = 50}) async {
    try {
      final result =
          await _get('${AppConstants.chatMensajesEndpoint}?limit=$limit');
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener mensajes chat: $e');
      return [];
    }
  }

  /// Enviar mensaje al chat
  Future<bool> enviarMensajeChat({
    required String usuarioNombre,
    required String usuarioId,
    required String mensaje,
  }) async {
    try {
      final result = await _post(
        AppConstants.chatEnviarEndpoint,
        {
          'usuario_nombre': usuarioNombre,
          'usuario_id': usuarioId,
          'mensaje': mensaje,
        },
      );
      return result['success'] == true;
    } catch (e) {
      print('❌ Error enviando mensaje chat: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 📊 ENDPOINTS DE DASHBOARD
  // ════════════════════════════════════════════════════════

  /// Obtener resumen del sistema
  Future<Map<String, dynamic>?> getDashboardResumen() async {
    try {
      final result = await _get(AppConstants.dashboardResumenEndpoint);
      return result['data'];
    } catch (e) {
      print('❌ Error al obtener resumen dashboard: $e');
      return null;
    }
  }

  /// Obtener buses por estado
  Future<Map<String, dynamic>?> getBusesEstado() async {
    try {
      final result = await _get(AppConstants.dashboardBusesEstadoEndpoint);
      return result['data'];
    } catch (e) {
      print('❌ Error al obtener buses por estado: $e');
      return null;
    }
  }

  /// Obtener estadísticas de rutas
  Future<List<dynamic>> getRutasEstadisticas() async {
    try {
      final result =
          await _get(AppConstants.dashboardRutasEstadisticasEndpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('❌ Error al obtener estadísticas rutas: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  // 🏥 HEALTH CHECK
  // ════════════════════════════════════════════════════════

  /// Verificar estado del servidor
  Future<bool> checkHealth() async {
    try {
      final result = await _get(AppConstants.healthEndpoint);
      return result['status'] == 'ok';
    } catch (e) {
      print('❌ Error en health check: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🧹 CLEANUP
  // ════════════════════════════════════════════════════════

  /// Cerrar cliente HTTP
  void dispose() {
    _client.close();
  }
}

// ════════════════════════════════════════════════════════
// 🚨 CLASE DE EXCEPCIÓN PERSONALIZADA
// ════════════════════════════════════════════════════════

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException(this.message, [this.statusCode, this.body]);

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return 'ApiException: $message';
  }
}
