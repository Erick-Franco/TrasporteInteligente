// ════════════════════════════════════════════════════════
// 👨‍✈️ PROVIDER DE CONDUCTOR - TRANSPORTE INTELIGENTE
// lib/presentation/providers/conductor_provider.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/conductor_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class ConductorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Conductor? _conductor;
  bool _estaLogeado = false;
  bool _cargando = false;
  String? _error;
  String _sentidoActual = 'ida';
  bool _gpsActivo = false;

  // Getters
  Conductor? get conductor => _conductor;
  bool get estaLogeado => _estaLogeado;
  bool get cargando => _cargando;
  String? get error => _error;
  String get sentidoActual => _sentidoActual;
  bool get gpsActivo => _gpsActivo;

  // ════════════════════════════════════════════════════════
  // 🔐 LOGIN
  // ════════════════════════════════════════════════════════

  /// Login con licencia (método principal del backend)
  Future<bool> loginConductorConLicencia({
    required String licencia,
    required String password,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final conductor = await AuthService.loginConductor(
        licencia: licencia,
        password: password,
      );

      if (conductor != null) {
        _conductor = conductor;
        _estaLogeado = true;
        _sentidoActual = 'ida';

        print('✅ Login exitoso');
        print('   Conductor: ${conductor.nombre}');
        print('   Vehículo ID: ${conductor.vehiculoId}');
        print('   Ruta ID: ${conductor.rutaId}');
        print('   Viaje ID: ${conductor.viajeId}');
        print('   Viaje Estado: ${conductor.viajeEstado}');

        // Verificar si tiene vehículo y ruta antes de activar GPS
        if (conductor.vehiculoId == null || conductor.rutaId == null) {
          _error = 'Conductor sin vehículo o ruta asignada';
          print('⚠️ ${_error}');
        } else {
          // Activar GPS
          await _iniciarSeguimientoGPS();
        }

        _cargando = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales incorrectas o conductor no encontrado';
        _cargando = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  /// Login con correo (método alternativo para compatibilidad)
  Future<bool> loginConductor({
    required String correo,
    required String contrasena,
    String? placa,
    String? linea,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final conductor = await AuthService.loginConductorConCorreo(
        correo: correo,
        contrasena: contrasena,
        placa: placa,
        linea: linea,
      );

      if (conductor != null) {
        _conductor = conductor;
        _estaLogeado = true;
        _sentidoActual = 'ida';

        print('✅ Login exitoso');
        print('   Conductor: ${conductor.nombre}');
        print('   Vehículo ID: ${conductor.vehiculoId}');
        print('   Ruta ID: ${conductor.rutaId}');
        print('   Viaje ID: ${conductor.viajeId}');

        // Verificar si tiene vehículo y ruta
        if (conductor.vehiculoId == null || conductor.rutaId == null) {
          _error = 'Conductor sin vehículo o ruta asignada';
          print('⚠️ ${_error}');
        } else {
          // Activar GPS
          await _iniciarSeguimientoGPS();
        }

        _cargando = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales incorrectas o conductor no encontrado';
        _cargando = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 📍 GPS Y UBICACIÓN
  // ════════════════════════════════════════════════════════

  /// Iniciar seguimiento GPS
  Future<void> _iniciarSeguimientoGPS() async {
    if (_conductor == null || !_estaLogeado) return;

    try {
      final locationService = LocationService();

      // Verificar permisos
      final permisosOk = await locationService.requestLocationPermission();

      if (!permisosOk) {
        _error = 'Se necesitan permisos de ubicación para el modo conductor';
        notifyListeners();
        return;
      }

      // Obtener ubicación inicial
      final position = await locationService.getCurrentLocation();

      if (position == null) {
        _error = 'No se pudo obtener la ubicación GPS';
        notifyListeners();
        return;
      }

      print(
          '📍 GPS Conductor activado: ${position.latitude}, ${position.longitude}');

      // Solo enviar ubicación si tiene viaje activo
      if (_conductor!.tieneViajeActivo) {
        await _enviarUbicacionConductor(position);
        print('📍 Envío de GPS activado para conductor ${_conductor!.id}');
      } else {
        print(
            '⚠️ Conductor sin viaje activo - GPS NO se enviará hasta iniciar viaje');
      }

      _gpsActivo = true;
      notifyListeners();

      // Escuchar actualizaciones de ubicación
      locationService.getLocationStream().listen(
        (position) async {
          // Solo enviar si tiene viaje activo
          if (_conductor?.tieneViajeActivo == true) {
            await _enviarUbicacionConductor(position);
          }
        },
        onError: (error) {
          print('❌ Error en stream GPS: $error');
          _gpsActivo = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('❌ Error iniciando GPS conductor: $e');
      _error = 'Error al activar GPS: $e';
      _gpsActivo = false;
      notifyListeners();
    }
  }

  /// Enviar ubicación al servidor
  Future<void> _enviarUbicacionConductor(Position position) async {
    if (_conductor == null || !_estaLogeado) return;

    try {
      // Verificar que el conductor tenga vehículo y ruta
      if (_conductor!.vehiculoId == null || _conductor!.rutaId == null) {
        print('⚠️ Conductor sin vehículo o ruta asignada');
        return;
      }

      // Solo enviar si tiene viaje activo
      if (!_conductor!.tieneViajeActivo) {
        return;
      }

      if (kDebugMode) {
        print(
            '📍 Enviando ubicación: ${position.latitude}, ${position.longitude}');
        print('   Velocidad: ${position.speed} m/s');
        print('   Dirección: ${position.heading}°');
        print('   Sentido: $_sentidoActual');
      }

      // Enviar a la API
      final success = await AuthService.actualizarUbicacionConductor(
        conductorId: _conductor!.id,
        vehiculoId: _conductor!.vehiculoId!,
        rutaId: _conductor!.rutaId!,
        latitud: position.latitude,
        longitud: position.longitude,
        velocidad: position.speed * 3.6, // m/s a km/h
        direccion: position.heading,
      );

      if (!success) {
        print('⚠️ No se pudo enviar ubicación a la API');
      }
    } catch (e) {
      print('❌ Error enviando ubicación: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔄 CAMBIO DE SENTIDO
  // ════════════════════════════════════════════════════════

  /// Cambiar sentido del recorrido (ida/vuelta)
  Future<void> cambiarSentido(String nuevoSentido) async {
    if (_conductor == null || !_estaLogeado) return;

    try {
      // Validar sentido
      if (nuevoSentido != 'ida' && nuevoSentido != 'vuelta') {
        _error = 'Sentido inválido. Usa "ida" o "vuelta"';
        notifyListeners();
        return;
      }

      _sentidoActual = nuevoSentido;
      notifyListeners();

      print('✅ Sentido cambiado a: $nuevoSentido');
    } catch (e) {
      _error = 'Error cambiando sentido: $e';
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎯 GESTIÓN DE VIAJES - CON DEBUG COMPLETO
  // ════════════════════════════════════════════════════════

  /// Iniciar viaje CON DEBUG COMPLETO
  Future<bool> iniciarViaje() async {
    print('═══════════════════════════════════════');
    print('🚀 MÉTODO iniciarViaje() LLAMADO');
    print('═══════════════════════════════════════');

    // Validación 1
    print('🔍 Validación 1: ¿Conductor logueado?');
    print('   _conductor: $_conductor');
    print('   _estaLogeado: $_estaLogeado');

    if (_conductor == null || !_estaLogeado) {
      _error = 'Debes estar logueado';
      print('❌ FALLO: No está logueado');
      notifyListeners();
      return false;
    }
    print('✅ Validación 1 OK');

    // Validación 2
    print('🔍 Validación 2: ¿Tiene vehículo y ruta?');
    print('   vehiculoId: ${_conductor!.vehiculoId}');
    print('   rutaId: ${_conductor!.rutaId}');

    if (_conductor!.vehiculoId == null || _conductor!.rutaId == null) {
      _error = 'No tienes vehículo o ruta asignada';
      print('❌ FALLO: Sin vehículo o ruta');
      notifyListeners();
      return false;
    }
    print('✅ Validación 2 OK');

    // Validación 3
    print('🔍 Validación 3: ¿Ya tiene viaje activo?');
    print('   tieneViajeActivo: ${_conductor!.tieneViajeActivo}');
    print('   viajeId: ${_conductor!.viajeId}');
    print('   viajeEstado: ${_conductor!.viajeEstado}');

    if (_conductor!.tieneViajeActivo) {
      _error = 'Ya tienes un viaje activo';
      print('❌ FALLO: Ya tiene viaje activo');
      notifyListeners();
      return false;
    }
    print('✅ Validación 3 OK - NO tiene viaje activo');

    try {
      print('───────────────────────────────────────');
      print('📋 Preparando llamada al backend...');
      print('───────────────────────────────────────');

      _cargando = true;
      _error = null;
      notifyListeners();

      print('📊 DATOS DEL VIAJE:');
      print('   Conductor ID: ${_conductor!.id}');
      print('   Vehículo ID: ${_conductor!.vehiculoId}');
      print('   Ruta ID: ${_conductor!.rutaId}');
      print('   Conductor Nombre: ${_conductor!.nombre}');

      print('───────────────────────────────────────');
      print('🌐 Llamando a _apiService.iniciarViaje()...');
      print('───────────────────────────────────────');

      // ✅ USAR ApiService
      final viaje = await _apiService.iniciarViaje(
        vehiculoId: _conductor!.vehiculoId!,
        rutaId: _conductor!.rutaId!,
        conductorId: _conductor!.id,
      );

      print('───────────────────────────────────────');
      print('📥 RESPUESTA DEL BACKEND:');
      print('   viaje: $viaje');
      print('───────────────────────────────────────');

      if (viaje != null && viaje['id'] != null) {
        print('✅ Respuesta válida recibida');
        print('   Viaje ID: ${viaje['id']}');
        print('   Fecha salida: ${viaje['fecha_salida']}');
        print('   Estado: ${viaje['estado']}');

        // Actualizar conductor con datos del viaje
        _conductor = _conductor!.copyWith(
          viajeId: viaje['id'],
          viajeEstado: 'en_progreso',
        );

        _cargando = false;
        notifyListeners();

        print('═══════════════════════════════════════');
        print('✅ ¡VIAJE INICIADO EXITOSAMENTE!');
        print('   Viaje ID: ${viaje['id']}');
        print('   Estado: en_progreso');
        print('═══════════════════════════════════════');

        // Iniciar envío de GPS automáticamente
        if (_gpsActivo) {
          print('📍 GPS ya estaba activo, comenzando envío de ubicación');
        }

        return true;
      }

      // Si llegamos aquí, la respuesta no es válida
      print('❌ RESPUESTA INVÁLIDA');
      print('   viaje es null: ${viaje == null}');
      if (viaje != null) {
        print('   viaje[\'id\'] es null: ${viaje['id'] == null}');
        print('   Contenido de viaje: $viaje');
      }

      _error = 'No se pudo iniciar el viaje - Respuesta inválida del servidor';
      _cargando = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════');
      print('❌ EXCEPCIÓN CAPTURADA');
      print('═══════════════════════════════════════');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace);
      print('═══════════════════════════════════════');

      _error = 'Error al iniciar viaje: $e';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  /// Finalizar viaje
  Future<bool> finalizarViaje() async {
    if (_conductor == null || !_estaLogeado) {
      _error = 'Debes estar logueado';
      notifyListeners();
      return false;
    }

    // Verificar que tenga viaje activo
    if (_conductor!.viajeId == null) {
      _error = 'No hay viaje activo para finalizar';
      notifyListeners();
      print('❌ Error: $_error');
      return false;
    }

    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      print('🛑 Finalizando viaje...');
      print('   Viaje ID: ${_conductor!.viajeId}');

      // ✅ USAR ApiService
      final success = await _apiService.finalizarViaje(_conductor!.viajeId!);

      if (success) {
        // Limpiar viaje del conductor
        _conductor = _conductor!.copyWith(
          clearViajeId: true,
          clearViajeEstado: true,
        );

        _cargando = false;
        notifyListeners();

        print('✅ Viaje finalizado exitosamente');
        print('   GPS seguirá activo pero NO se enviará ubicación');

        return true;
      }

      _error = 'No se pudo finalizar el viaje';
      _cargando = false;
      notifyListeners();
      print('❌ Error: $_error');
      return false;
    } catch (e) {
      _error = 'Error al finalizar viaje: $e';
      _cargando = false;
      notifyListeners();
      print('❌ Error: $_error');
      return false;
    }
  }

  /// Registrar paso por paradero
  Future<void> registrarParadero(int paraderoId, Position position) async {
    if (_conductor == null || _conductor!.viajeId == null) return;

    try {
      await AuthService.registrarLlegadaParadero(
        viajeId: _conductor!.viajeId!,
        puntoControlId: paraderoId,
        latitud: position.latitude,
        longitud: position.longitude,
      );

      print('🛑 Paradero $paraderoId registrado');
    } catch (e) {
      print('❌ Error registrando paradero: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 🚪 LOGOUT
  // ════════════════════════════════════════════════════════

  /// Cerrar sesión
  Future<void> logout() async {
    // Finalizar viaje si hay uno activo
    if (_conductor?.tieneViajeActivo == true) {
      print('🛑 Finalizando viaje antes de cerrar sesión...');
      await finalizarViaje();
    }

    await AuthService.logout();

    _conductor = null;
    _estaLogeado = false;
    _error = null;
    _sentidoActual = 'ida';
    _cargando = false;
    _gpsActivo = false;
    notifyListeners();

    print('🚪 Sesión de conductor cerrada');
  }

  // ════════════════════════════════════════════════════════
  // 🔧 UTILIDADES
  // ════════════════════════════════════════════════════════

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Recargar información del conductor
  Future<void> recargarInfo() async {
    if (_conductor == null) return;

    try {
      final info = await AuthService.obtenerInfoConductor(_conductor!.id);
      if (info != null) {
        _conductor = Conductor.fromJson(info);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error recargando info: $e');
    }
  }

  @override
  void dispose() {
    print('🛑 ConductorProvider dispose');
    super.dispose();
  }
}
