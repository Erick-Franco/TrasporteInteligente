// ════════════════════════════════════════════════════════
// 👨‍✈️ MODELO DE CONDUCTOR - TRANSPORTE INTELIGENTE
// lib/data/models/conductor_model.dart
// ════════════════════════════════════════════════════════

class Conductor {
  // Datos principales
  final String id; // UID de Firebase Auth (String, no int)
  final String nombre; // Nombre completo
  final String licencia; // Número de licencia de conducir
  final String? telefono; // Teléfono (opcional)
  final String? email; // Email (opcional)

  // Datos del vehículo asignado
  final String? vehiculoId; // ID del vehículo (String en Firebase)
  final String? placaVehiculo; // Placa del vehículo
  final String? modeloVehiculo; // Modelo del vehículo

  // Datos de la ruta asignada
  final String? rutaId; // ID de la ruta (String en Firebase)
  final String? rutaNombre; // Nombre de la ruta (ej: "Linea 18")
  final String? rutaCodigo; // Código de la ruta (ej: "L18")

  // Viaje actual
  final String? viajeId; // ID del viaje en curso (String en Firebase)
  final String? viajeEstado; // Estado del viaje (en_progreso, completado)

  // Estado
  final bool activo; // Si el conductor está activo
  final DateTime? fechaRegistro; // Fecha de registro
  final DateTime? ultimaActualizacion; // Última actualización

  // ⚠️ CAMPOS LEGACY (para compatibilidad con código viejo)
  String get usuario => nombre; // Alias para compatibilidad
  String get correo => email ?? ''; // Alias para compatibilidad
  String get linea => rutaCodigo ?? rutaNombre ?? ''; // Alias
  bool get estaActivo => activo; // Alias

  Conductor({
    required this.id,
    required this.nombre,
    this.licencia = '', // Opcional con valor por defecto
    this.telefono,
    this.email,
    this.vehiculoId,
    this.placaVehiculo,
    this.modeloVehiculo,
    this.rutaId,
    this.rutaNombre,
    this.rutaCodigo,
    this.viajeId,
    this.viajeEstado,
    this.activo = false,
    this.fechaRegistro,
    this.ultimaActualizacion,
  });

  /// Crear Conductor desde JSON (respuesta del backend o Firebase)
  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id']?.toString() ?? json['conductor_id']?.toString() ?? '',
      nombre: json['nombre'] ?? 'Sin nombre',
      licencia: json['licencia'] ?? '',
      telefono: json['telefono'],
      email: json['email'] ?? json['correo'],
      vehiculoId: json['vehiculo_id']?.toString(),
      placaVehiculo: json['placa'] ?? json['placa_vehiculo'],
      modeloVehiculo: json['modelo'],
      rutaId: json['ruta_id']?.toString(),
      rutaNombre: json['ruta_nombre'],
      rutaCodigo: json['ruta_codigo'] ?? json['linea'],
      viajeId: json['viaje_id']?.toString(),
      viajeEstado: json['viaje_estado'] ?? json['estado'],
      activo: json['activo'] ?? json['esta_activo'] ?? false,
      fechaRegistro:
          _parseDateTime(json['fecha_registro'] ?? json['created_at']),
      ultimaActualizacion:
          _parseDateTime(json['ultima_actualizacion'] ?? json['updated_at']),
    );
  }

  /// Helper para parsear fechas
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'licencia': licencia,
      'telefono': telefono,
      'email': email,
      'vehiculo_id': vehiculoId,
      'placa': placaVehiculo,
      'modelo': modeloVehiculo,
      'ruta_id': rutaId,
      'ruta_nombre': rutaNombre,
      'ruta_codigo': rutaCodigo,
      'viaje_id': viajeId,
      'viaje_estado': viajeEstado,
      'activo': activo,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'ultima_actualizacion': ultimaActualizacion?.toIso8601String(),
    };
  }

  /// ✅ ARREGLADO: copyWith que permite valores null
  Conductor copyWith({
    String? id,
    String? nombre,
    String? licencia,
    String? telefono,
    String? email,
    String? vehiculoId,
    String? placaVehiculo,
    String? modeloVehiculo,
    String? rutaId,
    String? rutaNombre,
    String? rutaCodigo,
    String? viajeId,
    String? viajeEstado,
    bool? activo,
    DateTime? fechaRegistro,
    DateTime? ultimaActualizacion,
    // ✅ NUEVO: Flags para permitir null
    bool clearViajeId = false,
    bool clearViajeEstado = false,
  }) {
    return Conductor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      licencia: licencia ?? this.licencia,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      placaVehiculo: placaVehiculo ?? this.placaVehiculo,
      modeloVehiculo: modeloVehiculo ?? this.modeloVehiculo,
      rutaId: rutaId ?? this.rutaId,
      rutaNombre: rutaNombre ?? this.rutaNombre,
      rutaCodigo: rutaCodigo ?? this.rutaCodigo,
      // ✅ ARREGLO: Permitir limpiar viajeId y viajeEstado
      viajeId: clearViajeId ? null : (viajeId ?? this.viajeId),
      viajeEstado: clearViajeEstado ? null : (viajeEstado ?? this.viajeEstado),
      activo: activo ?? this.activo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }

  // ════════════════════════════════════════════════════════
  // 🔧 MÉTODOS ÚTILES
  // ════════════════════════════════════════════════════════

  /// Verificar si tiene un viaje activo
  bool get tieneViajeActivo => viajeId != null && viajeEstado == 'en_progreso';

  /// Verificar si tiene vehículo asignado
  bool get tieneVehiculo => vehiculoId != null && placaVehiculo != null;

  /// Verificar si tiene ruta asignada
  bool get tieneRuta => rutaId != null;

  /// Obtener nombre completo de la ruta
  String get rutaCompleta {
    if (rutaCodigo != null && rutaNombre != null) {
      return '$rutaCodigo - $rutaNombre';
    }
    return rutaNombre ?? rutaCodigo ?? 'Sin ruta';
  }

  /// Obtener información del vehículo
  String get vehiculoInfo {
    if (placaVehiculo != null && modeloVehiculo != null) {
      return '$placaVehiculo ($modeloVehiculo)';
    }
    return placaVehiculo ?? 'Sin vehículo';
  }

  /// Verificar si está todo configurado para conducir
  bool get puedeConducir => activo && tieneVehiculo && tieneRuta;

  @override
  String toString() {
    return 'Conductor(id: $id, nombre: $nombre, licencia: $licencia, '
        'ruta: $rutaCompleta, vehiculo: $placaVehiculo, activo: $activo, '
        'viajeId: $viajeId, viajeEstado: $viajeEstado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conductor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
