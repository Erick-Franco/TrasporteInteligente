// lib/utils/map_utils.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapUtils {
  // Calcular el centro de un conjunto de coordenadas
  static LatLng calcularCentro(List<LatLng> coordenadas) {
    if (coordenadas.isEmpty) {
      return LatLng(-15.8402, -70.0219); // Default: Puno
    }

    double sumLat = 0;
    double sumLng = 0;

    for (var coord in coordenadas) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }

    return LatLng(
      sumLat / coordenadas.length,
      sumLng / coordenadas.length,
    );
  }

  // Calcular el zoom apropiado para mostrar todos los puntos
  static double calcularZoomParaBounds(
    List<LatLng> coordenadas,
    double anchoMapa,
  ) {
    if (coordenadas.isEmpty) return 15.0;

    double minLat = coordenadas[0].latitude;
    double maxLat = coordenadas[0].latitude;
    double minLng = coordenadas[0].longitude;
    double maxLng = coordenadas[0].longitude;

    for (var coord in coordenadas) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff < 0.01) return 16.0;
    if (maxDiff < 0.05) return 14.0;
    if (maxDiff < 0.1) return 13.0;
    if (maxDiff < 0.5) return 11.0;
    return 10.0;
  }

  // Obtener color según velocidad
  static Color obtenerColorPorVelocidad(double? velocidad) {
    if (velocidad == null || velocidad == 0) {
      return Colors.grey; // Detenido
    } else if (velocidad < 15) {
      return Colors.orange; // Lento
    } else if (velocidad < 30) {
      return Colors.green; // Normal
    } else {
      return Colors.blue; // Rápido
    }
  }

  // Obtener icono según estado del bus
  static IconData obtenerIconoPorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'activo':
        return Icons.directions_bus;
      case 'mantenimiento':
        return Icons.build;
      case 'fuera_de_servicio':
        return Icons.block;
      default:
        return Icons.directions_bus;
    }
  }

  // Formatear coordenadas para mostrar
  static String formatearCoordenadas(double lat, double lng) {
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  // Crear bounds desde una lista de coordenadas
  static Map<String, double> crearBounds(List<LatLng> coordenadas) {
    if (coordenadas.isEmpty) {
      return {
        'minLat': -15.9,
        'maxLat': -15.7,
        'minLng': -70.2,
        'maxLng': -69.9,
      };
    }

    double minLat = coordenadas[0].latitude;
    double maxLat = coordenadas[0].latitude;
    double minLng = coordenadas[0].longitude;
    double maxLng = coordenadas[0].longitude;

    for (var coord in coordenadas) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  // Validar si una coordenada es válida
  static bool coordenadaValida(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  // Obtener URL de tile de OpenStreetMap
  static String obtenerTileUrl() {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  // Obtener URL de tile de OpenStreetMap con tema oscuro
  static String obtenerTileUrlOscuro() {
    return 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png';
  }
}
