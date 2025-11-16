// ════════════════════════════════════════════════════════
// 🚌 REPOSITORIO DE BUSES - TRANSPORTE INTELIGENTE
// lib/data/repositories/bus_repository.dart
// ════════════════════════════════════════════════════════

import 'package:geolocator/geolocator.dart'; // ✅ Para cálculo de distancias
import '../models/bus_model.dart';
import '../../services/api_service.dart';

class BusRepository {
  final ApiService _apiService = ApiService();

  // ════════════════════════════════════════════════════════
  // 🚌 OBTENER BUSES
  // ════════════════════════════════════════════════════════

  /// Obtener todos los buses activos
  Future<List<BusModel>> getBusesActivos() async {
    try {
      final data = await _apiService.getBusesActivos();
      return data.map((json) => BusModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error en BusRepository.getBusesActivos: $e');
      return [];
    }
  }

  /// Obtener buses de una ruta específica
  Future<List<BusModel>> getBusesPorRuta(int rutaId) async {
    try {
      final data = await _apiService.getBusesPorRuta(rutaId);
      return data.map((json) => BusModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error en BusRepository.getBusesPorRuta: $e');
      return [];
    }
  }

  /// Obtener un bus por ID
  Future<BusModel?> getBusPorId(int busId) async {
    try {
      final data = await _apiService.getBusById(busId);
      if (data != null) {
        return BusModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error en BusRepository.getBusPorId: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // 📍 UBICACIÓN
  // ════════════════════════════════════════════════════════

  /// Actualizar ubicación de un bus (usado por conductor)
  Future<bool> actualizarUbicacionBus({
    required int busId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
  }) async {
    try {
      return await _apiService.actualizarUbicacionBus(
        busId: busId,
        latitud: latitud,
        longitud: longitud,
        velocidad: velocidad,
        direccion: direccion,
      );
    } catch (e) {
      print('❌ Error en BusRepository.actualizarUbicacionBus: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔍 BÚSQUEDA Y FILTROS (MÉTODOS LOCALES)
  // ════════════════════════════════════════════════════════

  /// Buscar buses cercanos a una ubicación (filtrado local)
  /// Primero obtiene todos los buses activos, luego filtra por distancia
  Future<List<BusModel>> getBusesCercanos(
    double lat,
    double lng, {
    double radio = 5.0,
  }) async {
    try {
      // Obtener todos los buses activos
      final todosBuses = await getBusesActivos();

      // Filtrar localmente por distancia
      return todosBuses.where((bus) {
        if (bus.latitud == null || bus.longitud == null) return false;

        final distancia = _calcularDistancia(
          lat,
          lng,
          bus.latitud!,
          bus.longitud!,
        );

        return distancia <= radio;
      }).toList();
    } catch (e) {
      print('❌ Error en BusRepository.getBusesCercanos: $e');
      return [];
    }
  }

  /// Calcular distancia entre dos puntos GPS usando Geolocator
  double _calcularDistancia(
      double lat1, double lon1, double lat2, double lon2) {
    // Retorna distancia en kilómetros
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // ════════════════════════════════════════════════════════
  // 📊 ESTADÍSTICAS Y FILTROS
  // ════════════════════════════════════════════════════════

  /// Obtener buses agrupados por ruta
  Future<Map<int, List<BusModel>>> getBusesPorRutaAgrupados() async {
    try {
      final buses = await getBusesActivos();
      final Map<int, List<BusModel>> agrupados = {};

      for (var bus in buses) {
        if (bus.rutaId != null) {
          agrupados.putIfAbsent(bus.rutaId!, () => []).add(bus);
        }
      }

      return agrupados;
    } catch (e) {
      print('❌ Error en BusRepository.getBusesPorRutaAgrupados: $e');
      return {};
    }
  }

  /// Obtener buses en movimiento
  Future<List<BusModel>> getBusesEnMovimiento() async {
    try {
      final buses = await getBusesActivos();
      return buses.where((bus) => (bus.velocidad ?? 0) > 0).toList();
    } catch (e) {
      print('❌ Error en BusRepository.getBusesEnMovimiento: $e');
      return [];
    }
  }

  /// Obtener buses detenidos
  Future<List<BusModel>> getBusesDetenidos() async {
    try {
      final buses = await getBusesActivos();
      return buses.where((bus) => (bus.velocidad ?? 0) == 0).toList();
    } catch (e) {
      print('❌ Error en BusRepository.getBusesDetenidos: $e');
      return [];
    }
  }
}
