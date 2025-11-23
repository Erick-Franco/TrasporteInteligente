// ════════════════════════════════════════════════════════
// 👨‍✈️ PROVIDER DE CONDUCTOR - TRANSPORTE INTELIGENTE
// lib/presentation/providers/conductor_provider.dart
// MIGRADO A FIREBASE
// ════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/conductor_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class ConductorProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();

  Conductor? _conductor;
  bool _estaLogeado = false;
  bool _cargando = false;
  String? _error;
  String _sentidoActual = 'ida';
  bool _gpsActivo = false;
  String? _viajeActualId;

  // Getters
  Conductor? get conductor => _conductor;
  bool get estaLogeado => _estaLogeado;
  bool get cargando => _cargando;
  String? get error => _error;
  String get sentidoActual => _sentidoActual;
  bool get gpsActivo => _gpsActivo;
  String? get viajeActualId => _viajeActualId;
  bool get tieneViajeActivo => _viajeActualId != null;

  // ════════════════════════════════════════════════════════
  // 🔐 LOGIN
  // ════════════════════════════════════════════════════════

  // StreamSubscription para escuchar cambios en tiempo real
  StreamSubscription<DocumentSnapshot>? _conductorSubscription;

  // ════════════════════════════════════════════════════════
  // 🔐 LOGIN
  // ════════════════════════════════════════════════════════

  /// Login con email y contraseña (Firebase Auth)
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
      print('🔐 Intentando login con Firebase Auth...');
      print('   Email: $correo');

      final conductor = await AuthService.loginConductor(
        email: correo,
        password: contrasena,
      );

      if (conductor != null) {
        _conductor = conductor;
        _estaLogeado = true;
        _sentidoActual = 'ida';

        print('✅ Login exitoso');
        print('   Conductor: ${conductor.nombre}');
        print('   UID: ${conductor.id}');

        // INICIAR ESCUCHA EN TIEMPO REAL
        _iniciarEscuchaConductor(conductor.id);

        // Verificar si tiene viaje activo
        await _verificarViajeActivo();

        // Verificar si tiene vehículo y ruta antes de activar GPS
        if (conductor.vehiculoId == null || conductor.rutaId == null) {
          _error =
              'Conductor sin vehículo o ruta asignada. Esperando asignación...';
          print('⚠️ $_error');
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
      print('❌ Error en login: $_error');
      return false;
    }
  }

  /// Iniciar escucha de cambios en el documento del conductor
  void _iniciarEscuchaConductor(String uid) {
    print('🎧 Iniciando escucha de cambios para conductor: $uid');

    // Cancelar suscripción anterior si existe
    _conductorSubscription?.cancel();

    _conductorSubscription = FirebaseFirestore.instance
        .collection('conductores')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        print('🔄 Datos de conductor actualizados en tiempo real');
        try {
          final data = snapshot.data()!;
          data['id'] = snapshot.id;

          // Actualizar modelo completo
          _conductor = Conductor.fromJson(data);

          // Verificar si ahora tiene todo lo necesario
          if (_conductor!.puedeConducir && !_gpsActivo) {
            print('✅ Conductor ahora tiene vehículo y ruta. Activando GPS...');
            _iniciarSeguimientoGPS();
            _error = null;
          }

          notifyListeners();
        } catch (e) {
          print('❌ Error procesando actualización de conductor: $e');
        }
      }
    }, onError: (e) {
      print('❌ Error en stream de conductor: $e');
    });
  }

  /// Login con licencia (compatibilidad)
  Future<bool> loginConductorConLicencia({
    required String licencia,
    required String password,
  }) async {
    // Convertir licencia a email si no lo es
    final email =
        licencia.contains('@') ? licencia : '$licencia@transporte.com';
    return await loginConductor(correo: email, contrasena: password);
  }

  /// Verificar si hay viaje activo
  Future<void> _verificarViajeActivo() async {
    try {
      final viajeActual = await AuthService.obtenerViajeActual();
      if (viajeActual != null && viajeActual['estado'] == 'activo') {
        _viajeActualId = viajeActual['id'];
        print('✅ Viaje activo encontrado: $_viajeActualId');
      } else {
        _viajeActualId = null;
        print('ℹ️ No hay viaje activo');
      }
    } catch (e) {
      print('❌ Error verificando viaje activo: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 📍 GPS Y UBICACIÓN
  // ════════════════════════════════════════════════════════

  /// Iniciar seguimiento GPS
  Future<void> _iniciarSeguimientoGPS() async {
    if (_conductor == null || !_estaLogeado) return;

    try {
      // Verificar permisos
      final permisosOk = await _locationService.requestLocationPermission();

      if (!permisosOk) {
        _error = 'Se necesitan permisos de ubicación para el modo conductor';
        notifyListeners();
        return;
      }

      // Obtener ubicación inicial
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        _error = 'No se pudo obtener la ubicación GPS';
        notifyListeners();
        return;
      }

      print(
          '📍 GPS Conductor activado: ${position.latitude}, ${position.longitude}');

      _gpsActivo = true;
      notifyListeners();

      print('✅ GPS activado para conductor ${_conductor!.id}');
    } catch (e) {
      print('❌ Error iniciando GPS conductor: $e');
      _error = 'Error al activar GPS: $e';
      _gpsActivo = false;
      notifyListeners();
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
  // 🎯 GESTIÓN DE VIAJES
  // ════════════════════════════════════════════════════════

  /// Iniciar viaje
  Future<bool> iniciarViaje() async {
    print('═══════════════════════════════════════');
    print('🚀 MÉTODO iniciarViaje() LLAMADO');
    print('═══════════════════════════════════════');

    // Validaciones
    if (_conductor == null || !_estaLogeado) {
      _error = 'Debes estar logueado';
      print('❌ FALLO: No está logueado');
      notifyListeners();
      return false;
    }

    if (_conductor!.vehiculoId == null || _conductor!.rutaId == null) {
      _error = 'No tienes vehículo o ruta asignada';
      print('❌ FALLO: Sin vehículo o ruta');
      notifyListeners();
      return false;
    }

    if (tieneViajeActivo) {
      _error = 'Ya tienes un viaje activo';
      print('❌ FALLO: Ya tiene viaje activo');
      notifyListeners();
      return false;
    }

    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      print('📊 DATOS DEL VIAJE:');
      print('   Conductor UID: ${_conductor!.id}');
      print('   Vehículo ID: ${_conductor!.vehiculoId}');
      print('   Ruta ID: ${_conductor!.rutaId}');
      print('   Sentido: $_sentidoActual');

      // Iniciar viaje en Firebase
      final viaje = await AuthService.iniciarViaje(
        vehiculoId: _conductor!.vehiculoId!,
        rutaId: _conductor!.rutaId!,
        tipo: _sentidoActual,
      );

      if (viaje != null && viaje['id'] != null) {
        _viajeActualId = viaje['id'];

        print('✅ ¡VIAJE INICIADO EXITOSAMENTE!');
        print('   Viaje ID: $_viajeActualId');

        // IMPORTANTE: Actualizar el documento del conductor en Firestore
        // para que aparezca en el panel del gerente
        try {
          await FirebaseFirestore.instance
              .collection('conductores')
              .doc(_conductor!.id)
              .update({
            'disponible': true,
            'ruta_id': _conductor!.rutaId,
            'viaje_actual_id': _viajeActualId,
            'ultima_actualizacion': FieldValue.serverTimestamp(),
          });
          print('✅ Documento del conductor actualizado en Firestore');
        } catch (e) {
          print('⚠️ Error actualizando conductor en Firestore: $e');
          // No fallar el viaje por esto, solo registrar el error
        }

        // Iniciar envío automático de GPS a Firebase Realtime Database
        await _locationService.startSendingLocation(
          viajeId: _viajeActualId!,
          rutaId: _conductor!.rutaId!,
        );

        print('📍 Envío automático de GPS iniciado');

        _cargando = false;
        notifyListeners();
        return true;
      }

      _error = 'No se pudo iniciar el viaje';
      _cargando = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════');
      print('❌ EXCEPCIÓN CAPTURADA');
      print('Error: $e');
      print('Stack trace: $stackTrace');
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

    if (!tieneViajeActivo || _viajeActualId == null) {
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
      print('   Viaje ID: $_viajeActualId');

      // Detener envío de GPS
      await _locationService.stopSendingLocation();
      print('📍 Envío de GPS detenido');

      // Finalizar viaje en Firebase
      final success = await AuthService.finalizarViaje(_viajeActualId!);

      if (success) {
        // IMPORTANTE: Actualizar el documento del conductor en Firestore
        // para que desaparezca del panel del gerente
        try {
          await FirebaseFirestore.instance
              .collection('conductores')
              .doc(_conductor!.id)
              .update({
            'disponible': false,
            'viaje_actual_id': null,
            'ultima_actualizacion': FieldValue.serverTimestamp(),
          });
          print('✅ Documento del conductor actualizado (disponible: false)');
        } catch (e) {
          print('⚠️ Error actualizando conductor en Firestore: $e');
          // No fallar la finalización por esto
        }

        _viajeActualId = null;
        _cargando = false;
        notifyListeners();

        print('✅ Viaje finalizado exitosamente');
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

  // ════════════════════════════════════════════════════════
  // 🚪 LOGOUT
  // ════════════════════════════════════════════════════════

  /// Cerrar sesión
  Future<void> logout() async {
    // Finalizar viaje si hay uno activo
    if (tieneViajeActivo) {
      print('🛑 Finalizando viaje antes de cerrar sesión...');
      await finalizarViaje();
    }

    // Detener GPS
    await _locationService.stopSendingLocation();

    // Cancelar suscripción
    _conductorSubscription?.cancel();

    // Cerrar sesión en Firebase
    await AuthService.logout();

    _conductor = null;
    _estaLogeado = false;
    _error = null;
    _sentidoActual = 'ida';
    _cargando = false;
    _gpsActivo = false;
    _viajeActualId = null;
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

  /// Recargar información del conductor (Manual)
  Future<void> recargarInfo() async {
    if (_conductor == null) return;
    // Ya no es estrictamente necesario con el stream, pero lo mantenemos por si acaso
    try {
      final info = await AuthService.obtenerInfoConductor();
      if (info != null) {
        _conductor =
            Conductor.fromJson(info); // Usar fromJson para mapeo completo
        await _verificarViajeActivo();
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error recargando info: $e');
    }
  }

  @override
  void dispose() {
    print('🛑 ConductorProvider dispose');
    _conductorSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
