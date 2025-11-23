// ════════════════════════════════════════════════════════
// 📍 SERVICIO DE UBICACIÓN - TRANSPORTE INTELIGENTE
// lib/services/location_service.dart
// MIGRADO A FIREBASE REALTIME DATABASE
// ════════════════════════════════════════════════════════

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _locationSubscription;
  String? _currentViajeId;
  String? _currentRutaId;

  // ════════════════════════════════════════════════════════
  // 🔐 PERMISOS Y SERVICIOS
  // ════════════════════════════════════════════════════════

  /// Verificar si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Solicitar permisos de ubicación
  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    return status.isGranted;
  }

  // ════════════════════════════════════════════════════════
  // 📍 OBTENER UBICACIÓN
  // ════════════════════════════════════════════════════════

  /// Obtener ubicación actual
  Future<Position?> getCurrentLocation() async {
    try {
      // Verificar si el servicio está habilitado
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Servicio de ubicación deshabilitado');
        return null;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Permisos de ubicación denegados');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permisos de ubicación denegados permanentemente');
        return null;
      }

      // Obtener posición
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
      return null;
    }
  }

  /// Obtener stream de ubicación en tiempo real
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 🔥 FIREBASE REALTIME DATABASE - ENVÍO DE GPS
  // ════════════════════════════════════════════════════════

  /// Iniciar envío automático de ubicación a Firebase
  Future<void> startSendingLocation({
    required String viajeId,
    required String rutaId,
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      _currentViajeId = viajeId;
      _currentRutaId = rutaId;

      print('📡 Iniciando envío de ubicación a Firebase...');
      print('   - Viaje: $viajeId');
      print('   - Ruta: $rutaId');

      // Cancelar suscripción anterior si existe
      await stopSendingLocation();

      // Suscribirse al stream de ubicación
      _locationSubscription = getLocationStream().listen(
        (position) async {
          await _sendLocationToFirebase(position);
        },
        onError: (error) {
          print('❌ Error en stream de ubicación: $error');
        },
      );

      print('✅ Envío de ubicación iniciado');
    } catch (e) {
      print('❌ Error al iniciar envío de ubicación: $e');
      rethrow;
    }
  }

  /// Enviar ubicación actual a Firebase Realtime Database
  Future<void> _sendLocationToFirebase(Position position) async {
    try {
      if (_auth.currentUser == null) return;

      final conductorId = _auth.currentUser!.uid;
      final ref = _rtdb.ref('ubicaciones_tiempo_real/$conductorId');

      await ref.set({
        'latitud': position.latitude,
        'longitud': position.longitude,
        'velocidad': position.speed * 3.6, // Convertir m/s a km/h
        'direccion': position.heading,
        'timestamp': ServerValue.timestamp,
        'viaje_id': _currentViajeId,
        'ruta_id': _currentRutaId,
      });

      print(
          '📍 Ubicación enviada: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Error enviando ubicación a Firebase: $e');
    }
  }

  /// Detener envío de ubicación
  Future<void> stopSendingLocation() async {
    try {
      if (_locationSubscription != null) {
        await _locationSubscription!.cancel();
        _locationSubscription = null;
        print('🛑 Envío de ubicación detenido');
      }

      // Eliminar ubicación del conductor en Firebase
      if (_auth.currentUser != null) {
        final conductorId = _auth.currentUser!.uid;
        await _rtdb.ref('ubicaciones_tiempo_real/$conductorId').remove();
        print('🗑️ Ubicación eliminada de Firebase');
      }

      _currentViajeId = null;
      _currentRutaId = null;
    } catch (e) {
      print('❌ Error al detener envío de ubicación: $e');
    }
  }

  /// Enviar ubicación manualmente (una sola vez)
  Future<bool> sendLocationOnce({
    required String viajeId,
    required String rutaId,
  }) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        return false;
      }

      _currentViajeId = viajeId;
      _currentRutaId = rutaId;

      await _sendLocationToFirebase(position);
      return true;
    } catch (e) {
      print('❌ Error enviando ubicación: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 📊 ESCUCHAR UBICACIONES DE OTROS CONDUCTORES
  // ════════════════════════════════════════════════════════

  /// Escuchar ubicaciones de todos los conductores en tiempo real
  Stream<Map<String, dynamic>> listenToAllLocations() {
    return _rtdb.ref('ubicaciones_tiempo_real').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};

      return Map<String, dynamic>.from(
        data.map((key, value) => MapEntry(
              key.toString(),
              Map<String, dynamic>.from(value as Map),
            )),
      );
    });
  }

  /// Escuchar ubicación de un conductor específico
  Stream<Map<String, dynamic>?> listenToLocationByConductor(
      String conductorId) {
    return _rtdb
        .ref('ubicaciones_tiempo_real/$conductorId')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    });
  }

  // ════════════════════════════════════════════════════════
  // 🧮 CÁLCULOS DE DISTANCIA
  // ════════════════════════════════════════════════════════

  /// Calcular distancia entre dos puntos (en metros)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calcular distancia entre dos puntos (en kilómetros)
  double calculateDistanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateDistance(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Verificar si está cerca de un punto (dentro de un radio en metros)
  bool isNearLocation({
    required double currentLat,
    required double currentLon,
    required double targetLat,
    required double targetLon,
    double radiusMeters = 50.0,
  }) {
    final distance =
        calculateDistance(currentLat, currentLon, targetLat, targetLon);
    return distance <= radiusMeters;
  }

  // ════════════════════════════════════════════════════════
  // 🧹 CLEANUP
  // ════════════════════════════════════════════════════════

  /// Limpiar recursos al cerrar la app
  Future<void> dispose() async {
    await stopSendingLocation();
  }
}
