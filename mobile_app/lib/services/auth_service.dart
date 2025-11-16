// ════════════════════════════════════════════════════════
// 🔐 SERVICIO DE AUTENTICACIÓN - TRANSPORTE INTELIGENTE
// lib/services/auth_service.dart
// ════════════════════════════════════════════════════════

import '../data/models/conductor_model.dart';
import 'api_service.dart';

class AuthService {
  // Usar el ApiService existente para no duplicar código
  static final ApiService _apiService = ApiService();

  // ════════════════════════════════════════════════════════
  // 🔐 LOGIN DE CONDUCTOR
  // ════════════════════════════════════════════════════════

  /// Login de conductor con licencia y contraseña
  static Future<Conductor?> loginConductor({
    required String licencia,
    required String password,
  }) async {
    try {
      print('🔐 Intentando login conductor...');
      print('📝 Licencia: $licencia');

      final data = await _apiService.loginConductor(
        licencia: licencia,
        password: password,
      );

      if (data != null) {
        print('✅ Login exitoso - Conductor encontrado');
        return Conductor.fromJson(data);
      } else {
        print('❌ Login fallido: Credenciales incorrectas');
        throw Exception('Credenciales incorrectas');
      }
    } catch (e) {
      print('❌ Error en login conductor: $e');

      // Manejo específico de errores de conexión
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        throw Exception(
            'No se puede conectar al servidor. Verifica tu conexión.');
      }

      rethrow;
    }
  }

  /// Login alternativo con correo (para compatibilidad)
  static Future<Conductor?> loginConductorConCorreo({
    required String correo,
    required String contrasena,
    String? placa,
    String? linea,
  }) async {
    try {
      print('🔐 Intentando login conductor con correo...');
      print('📧 Correo: $correo');
      if (linea != null) print('🚗 Línea: $linea');
      if (placa != null) print('🚙 Placa: $placa');

      // El backend espera licencia, así que usamos el correo como licencia temporalmente
      // TODO: Actualizar backend para soportar login con correo
      final data = await _apiService.loginConductor(
        licencia: correo,
        password: contrasena,
      );

      if (data != null) {
        print('✅ Login exitoso');
        return Conductor.fromJson(data);
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } catch (e) {
      print('❌ Error en login: $e');

      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception('No se puede conectar al servidor.');
      }

      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════
  // 📍 UBICACIÓN DEL CONDUCTOR
  // ════════════════════════════════════════════════════════

  /// Actualizar ubicación del conductor
  static Future<bool> actualizarUbicacionConductor({
    required int conductorId,
    required int vehiculoId,
    required int rutaId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
  }) async {
    try {
      print(
          '📍 Enviando ubicación conductor $conductorId: $latitud, $longitud');

      final success = await _apiService.enviarUbicacionConductor(
        conductorId: conductorId,
        vehiculoId: vehiculoId,
        rutaId: rutaId,
        latitud: latitud,
        longitud: longitud,
        velocidad: velocidad,
        direccion: direccion,
      );

      if (success) {
        print('✅ Ubicación enviada correctamente');
      } else {
        print('❌ Error al enviar ubicación');
      }

      return success;
    } catch (e) {
      print('❌ Error actualizando ubicación: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 📊 INFORMACIÓN DEL CONDUCTOR
  // ════════════════════════════════════════════════════════

  /// Obtener información del conductor
  static Future<Map<String, dynamic>?> obtenerInfoConductor(
      int conductorId) async {
    try {
      print('👤 Obteniendo info del conductor $conductorId...');
      return await _apiService.getConductorById(conductorId);
    } catch (e) {
      print('❌ Error obteniendo info conductor: $e');
      return null;
    }
  }

  /// Obtener viaje actual del conductor
  static Future<Map<String, dynamic>?> obtenerViajeActual(
      int conductorId) async {
    try {
      print('🚗 Obteniendo viaje actual del conductor $conductorId...');
      return await _apiService.getViajeActualConductor(conductorId);
    } catch (e) {
      print('❌ Error obteniendo viaje actual: $e');
      return null;
    }
  }

  /// Obtener última ubicación del conductor
  static Future<Map<String, dynamic>?> obtenerUltimaUbicacion(
      int conductorId) async {
    try {
      return await _apiService.getUltimaUbicacionConductor(conductorId);
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎯 VIAJES
  // ════════════════════════════════════════════════════════

  /// Iniciar un viaje
  static Future<Map<String, dynamic>?> iniciarViaje({
    required int vehiculoId,
    required int rutaId,
    required int conductorId,
  }) async {
    try {
      print('🚀 Iniciando viaje...');
      print('   - Vehículo: $vehiculoId');
      print('   - Ruta: $rutaId');
      print('   - Conductor: $conductorId');

      final viaje = await _apiService.iniciarViaje(
        vehiculoId: vehiculoId,
        rutaId: rutaId,
        conductorId: conductorId,
      );

      if (viaje != null) {
        print('✅ Viaje iniciado: ${viaje['id']}');
      }

      return viaje;
    } catch (e) {
      print('❌ Error al iniciar viaje: $e');
      return null;
    }
  }

  /// Finalizar viaje
  static Future<bool> finalizarViaje(int viajeId) async {
    try {
      print('🏁 Finalizando viaje $viajeId...');
      final success = await _apiService.finalizarViaje(viajeId);

      if (success) {
        print('✅ Viaje finalizado');
      }

      return success;
    } catch (e) {
      print('❌ Error al finalizar viaje: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔔 EVENTOS DE PARADEROS
  // ════════════════════════════════════════════════════════

  /// Registrar llegada a un paradero
  static Future<bool> registrarLlegadaParadero({
    required int viajeId,
    required int puntoControlId,
    required double latitud,
    required double longitud,
  }) async {
    try {
      print('🛑 Registrando llegada a paradero $puntoControlId...');

      final success = await _apiService.registrarEventoParadero(
        viajeId: viajeId,
        puntoControlId: puntoControlId,
        latitud: latitud,
        longitud: longitud,
      );

      if (success) {
        print('✅ Llegada registrada');
      }

      return success;
    } catch (e) {
      print('❌ Error registrando llegada: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🚪 LOGOUT
  // ════════════════════════════════════════════════════════

  /// Cerrar sesión del conductor
  static Future<void> logout() async {
    print('🚪 Sesión de conductor cerrada');
    // Aquí puedes agregar lógica adicional si es necesario
    // Por ejemplo: limpiar tokens, notificar al servidor, etc.
  }

  // ════════════════════════════════════════════════════════
  // 🔧 MÉTODOS LEGACY (para compatibilidad)
  // ════════════════════════════════════════════════════════

  /// Cambiar sentido del conductor (método legacy)
  @Deprecated('Usa el provider de buses en su lugar')
  static Future<bool> cambiarSentidoConductor({
    required String conductorId,
    required String sentido,
  }) async {
    try {
      // El sentido se maneja ahora a nivel de la app, no del backend
      print('⚠️ cambiarSentidoConductor es un método legacy');
      return true;
    } catch (e) {
      print('❌ Error cambiando sentido: $e');
      return false;
    }
  }

  /// Obtener ruta del conductor (método legacy)
  @Deprecated('Usa RutaProvider.cargarRutaPorId() en su lugar')
  static Future<Map<String, dynamic>?> obtenerRutaConductor(
      String conductorId) async {
    try {
      final id = int.parse(conductorId);
      return await obtenerInfoConductor(id);
    } catch (e) {
      print('❌ Error obteniendo ruta conductor: $e');
      return null;
    }
  }
}
