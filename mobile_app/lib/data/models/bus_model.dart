// ════════════════════════════════════════════════════════
// 🚌 MODELO DE BUS - TRANSPORTE INTELIGENTE
// lib/data/models/bus_model.dart
// ════════════════════════════════════════════════════════

class BusModel {
  // IDs principales (String para Firebase)
  final String? conductorId; // ID del conductor (Firebase UID)
  final String? vehiculoId; // ID del vehículo
  final String? viajeId; // ID del viaje actual

  // Información del vehículo
  final String? placa; // Placa del vehículo
  final String? modelo; // Modelo del vehículo

  // Información de la ruta
  final String? rutaId; // ID de la ruta (String en Firebase)
  final String? rutaNombre; // Nombre de la ruta (ej: "Linea 18")
  final String? rutaCodigo; // Código de la ruta (ej: "L18")
  final String? rutaColor; // Color de la ruta (hex)

  // Información del conductor
  final String? conductorNombre; // Nombre del conductor

  // Ubicación GPS
  final double? latitud; // Latitud actual
  final double? longitud; // Longitud actual
  final double? velocidad; // Velocidad en km/h
  final double? direccion; // Dirección en grados (0-360)

  // Estado y sentido
  final String? estado; // Estado del viaje (en_progreso, completado, etc)
  final String sentido; // Sentido del recorrido ('ida' o 'vuelta')

  // Timestamps
  final DateTime? ultimaActualizacion; // Última actualización GPS

  BusModel({
    this.conductorId,
    this.vehiculoId,
    this.viajeId,
    this.placa,
    this.modelo,
    this.rutaId,
    this.rutaNombre,
    this.rutaCodigo,
    this.rutaColor,
    this.conductorNombre,
    this.latitud,
    this.longitud,
    this.velocidad,
    this.direccion,
    this.estado,
    this.sentido = 'ida',
    this.ultimaActualizacion,
  });

  /// Crear BusModel desde JSON (Firebase o backend)
  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      conductorId: json['conductor_id']?.toString(),
      vehiculoId: json['vehiculo_id']?.toString(),
      viajeId: json['viaje_id']?.toString(),
      placa: json['placa'],
      modelo: json['modelo'],
      rutaId: json['ruta_id']?.toString(),
      rutaNombre: json['ruta_nombre'],
      rutaCodigo: json['ruta_codigo'],
      rutaColor: json['ruta_color'],
      conductorNombre: json['conductor_nombre'],
      latitud: _parseDouble(json['latitud']),
      longitud: _parseDouble(json['longitud']),
      velocidad: _parseDouble(json['velocidad']),
      direccion: _parseDouble(json['direccion']),
      estado: json['estado'],
      sentido: json['sentido'] ?? 'ida',
      ultimaActualizacion: json['ultima_actualizacion'] != null
          ? DateTime.parse(json['ultima_actualizacion'])
          : null,
    );
  }

  /// Helper para parsear números que pueden venir como string o null
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Convertir a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'conductor_id': conductorId,
      'vehiculo_id': vehiculoId,
      'viaje_id': viajeId,
      'placa': placa,
      'modelo': modelo,
      'ruta_id': rutaId,
      'ruta_nombre': rutaNombre,
      'ruta_codigo': rutaCodigo,
      'ruta_color': rutaColor,
      'conductor_nombre': conductorNombre,
      'latitud': latitud,
      'longitud': longitud,
      'velocidad': velocidad,
      'direccion': direccion,
      'estado': estado,
      'sentido': sentido,
      'ultima_actualizacion': ultimaActualizacion?.toIso8601String(),
    };
  }

  /// Crear copia con campos modificados
  BusModel copyWith({
    String? conductorId,
    String? vehiculoId,
    String? viajeId,
    String? placa,
    String? modelo,
    String? rutaId,
    String? rutaNombre,
    String? rutaCodigo,
    String? rutaColor,
    String? conductorNombre,
    double? latitud,
    double? longitud,
    double? velocidad,
    double? direccion,
    String? estado,
    String? sentido,
    DateTime? ultimaActualizacion,
  }) {
    return BusModel(
      conductorId: conductorId ?? this.conductorId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      viajeId: viajeId ?? this.viajeId,
      placa: placa ?? this.placa,
      modelo: modelo ?? this.modelo,
      rutaId: rutaId ?? this.rutaId,
      rutaNombre: rutaNombre ?? this.rutaNombre,
      rutaCodigo: rutaCodigo ?? this.rutaCodigo,
      rutaColor: rutaColor ?? this.rutaColor,
      conductorNombre: conductorNombre ?? this.conductorNombre,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      velocidad: velocidad ?? this.velocidad,
      direccion: direccion ?? this.direccion,
      estado: estado ?? this.estado,
      sentido: sentido ?? this.sentido,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }

  // ════════════════════════════════════════════════════════
  // 🔧 MÉTODOS ÚTILES
  // ════════════════════════════════════════════════════════

  /// Verificar si el bus está en movimiento
  bool get enMovimiento => (velocidad ?? 0) > 0;

  /// Verificar si tiene ubicación GPS válida
  bool get tieneUbicacion => latitud != null && longitud != null;

  /// Obtener texto del estado
  String get estadoTexto {
    switch (estado) {
      case 'en_progreso':
        return 'En ruta';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  /// Obtener tiempo desde última actualización
  String get tiempoDesdeActualizacion {
    if (ultimaActualizacion == null) return 'Sin datos';

    final diferencia = DateTime.now().difference(ultimaActualizacion!);

    if (diferencia.inSeconds < 60) {
      return 'Hace ${diferencia.inSeconds} seg';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else {
      return 'Hace ${diferencia.inHours} hrs';
    }
  }

  /// Verificar si los datos están actualizados (menos de 30 segundos)
  bool get datosActualizados {
    if (ultimaActualizacion == null) return false;
    return DateTime.now().difference(ultimaActualizacion!).inSeconds < 30;
  }

  @override
  String toString() {
    return 'BusModel(conductorId: $conductorId, placa: $placa, ruta: $rutaNombre, '
        'lat: $latitud, lng: $longitud, velocidad: $velocidad)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusModel && other.conductorId == conductorId;
  }

  @override
  int get hashCode => conductorId.hashCode;
}
