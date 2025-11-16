// ════════════════════════════════════════════════════════
// 🚏 MODELO DE PARADA/PARADERO - TRANSPORTE INTELIGENTE
// lib/data/models/parada_model.dart
// ════════════════════════════════════════════════════════

class ParadaModel {
  final int id;
  final String nombre;
  final double? latitud; // ✅ Nullable para manejar datos incompletos
  final double? longitud; // ✅ Nullable para manejar datos incompletos
  final String? direccion;
  final bool esPrincipal;
  final int? rutaId; // ✅ ID de la ruta a la que pertenece
  final int? orden; // ✅ Orden en la ruta

  ParadaModel({
    required this.id,
    required this.nombre,
    this.latitud,
    this.longitud,
    this.direccion,
    this.esPrincipal = false,
    this.rutaId,
    this.orden,
  });

  /// Crear desde JSON (respuesta del backend)
  factory ParadaModel.fromJson(Map<String, dynamic> json) {
    return ParadaModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Parada sin nombre',
      latitud: _parseDouble(json['latitud']),
      longitud: _parseDouble(json['longitud']),
      direccion: json['direccion'],
      esPrincipal: json['es_parada_principal'] ?? json['es_principal'] ?? false,
      rutaId: json['ruta_id'],
      orden: json['orden'],
    );
  }

  /// Helper para parsear números que pueden venir como string
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'es_parada_principal': esPrincipal,
      'ruta_id': rutaId,
      'orden': orden,
    };
  }

  /// Crear copia con campos modificados
  ParadaModel copyWith({
    int? id,
    String? nombre,
    double? latitud,
    double? longitud,
    String? direccion,
    bool? esPrincipal,
    int? rutaId,
    int? orden,
  }) {
    return ParadaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccion: direccion ?? this.direccion,
      esPrincipal: esPrincipal ?? this.esPrincipal,
      rutaId: rutaId ?? this.rutaId,
      orden: orden ?? this.orden,
    );
  }

  // ════════════════════════════════════════════════════════
  // 🔧 MÉTODOS ÚTILES
  // ════════════════════════════════════════════════════════

  /// Verificar si tiene coordenadas válidas
  bool get tieneUbicacion => latitud != null && longitud != null;

  /// Obtener descripción completa
  String get descripcionCompleta {
    if (direccion != null && direccion!.isNotEmpty) {
      return '$nombre - $direccion';
    }
    return nombre;
  }

  @override
  String toString() {
    return 'ParadaModel(id: $id, nombre: $nombre, lat: $latitud, lng: $longitud)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParadaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
