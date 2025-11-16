// ════════════════════════════════════════════════════════
// 💬 MODELO DE MENSAJE - TRANSPORTE INTELIGENTE
// lib/data/models/mensaje_model.dart
// ════════════════════════════════════════════════════════

class MensajeModel {
  final int? id; // ID del mensaje en DB
  final String usuarioNombre; // Nombre del usuario
  final String usuarioId; // ID del usuario
  final String mensaje; // Contenido del mensaje
  final int? paradaId; // ID de parada (opcional)
  final int? rutaId; // ID de ruta (opcional)
  final String tipo; // Tipo: 'general', 'parada', 'ruta'
  final DateTime fechaEnvio; // Fecha y hora del mensaje

  // ⚠️ GETTER LEGACY (para compatibilidad con código viejo)
  String get username => usuarioNombre; // Alias para compatibilidad

  MensajeModel({
    this.id,
    required this.usuarioNombre,
    required this.usuarioId,
    required this.mensaje,
    this.paradaId,
    this.rutaId,
    this.tipo = 'general',
    DateTime? fechaEnvio,
  }) : fechaEnvio = fechaEnvio ?? DateTime.now();

  /// Crear MensajeModel desde JSON (respuesta del backend)
  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: _parseInt(json['id']),
      usuarioNombre: json['usuario_nombre'] ?? json['username'] ?? 'Anónimo',
      usuarioId: json['usuario_id']?.toString() ??
          json['user_id']?.toString() ??
          'unknown',
      mensaje: json['mensaje'] ?? '',
      paradaId: _parseInt(json['parada_id']),
      rutaId: _parseInt(json['ruta_id']),
      tipo: json['tipo'] ?? 'general',
      fechaEnvio: _parseDateTime(json['fecha_envio'] ?? json['timestamp']) ??
          DateTime.now(),
    );
  }

  /// Helper para parsear enteros
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper para parsear fechas
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('❌ Error parseando fecha: $value');
        return null;
      }
    }
    return null;
  }

  /// Convertir a JSON (para enviar al backend)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'usuario_nombre': usuarioNombre,
      'usuario_id': usuarioId,
      'mensaje': mensaje,
      if (paradaId != null) 'parada_id': paradaId,
      if (rutaId != null) 'ruta_id': rutaId,
      'tipo': tipo,
      'timestamp': fechaEnvio.toIso8601String(),
    };
  }

  /// Crear copia con campos modificados
  MensajeModel copyWith({
    int? id,
    String? usuarioNombre,
    String? usuarioId,
    String? mensaje,
    int? paradaId,
    int? rutaId,
    String? tipo,
    DateTime? fechaEnvio,
  }) {
    return MensajeModel(
      id: id ?? this.id,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      usuarioId: usuarioId ?? this.usuarioId,
      mensaje: mensaje ?? this.mensaje,
      paradaId: paradaId ?? this.paradaId,
      rutaId: rutaId ?? this.rutaId,
      tipo: tipo ?? this.tipo,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
    );
  }

  // ════════════════════════════════════════════════════════
  // 🔧 MÉTODOS ÚTILES
  // ════════════════════════════════════════════════════════

  /// Verificar si el mensaje es reciente (menos de 1 minuto)
  bool get esReciente {
    final diferencia = DateTime.now().difference(fechaEnvio);
    return diferencia.inMinutes < 1;
  }

  /// Obtener tiempo desde el envío en formato legible
  String get tiempoDesdeEnvio {
    final diferencia = DateTime.now().difference(fechaEnvio);

    if (diferencia.inSeconds < 60) {
      return 'Hace ${diferencia.inSeconds}s';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes}m';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours}h';
    } else {
      return 'Hace ${diferencia.inDays}d';
    }
  }

  /// Obtener hora en formato HH:mm
  String get horaFormateada {
    return '${fechaEnvio.hour.toString().padLeft(2, '0')}:'
        '${fechaEnvio.minute.toString().padLeft(2, '0')}';
  }

  /// Verificar si es un mensaje del sistema
  bool get esMensajeSistema =>
      usuarioId == 'system' || usuarioNombre.toLowerCase() == 'sistema';

  /// Verificar si tiene contexto de parada
  bool get tieneParada => paradaId != null;

  /// Verificar si tiene contexto de ruta
  bool get tieneRuta => rutaId != null;

  @override
  String toString() {
    return 'MensajeModel(id: $id, usuario: $usuarioNombre, mensaje: $mensaje, '
        'tipo: $tipo, fecha: ${horaFormateada})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MensajeModel &&
        other.id == id &&
        other.fechaEnvio == fechaEnvio;
  }

  @override
  int get hashCode => id.hashCode ^ fechaEnvio.hashCode;
}
