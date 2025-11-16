// lib/data/models/ruta_model.dart

import 'package:latlong2/latlong.dart';

class RutaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? color;
  final double? tarifa;
  final bool activo;

  // 🆕 NUEVO: Coordenadas de IDA y VUELTA
  final List<LatLng> coordinadasIda;
  final List<LatLng> coordinadasVuelta;

  RutaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.color,
    this.tarifa,
    this.activo = true,
    this.coordinadasIda = const [],
    this.coordinadasVuelta = const [],
  });

  factory RutaModel.fromJson(Map<String, dynamic> json) {
    return RutaModel(
      id: json['id'] ?? json['ruta_id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      color: json['color'],
      tarifa: json['tarifa'] != null
          ? double.parse(json['tarifa'].toString())
          : null,
      activo: json['activo'] ?? true,
      coordinadasIda: _parseCoordinates(json['coordenadas_ida']),
      coordinadasVuelta: _parseCoordinates(json['coordenadas_vuelta']),
    );
  }

  // Helper para parsear coordenadas desde JSON
  static List<LatLng> _parseCoordinates(dynamic coords) {
    if (coords == null) return [];

    if (coords is List) {
      return coords.map((coord) {
        if (coord is Map<String, dynamic>) {
          final lat = double.parse(coord['latitud'].toString());
          final lng = double.parse(coord['longitud'].toString());
          return LatLng(lat, lng);
        }
        return LatLng(0, 0);
      }).toList();
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'tarifa': tarifa,
      'activo': activo,
      'coordenadas_ida': coordinadasIda
          .map((c) => {'latitud': c.latitude, 'longitud': c.longitude})
          .toList(),
      'coordenadas_vuelta': coordinadasVuelta
          .map((c) => {'latitud': c.latitude, 'longitud': c.longitude})
          .toList(),
    };
  }

  // 🆕 Método para crear ruta con coordenadas
  RutaModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? color,
    double? tarifa,
    bool? activo,
    List<LatLng>? coordinadasIda,
    List<LatLng>? coordinadasVuelta,
  }) {
    return RutaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      color: color ?? this.color,
      tarifa: tarifa ?? this.tarifa,
      activo: activo ?? this.activo,
      coordinadasIda: coordinadasIda ?? this.coordinadasIda,
      coordinadasVuelta: coordinadasVuelta ?? this.coordinadasVuelta,
    );
  }
}
