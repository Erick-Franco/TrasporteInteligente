// ════════════════════════════════════════════════════════
// 🛣️ REPOSITORIO DE RUTAS - TRANSPORTE INTELIGENTE
// lib/data/repositories/ruta_repository.dart
// ════════════════════════════════════════════════════════

import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ruta_model.dart';
import '../models/parada_model.dart';
import '../../services/api_service.dart';

class RutaRepository {
  final ApiService _apiService = ApiService();

  // ════════════════════════════════════════════════════════
  // 🛣️ OBTENER RUTAS
  // ════════════════════════════════════════════════════════

  /// Obtener todas las rutas disponibles
  Future<List<RutaModel>> getRutas() async {
    try {
      final data = await _apiService.getRutas();
      return data.map((json) => RutaModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error en RutaRepository.getRutas: $e');
      return [];
    }
  }

  /// Obtener ruta completa por ID (con coordenadas GPS de ida y vuelta)
  Future<RutaModel?> getRutaCompleta(String rutaId) async {
    try {
      // 1. Obtener info básica de la ruta
      // final rutaData = await _apiService.getRutaById(rutaId);
      // if (rutaData == null) return null;

      // 2. Obtener puntos GPS de IDA
      // final puntosIdaData = await _apiService.getRutaPuntos(rutaId, 'ida');
      // ...

      // Retornamos null por ahora ya que usamos FirebaseService directamente en RutaProvider
      return null;
    } catch (e) {
      print('❌ Error en RutaRepository.getRutaCompleta: $e');
      return null;
    }
  }

  /// Obtener ruta por código (L18, L22, etc.)
  Future<RutaModel?> getRutaPorCodigo(String codigo) async {
    try {
      final rutas = await getRutas();

      // Buscar por nombre que contenga el código
      final ruta = rutas.firstWhere(
        (r) => r.nombre.toLowerCase().contains(codigo.toLowerCase()),
        orElse: () => throw Exception('Ruta no encontrada'),
      );

      // Cargar coordenadas completas
      return await getRutaCompleta(ruta.id);
    } catch (e) {
      print('❌ Error en RutaRepository.getRutaPorCodigo: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔍 BÚSQUEDA Y FILTROS
  // ════════════════════════════════════════════════════════

  /// Obtener rutas cercanas a una ubicación
  Future<List<RutaModel>> getRutasCercanas(
    double lat,
    double lng, {
    double radioKm = 3.0,
  }) async {
    try {
      // Obtener todas las rutas
      final todasRutas = await getRutas();
      final List<RutaModel> rutasCercanas = [];

      // Para cada ruta, cargar sus coordenadas y verificar distancia
      for (var ruta in todasRutas) {
        final rutaCompleta = await getRutaCompleta(ruta.id);
        if (rutaCompleta == null) continue;

        bool estaCerca = false;

        // Si la ruta tiene coordenadas de ida/vuelta, usarlas
        if ((rutaCompleta.coordinadasIda.isNotEmpty) ||
            (rutaCompleta.coordinadasVuelta.isNotEmpty)) {
          estaCerca = _verificarRutaCercana(
            rutaCompleta,
            lat,
            lng,
            radioKm,
          );
        } else {
          // Fallback: si no hay coordenadas, intentar con los paraderos de la ruta
          final paradas = await getParaderosRuta(ruta.id);
          for (var parada in paradas) {
            if (parada.tieneUbicacion) {
              final distancia = Geolocator.distanceBetween(
                    lat,
                    lng,
                    parada.latitud!,
                    parada.longitud!,
                  ) /
                  1000; // metros a km

              if (distancia <= radioKm) {
                estaCerca = true;
                break;
              }
            }
          }
        }

        if (estaCerca) {
          rutasCercanas.add(rutaCompleta);
        }
      }

      return rutasCercanas;
    } catch (e) {
      print('❌ Error en RutaRepository.getRutasCercanas: $e');
      return [];
    }
  }

  /// Verificar si algún punto de la ruta está cerca de una ubicación
  bool _verificarRutaCercana(
    RutaModel ruta,
    double lat,
    double lng,
    double radioKm,
  ) {
    // Verificar puntos de IDA
    for (var punto in ruta.coordinadasIda) {
      final distancia = Geolocator.distanceBetween(
            lat,
            lng,
            punto.latitude,
            punto.longitude,
          ) /
          1000; // metros a km

      if (distancia <= radioKm) return true;
    }

    // Verificar puntos de VUELTA
    for (var punto in ruta.coordinadasVuelta) {
      final distancia = Geolocator.distanceBetween(
            lat,
            lng,
            punto.latitude,
            punto.longitude,
          ) /
          1000;

      if (distancia <= radioKm) return true;
    }

    return false;
  }

  /// Buscar rutas por destino
  Future<List<RutaModel>> buscarRutasPorDestino(
    String destino,
    double miLat,
    double miLng, {
    double radioKm = 5.0,
  }) async {
    try {
      // Obtener todas las rutas
      final todasRutas = await getRutas();

      // Filtrar por nombre/descripción que contenga el destino
      final rutasFiltradas = todasRutas.where((ruta) {
        final nombre = ruta.nombre.toLowerCase();
        final desc = ruta.descripcion?.toLowerCase() ?? '';
        final busqueda = destino.toLowerCase();

        return nombre.contains(busqueda) || desc.contains(busqueda);
      }).toList();

      // Cargar coordenadas completas de las rutas encontradas
      final List<RutaModel> rutasCompletas = [];
      for (var ruta in rutasFiltradas) {
        final rutaCompleta = await getRutaCompleta(ruta.id);
        if (rutaCompleta != null) {
          rutasCompletas.add(rutaCompleta);
        }
      }

      // Ordenar por distancia al usuario
      rutasCompletas.sort((a, b) {
        final distA = _calcularDistanciaMinima(a, miLat, miLng);
        final distB = _calcularDistanciaMinima(b, miLat, miLng);
        return distA.compareTo(distB);
      });

      return rutasCompletas;
    } catch (e) {
      print('❌ Error en RutaRepository.buscarRutasPorDestino: $e');
      return [];
    }
  }

  /// Calcular distancia mínima entre una ubicación y cualquier punto de la ruta
  double _calcularDistanciaMinima(RutaModel ruta, double lat, double lng) {
    double distanciaMin = double.infinity;

    // Verificar puntos de IDA
    for (var punto in ruta.coordinadasIda) {
      final distancia = Geolocator.distanceBetween(
            lat,
            lng,
            punto.latitude,
            punto.longitude,
          ) /
          1000;

      if (distancia < distanciaMin) {
        distanciaMin = distancia;
      }
    }

    // Verificar puntos de VUELTA
    for (var punto in ruta.coordinadasVuelta) {
      final distancia = Geolocator.distanceBetween(
            lat,
            lng,
            punto.latitude,
            punto.longitude,
          ) /
          1000;

      if (distancia < distanciaMin) {
        distanciaMin = distancia;
      }
    }

    return distanciaMin;
  }

  // ════════════════════════════════════════════════════════
  // 🚏 PARADEROS (PUNTOS DE CONTROL)
  // ════════════════════════════════════════════════════════

  /// Obtener paraderos de una ruta
  Future<List<ParadaModel>> getParaderosRuta(String rutaId) async {
    try {
      // final data = await _apiService.getRutaParaderos(rutaId);
      // return data.map((json) => ParadaModel.fromJson(json)).toList();
      return [];
    } catch (e) {
      print('❌ Error en RutaRepository.getParaderosRuta: $e');
      return [];
    }
  }

  /// Obtener paraderos cercanos a una ubicación
  Future<List<ParadaModel>> getParadasCercanas(
    double lat,
    double lng, {
    double radioKm = 1.0,
  }) async {
    try {
      // Obtener todas las rutas
      final rutas = await getRutas();
      final List<ParadaModel> paradasCercanas = [];

      // Para cada ruta, obtener sus paraderos
      for (var ruta in rutas) {
        final paraderos = await getParaderosRuta(ruta.id);

        // Filtrar paraderos cercanos
        for (var paradero in paraderos) {
          if (paradero.latitud == null || paradero.longitud == null) continue;

          final distancia = Geolocator.distanceBetween(
                lat,
                lng,
                paradero.latitud!,
                paradero.longitud!,
              ) /
              1000;

          if (distancia <= radioKm) {
            paradasCercanas.add(paradero);
          }
        }
      }

      // Ordenar por distancia
      paradasCercanas.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          lat,
          lng,
          a.latitud!,
          a.longitud!,
        );
        final distB = Geolocator.distanceBetween(
          lat,
          lng,
          b.latitud!,
          b.longitud!,
        );
        return distA.compareTo(distB);
      });

      return paradasCercanas;
    } catch (e) {
      print('❌ Error en RutaRepository.getParadasCercanas: $e');
      return [];
    }
  }

  /// Obtener ruta con paradas (método de compatibilidad)
  Future<Map<String, dynamic>?> getRutaConParadas(String rutaId) async {
    try {
      final ruta = await getRutaCompleta(rutaId);
      final paraderos = await getParaderosRuta(rutaId);

      if (ruta == null) return null;

      return {
        'ruta': ruta.toJson(),
        'paraderos': paraderos.map((p) => p.toJson()).toList(),
      };
    } catch (e) {
      print('❌ Error en RutaRepository.getRutaConParadas: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════=
  // 💾 PERSISTENCIA DE PUNTOS (MAPEO MANUAL)
  // ═══════════════════════════════════════════════════════=

  /// Guardar puntos mapeados manualmente para una ruta (ida/vuelta)
  /// Convierte List<LatLng> a la estructura esperada por el API
  Future<bool> guardarPuntosRuta(
    String rutaId,
    String tipo,
    List<LatLng> puntos,
  ) async {
    try {
      final payload = <Map<String, dynamic>>[];

      for (var i = 0; i < puntos.length; i++) {
        final p = puntos[i];
        payload.add({
          'latitud': p.latitude,
          'longitud': p.longitude,
          'orden': i + 1,
        });
      }

      // final success = await _apiService.guardarRutaPuntos(
      //   rutaId: rutaId,
      //   tipo: tipo,
      //   puntos: payload,
      // );

      return true;
    } catch (e) {
      print('❌ Error en RutaRepository.guardarPuntosRuta: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 📊 ESTADÍSTICAS
  // ════════════════════════════════════════════════════════

  /// Obtener rutas más usadas
  Future<List<RutaModel>> getRutasPopulares() async {
    try {
      // Por ahora retornar todas las rutas
      // TODO: Implementar lógica de popularidad basada en uso
      return await getRutas();
    } catch (e) {
      print('❌ Error en RutaRepository.getRutasPopulares: $e');
      return [];
    }
  }
}
