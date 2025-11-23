// lib/data/models/ubicacion_model.dart

class UbicacionModel {
  final int id;
  final int busId;
  final double latitud;
  final double longitud;
  final double? velocidad;
  final int? direccion;
  final DateTime fechaRegistro;

  UbicacionModel({
    required this.id,
    required this.busId,
    required this.latitud,
    required this.longitud,
    this.velocidad,
    this.direccion,
    required this.fechaRegistro,
  });

  factory UbicacionModel.fromJson(Map<String, dynamic> json) {
    return UbicacionModel(
      id: json['id'],
      busId: json['bus_id'],
      latitud: double.parse(json['latitud'].toString()),
      longitud: double.parse(json['longitud'].toString()),
      velocidad: json['velocidad'] != null
          ? double.parse(json['velocidad'].toString())
          : null,
      direccion: json['direccion'],
      fechaRegistro: DateTime.parse(json['fecha_registro']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_id': busId,
      'latitud': latitud,
      'longitud': longitud,
      'velocidad': velocidad,
      'direccion': direccion,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }
}
