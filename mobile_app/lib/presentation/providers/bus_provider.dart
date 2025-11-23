// ════════════════════════════════════════════════════════
// 🚌 PROVIDER DE BUSES - TRANSPORTE INTELIGENTE
// lib/presentation/providers/bus_provider.dart
// ════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../data/models/bus_model.dart';
import '../../services/firebase_service.dart';

class BusProvider with ChangeNotifier {
  // Ya no usamos ApiService ni SocketService, usamos FirebaseService
  // final ApiService _apiService = ApiService();
  // final SocketService _socketService = SocketService();

  List<BusModel> _buses = [];
  List<BusModel> _busesFiltrados = [];
  bool _cargando = false;
  String? _error;
  String? _rutaSeleccionada; // String ID
  StreamSubscription<DatabaseEvent>? _ubicacionesSubscription;

  // Getters
  List<BusModel> get buses =>
      _busesFiltrados.isEmpty ? _buses : _busesFiltrados;
  List<BusModel> get todosBuses => _buses;
  bool get cargando => _cargando;
  String? get error => _error;
  String? get rutaSeleccionada => _rutaSeleccionada;
  bool get webSocketConectado => _ubicacionesSubscription != null;
  int get totalBuses => _buses.length;

  // ════════════════════════════════════════════════════════
  // 🔌 CONEXIÓN TIEMPO REAL (FIREBASE RTDB)
  // ════════════════════════════════════════════════════════

  /// Conectar a Firebase RTDB para recibir actualizaciones en tiempo real
  Future<void> conectarWebSocket() async {
    if (_ubicacionesSubscription != null) {
      print('✅ Listener de ubicaciones ya activo');
      return;
    }

    try {
      print('🔌 Conectando a Firebase RTDB para ubicaciones...');

      // Escuchar cambios en la referencia de ubicaciones
      _ubicacionesSubscription =
          FirebaseService.listenTodasUbicaciones().listen((event) {
        if (event.snapshot.value != null) {
          _procesarActualizacionUbicaciones(event.snapshot.value);
        } else {
          // Si es null, no hay buses activos
          _buses = [];
          _aplicarFiltroRuta();
          notifyListeners();
        }
      }, onError: (e) {
        print('❌ Error en stream de ubicaciones: $e');
        _error = 'Error de conexión: $e';
        notifyListeners();
      });

      print('✅ Escuchando ubicaciones en tiempo real');
    } catch (e) {
      _error = 'Error al conectar RTDB: $e';
      notifyListeners();
      print('❌ Error RTDB: $e');
    }
  }

  /// Procesar datos crudos de RTDB
  void _procesarActualizacionUbicaciones(dynamic data) {
    try {
      if (data is Map) {
        final List<BusModel> nuevosBuses = [];

        data.forEach((key, value) {
          // key es el conductorId (String)
          if (value is Map) {
            // Intentar parsear los valores de manera segura
            final lat = double.tryParse(value['latitud'].toString()) ?? 0.0;
            final lng = double.tryParse(value['longitud'].toString()) ?? 0.0;
            final vel = double.tryParse(value['velocidad'].toString()) ?? 0.0;
            final dir = double.tryParse(value['direccion'].toString()) ?? 0.0;
            final viajeId = value['viaje_id']?.toString();
            final rutaId = value['ruta_id']?.toString();

            final bus = BusModel(
              conductorId: key.toString(),
              latitud: lat,
              longitud: lng,
              velocidad: vel,
              direccion: dir,
              viajeId: viajeId,
              rutaId: rutaId,
              // Datos que faltan en RTDB pero podríamos obtener de otro lado si fuera necesario
              // Por ahora usamos placeholders o lo que haya
              placa:
                  'Bus ${key.toString().substring(0, min(5, key.toString().length))}',
              modelo: 'Desconocido',
              rutaNombre: 'Ruta $rutaId',
              rutaCodigo: 'R$rutaId',
              conductorNombre: 'Conductor',
              estado: 'en_progreso',
              sentido: 'ida', // Asumimos ida por defecto si no está
              ultimaActualizacion: DateTime.now(),
            );
            nuevosBuses.add(bus);
          }
        });

        _buses = nuevosBuses;
        _aplicarFiltroRuta();
        notifyListeners();

        if (kDebugMode) {
          // print('📍 Actualizados ${_buses.length} buses desde RTDB');
        }
      }
    } catch (e) {
      print('❌ Error procesando datos RTDB: $e');
    }
  }

  int min(int a, int b) => a < b ? a : b;

  /// Reconectar (simulado, solo reinicia el listener)
  Future<void> reconectarWebSocket() async {
    print('🔄 Reiniciando listener de ubicaciones...');
    await _ubicacionesSubscription?.cancel();
    _ubicacionesSubscription = null;
    await conectarWebSocket();
  }

  // ════════════════════════════════════════════════════════
  // 📡 CARGAR BUSES (MÉTODOS DE COMPATIBILIDAD)
  // ════════════════════════════════════════════════════════

  /// Cargar todos los buses activos (ahora inicia el listener)
  Future<void> cargarBusesActivos() async {
    await conectarWebSocket();
  }

  /// Cargar buses de una ruta específica
  Future<void> cargarBusesPorRuta(String rutaId) async {
    _rutaSeleccionada = rutaId;
    await conectarWebSocket();
    _aplicarFiltroRuta();
  }

  /// Obtener bus por ID (Conductor ID en este caso)
  Future<BusModel?> obtenerBusPorId(String conductorId) async {
    try {
      return _buses.firstWhere((b) => b.conductorId == conductorId);
    } catch (e) {
      return null;
    }
  }

  /// Actualizar ubicación de un bus (usado por conductor)
  Future<bool> actualizarUbicacionBus({
    required String busId, // En realidad es conductorId ahora
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
  }) async {
    // Este método es legacy, mejor usar enviarUbicacionConductor
    return false;
  }

  /// Enviar ubicación GPS del conductor (modo conductor)
  Future<bool> enviarUbicacionConductor({
    required String conductorId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
    required String sentido,
  }) async {
    try {
      // Obtener datos del viaje actual del conductor desde Firestore
      final viaje = await FirebaseService.getViajeActual(conductorId);

      if (viaje == null) {
        // print('❌ No hay viaje activo para conductor $conductorId');
        return false;
      }

      final vehiculoId = viaje['vehiculo_id'];
      final rutaId = viaje['ruta_id'];
      final viajeId = viaje['id'];

      if (vehiculoId == null || rutaId == null) {
        print('❌ Datos de viaje incompletos');
        return false;
      }

      // Enviar ubicación a RTDB
      await FirebaseService.setUbicacionConductor(
        conductorId: conductorId,
        latitud: latitud,
        longitud: longitud,
        velocidad: velocidad,
        direccion: direccion,
        viajeId: viajeId,
        rutaId: rutaId,
      );

      return true;
    } catch (e) {
      print('❌ Error enviando ubicación conductor: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔍 FILTROS Y BÚSQUEDA
  // ════════════════════════════════════════════════════════

  /// Filtrar buses por ruta
  void filtrarPorRuta(String? rutaId) {
    _rutaSeleccionada = rutaId;
    if (rutaId == null) {
      _busesFiltrados = []; // O mostrar todos?
      // Si rutaId es null, mostramos todos en _busesFiltrados?
      // El comportamiento original era vaciar si era null? Revisando código anterior:
      // if (rutaId == null) _busesFiltrados = [];
      // Mantendré ese comportamiento.
    } else {
      _aplicarFiltroRuta();
    }
    notifyListeners();
  }

  void _aplicarFiltroRuta() {
    if (_rutaSeleccionada != null) {
      _busesFiltrados =
          _buses.where((bus) => bus.rutaId == _rutaSeleccionada).toList();
    } else {
      _busesFiltrados = _buses;
    }
  }

  /// Limpiar filtros
  void limpiarFiltros() {
    _rutaSeleccionada = null;
    _busesFiltrados = [];
    notifyListeners();
  }

  /// Buscar buses cercanos a una ubicación
  List<BusModel> buscarBusesCercanos({
    required double latitud,
    required double longitud,
    double radioKm = 5.0,
  }) {
    return _buses.where((bus) {
      if (bus.latitud == null || bus.longitud == null) return false;

      final distancia = _calcularDistancia(
        latitud,
        longitud,
        bus.latitud!,
        bus.longitud!,
      );

      return distancia <= radioKm;
    }).toList();
  }

  /// Calcular distancia entre dos puntos usando Geolocator
  double _calcularDistancia(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // ════════════════════════════════════════════════════════
  // 🎯 SUSCRIPCIONES A RUTAS
  // ════════════════════════════════════════════════════════

  /// Suscribirse a actualizaciones de una ruta específica
  void suscribirseARuta(String rutaId) {
    // En RTDB escuchamos todo, el filtro se hace en cliente
    _rutaSeleccionada = rutaId;
    _aplicarFiltroRuta();
    print('📍 Suscrito a actualizaciones de ruta $rutaId (filtro local)');
  }

  /// Desuscribirse de una ruta
  void desuscribirseDeRuta(String rutaId) {
    if (_rutaSeleccionada == rutaId) {
      _rutaSeleccionada = null;
      _aplicarFiltroRuta();
    }
    print('🔌 Desuscrito de ruta $rutaId');
  }

  // ════════════════════════════════════════════════════════
  // 🔧 UTILIDADES
  // ════════════════════════════════════════════════════════

  /// Limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  /// Refrescar buses
  Future<void> refrescar() async {
    // Solo reconectar
    await reconectarWebSocket();
  }

  /// Obtener buses por estado
  Map<String, List<BusModel>> get busesPorEstado {
    return {
      'en_movimiento': _buses.where((b) => (b.velocidad ?? 0) > 0).toList(),
      'detenidos': _buses.where((b) => (b.velocidad ?? 0) == 0).toList(),
    };
  }

  /// Obtener cantidad de buses por ruta
  Map<String, int> get busesPorRuta {
    final Map<String, int> conteo = {};
    for (var bus in _buses) {
      if (bus.rutaId != null) {
        conteo[bus.rutaId!] = (conteo[bus.rutaId!] ?? 0) + 1;
      }
    }
    return conteo;
  }

  @override
  void dispose() {
    print('🛑 Cancelando suscripción de buses...');
    _ubicacionesSubscription?.cancel();
    super.dispose();
  }
}
