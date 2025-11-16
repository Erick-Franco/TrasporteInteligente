// ════════════════════════════════════════════════════════
// 🚌 PROVIDER DE BUSES - TRANSPORTE INTELIGENTE
// lib/presentation/providers/bus_provider.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart'; // ✅ Para cálculo de distancias
import '../../data/models/bus_model.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

class BusProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  List<BusModel> _buses = [];
  List<BusModel> _busesFiltrados = [];
  bool _cargando = false;
  String? _error;
  int? _rutaSeleccionada;

  // Getters
  List<BusModel> get buses =>
      _busesFiltrados.isEmpty ? _buses : _busesFiltrados;
  List<BusModel> get todosBuses => _buses;
  bool get cargando => _cargando;
  String? get error => _error;
  int? get rutaSeleccionada => _rutaSeleccionada;
  bool get webSocketConectado => _socketService.conectado;
  int get totalBuses => _buses.length;

  // ════════════════════════════════════════════════════════
  // 🔌 CONEXIÓN WEBSOCKET
  // ════════════════════════════════════════════════════════

  /// Conectar al WebSocket para recibir actualizaciones en tiempo real
  Future<void> conectarWebSocket() async {
    if (_socketService.conectado) {
      print('✅ WebSocket ya conectado');
      return;
    }

    try {
      await _socketService.conectar();

      // Esperar a que la conexión se establezca
      await Future.delayed(const Duration(seconds: 1));

      // ════════════════════════════════════════════════════════
      // 📍 EVENTOS DE UBICACIÓN GPS
      // ════════════════════════════════════════════════════════

      // Actualización de ubicación de un bus
      _socketService.on('bus-location-update', (data) {
        _actualizarUbicacionBus(data);
      });

      // Bus llegó a un paradero
      _socketService.on('bus-arrived-stop', (data) {
        print(
            '🛑 Bus ${data['conductor_id']} llegó a paradero ${data['punto_control_id']}');
        // Aquí puedes agregar lógica adicional si necesitas
      });

      // Bus completó ruta
      _socketService.on('bus-route-completed', (data) {
        print('✅ Bus completó ruta: ${data['viaje_id']}');
        _removerBusCompletado(data['viaje_id']);
      });

      print('🔌 WebSocket conectado y escuchando eventos de buses');
    } catch (e) {
      _error = 'Error al conectar WebSocket: $e';
      notifyListeners();
      print('❌ Error WebSocket: $e');
    }
  }

  /// Actualizar ubicación de un bus en tiempo real
  void _actualizarUbicacionBus(dynamic data) {
    try {
      final conductorId = data['conductor_id'];
      final latitud = data['latitud'];
      final longitud = data['longitud'];
      final velocidad = data['velocidad'];
      final direccion = data['direccion'];

      // Buscar el bus por conductor_id
      final index = _buses.indexWhere((b) => b.conductorId == conductorId);

      if (index != -1) {
        // Actualizar ubicación del bus existente
        _buses[index] = _buses[index].copyWith(
          latitud: latitud,
          longitud: longitud,
          velocidad: velocidad,
          direccion: direccion,
          ultimaActualizacion: DateTime.now(),
        );

        // Si hay filtro activo, actualizar también la lista filtrada
        if (_rutaSeleccionada != null) {
          _aplicarFiltroRuta();
        }

        notifyListeners();

        if (kDebugMode) {
          print('📍 Bus actualizado: Conductor #$conductorId');
        }
      }
    } catch (e) {
      print('❌ Error al actualizar ubicación bus: $e');
    }
  }

  /// Remover bus que completó su ruta
  void _removerBusCompletado(int viajeId) {
    final index = _buses.indexWhere((b) => b.viajeId == viajeId);
    if (index != -1) {
      _buses.removeAt(index);
      if (_rutaSeleccionada != null) {
        _aplicarFiltroRuta();
      }
      notifyListeners();
    }
  }

  /// Reconectar WebSocket manualmente
  Future<void> reconectarWebSocket() async {
    print('🔄 Intentando reconectar WebSocket...');
    _socketService.desconectar();
    await Future.delayed(const Duration(seconds: 1));
    await conectarWebSocket();
  }

  // ════════════════════════════════════════════════════════
  // 📡 CARGAR BUSES DESDE API
  // ════════════════════════════════════════════════════════

  /// Cargar todos los buses activos
  Future<void> cargarBusesActivos() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final busesData = await _apiService.getBusesActivos();
      _buses = busesData.map((json) => BusModel.fromJson(json)).toList();

      // Aplicar filtro si hay uno activo
      if (_rutaSeleccionada != null) {
        _aplicarFiltroRuta();
      }

      _cargando = false;
      notifyListeners();
      print('✅ Buses activos cargados: ${_buses.length}');
    } catch (e) {
      _error = 'Error al cargar buses activos: $e';
      _cargando = false;
      notifyListeners();
      print('❌ Error al cargar buses: $e');
    }
  }

  /// Cargar buses de una ruta específica
  Future<void> cargarBusesPorRuta(int rutaId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final busesData = await _apiService.getBusesPorRuta(rutaId);
      _buses = busesData.map((json) => BusModel.fromJson(json)).toList();
      _rutaSeleccionada = rutaId;
      _busesFiltrados = _buses;

      _cargando = false;
      notifyListeners();
      print('✅ Buses de ruta $rutaId cargados: ${_buses.length}');
    } catch (e) {
      _error = 'Error al cargar buses de ruta $rutaId: $e';
      _cargando = false;
      notifyListeners();
      print('❌ Error al cargar buses de ruta: $e');
    }
  }

  /// Obtener bus por ID
  Future<BusModel?> obtenerBusPorId(int busId) async {
    try {
      final busData = await _apiService.getBusById(busId);
      if (busData != null) {
        return BusModel.fromJson(busData);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener bus $busId: $e');
      return null;
    }
  }

  /// Actualizar ubicación de un bus (usado por conductor)
  Future<bool> actualizarUbicacionBus({
    required int busId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
  }) async {
    try {
      return await _apiService.actualizarUbicacionBus(
        busId: busId,
        latitud: latitud,
        longitud: longitud,
        velocidad: velocidad,
        direccion: direccion,
      );
    } catch (e) {
      print('❌ Error actualizando ubicación bus: $e');
      return false;
    }
  }

  /// Enviar ubicación GPS del conductor (modo conductor)
  Future<bool> enviarUbicacionConductor({
    required int conductorId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
    required String sentido,
  }) async {
    try {
      // Obtener datos del viaje actual del conductor
      final viaje = await _apiService.getViajeActualConductor(conductorId);

      if (viaje == null) {
        print('❌ No hay viaje activo para conductor $conductorId');
        return false;
      }

      final vehiculoId = viaje['vehiculo_id'];
      final rutaId = viaje['ruta_id'];

      if (vehiculoId == null || rutaId == null) {
        print('❌ Datos de viaje incompletos');
        return false;
      }

      // Enviar ubicación via API REST
      final success = await _apiService.enviarUbicacionConductor(
        conductorId: conductorId,
        vehiculoId: vehiculoId,
        rutaId: rutaId,
        latitud: latitud,
        longitud: longitud,
        velocidad: velocidad,
        direccion: direccion,
      );

      // También enviar via WebSocket para actualización en tiempo real
      if (success) {
        _socketService.enviarUbicacionConductor(
          conductorId: conductorId,
          vehiculoId: vehiculoId,
          rutaId: rutaId,
          latitud: latitud,
          longitud: longitud,
          velocidad: velocidad,
          direccion: direccion,
        );
      }

      return success;
    } catch (e) {
      print('❌ Error enviando ubicación conductor: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔍 FILTROS Y BÚSQUEDA
  // ════════════════════════════════════════════════════════

  /// Filtrar buses por ruta
  void filtrarPorRuta(int? rutaId) {
    _rutaSeleccionada = rutaId;
    if (rutaId == null) {
      _busesFiltrados = [];
    } else {
      _aplicarFiltroRuta();
    }
    notifyListeners();
  }

  void _aplicarFiltroRuta() {
    if (_rutaSeleccionada != null) {
      _busesFiltrados =
          _buses.where((bus) => bus.rutaId == _rutaSeleccionada).toList();
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
    // Usar Geolocator para calcular distancia en metros, convertir a km
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // ════════════════════════════════════════════════════════
  // 🎯 SUSCRIPCIONES A RUTAS
  // ════════════════════════════════════════════════════════

  /// Suscribirse a actualizaciones de una ruta específica
  void suscribirseARuta(int rutaId) {
    _socketService.suscribirseARuta(rutaId);
    print('📍 Suscrito a actualizaciones de ruta $rutaId');
  }

  /// Desuscribirse de una ruta
  void desuscribirseDeRuta(int rutaId) {
    _socketService.desuscribirseDeRuta(rutaId);
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

  /// Refrescar buses (llamar a API de nuevo)
  Future<void> refrescar() async {
    if (_rutaSeleccionada != null) {
      await cargarBusesPorRuta(_rutaSeleccionada!);
    } else {
      await cargarBusesActivos();
    }
  }

  /// Obtener buses por estado
  Map<String, List<BusModel>> get busesPorEstado {
    return {
      'en_movimiento': _buses.where((b) => (b.velocidad ?? 0) > 0).toList(),
      'detenidos': _buses.where((b) => (b.velocidad ?? 0) == 0).toList(),
    };
  }

  /// Obtener cantidad de buses por ruta
  Map<int, int> get busesPorRuta {
    final Map<int, int> conteo = {};
    for (var bus in _buses) {
      if (bus.rutaId != null) {
        conteo[bus.rutaId!] = (conteo[bus.rutaId!] ?? 0) + 1;
      }
    }
    return conteo;
  }

  @override
  void dispose() {
    print('🛑 Desconectando WebSocket de buses...');
    _socketService.desconectar();
    super.dispose();
  }
}
