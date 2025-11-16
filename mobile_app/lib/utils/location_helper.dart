// lib/utils/location_helper.dart

import 'dart:math';

class LocationHelper {
  // Calcular distancia entre dos puntos usando la fórmula de Haversine (en metros)
  static double calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Radio de la Tierra en metros

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distancia en metros
  }

  // Calcular bearing (dirección) entre dos puntos (en grados)
  static double calcularBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);

    final y = sin(dLon) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);

    final bearing = atan2(y, x);

    return (_toDegrees(bearing) + 360) % 360; // Normalizar a 0-360
  }

  // Formatear distancia de manera legible
  static String formatearDistancia(double distanciaMetros) {
    if (distanciaMetros < 1000) {
      return '${distanciaMetros.round()} m';
    } else {
      final km = distanciaMetros / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  // Formatear coordenadas de manera legible
  static String formatearCoordenadas(double latitud, double longitud) {
    final latStr = latitud.toStringAsFixed(6);
    final lonStr = longitud.toStringAsFixed(6);
    return '$latStr, $lonStr';
  }

  // Calcular tiempo estimado de llegada (en minutos)
  static int calcularTiempoLlegada(
    double distanciaMetros,
    double velocidadKmH,
  ) {
    if (velocidadKmH <= 0) velocidadKmH = 25; // Velocidad por defecto

    final distanciaKm = distanciaMetros / 1000;
    final tiempoHoras = distanciaKm / velocidadKmH;
    final tiempoMinutos = (tiempoHoras * 60).round();

    return tiempoMinutos;
  }

  // Verificar si un punto está dentro de un radio
  static bool estaDentroDelRadio(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radioMetros,
  ) {
    final distancia = calcularDistancia(lat1, lon1, lat2, lon2);
    return distancia <= radioMetros;
  }

  // Convertir grados a radianes
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Convertir radianes a grados
  static double _toDegrees(double radians) {
    return radians * 180 / pi;
  }

  // Obtener dirección cardinal (N, S, E, O, NE, etc.)
  static String obtenerDireccionCardinal(double bearing) {
    const direcciones = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSO',
      'SO',
      'OSO',
      'O',
      'ONO',
      'NO',
      'NNO'
    ];

    final index = ((bearing + 11.25) / 22.5).floor() % 16;
    return direcciones[index];
  }

  // Interpolar entre dos puntos (útil para animaciones)
  static Map<String, double> interpolar(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double progreso, // 0.0 a 1.0
  ) {
    return {
      'lat': lat1 + (lat2 - lat1) * progreso,
      'lon': lon1 + (lon2 - lon1) * progreso,
    };
  }
}
