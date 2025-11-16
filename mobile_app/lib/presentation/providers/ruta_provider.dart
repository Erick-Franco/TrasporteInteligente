// ════════════════════════════════════════════════════════
// 🛣️ PROVIDER DE RUTAS - TRANSPORTE INTELIGENTE
// lib/presentation/providers/ruta_provider.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/ruta_model.dart';
import '../../data/models/parada_model.dart';
import '../../data/repositories/ruta_repository.dart';

class RutaProvider with ChangeNotifier {
  final RutaRepository _repository = RutaRepository();

  // Estado actual
  List<RutaModel> _rutas = [];
  List<RutaModel> _rutasCercanas = [];
  List<RutaModel> _resultadosBusqueda = [];
  RutaModel? _rutaSeleccionada;
  List<ParadaModel> _paradas = [];
  bool _cargando = false;
  String? _error;

  // Getters
  List<RutaModel> get rutas => _rutas;
  List<RutaModel> get rutasCercanas => _rutasCercanas;
  List<RutaModel> get resultadosBusqueda => _resultadosBusqueda;
  RutaModel? get rutaSeleccionada => _rutaSeleccionada;
  List<ParadaModel> get paradas => _paradas;
  bool get cargando => _cargando;
  String? get error => _error;
  int get totalRutas => _rutas.length;

  // ════════════════════════════════════════════════════════
  // 📡 CARGAR RUTAS
  // ════════════════════════════════════════════════════════

  /// Cargar todas las rutas disponibles
  Future<void> cargarRutas() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _rutas = await _repository.getRutas();
      _cargando = false;
      notifyListeners();
      print('✅ Rutas cargadas: ${_rutas.length}');
    } catch (e) {
      _error = 'Error al cargar rutas: $e';
      _cargando = false;
      notifyListeners();
      print('❌ Error al cargar rutas: $e');
    }
  }

  /// Cargar ruta específica por ID (con coordenadas completas)
  Future<void> cargarRutaPorId(int rutaId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('📍 Cargando ruta $rutaId...');
      _rutaSeleccionada = await _repository.getRutaCompleta(rutaId);

      if (_rutaSeleccionada != null) {
        print('✅ Ruta cargada: ${_rutaSeleccionada!.nombre}');
        print('   - Puntos IDA: ${_rutaSeleccionada!.coordinadasIda.length}');
        print(
            '   - Puntos VUELTA: ${_rutaSeleccionada!.coordinadasVuelta.length}');
      } else {
        _error = 'Ruta $rutaId no encontrada';
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar ruta $rutaId: $e';
      _cargando = false;
      notifyListeners();
      print('❌ Error al cargar ruta: $e');
    }
  }

  /// Cargar rutas cercanas a una ubicación
  Future<void> cargarRutasCercanas(
    double lat,
    double lng, {
    double radioKm = 3.0,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('📍 Buscando rutas cercanas a ($lat, $lng)...');
      _rutasCercanas = await _repository.getRutasCercanas(
        lat,
        lng,
        radioKm: radioKm,
      );
      print('✅ Rutas cercanas: ${_rutasCercanas.length}');
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar rutas cercanas: $e';
      _cargando = false;
      _rutasCercanas = [];
      notifyListeners();
      print('❌ Error al cargar rutas cercanas: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔍 BÚSQUEDA Y SELECCIÓN
  // ════════════════════════════════════════════════════════

  /// Buscar rutas por destino
  Future<void> buscarPorDestino(
    String destino,
    double miLat,
    double miLng, {
    double radioKm = 5.0,
  }) async {
    if (destino.trim().isEmpty) {
      _resultadosBusqueda = [];
      notifyListeners();
      return;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 Buscando rutas para: "$destino"');
      _resultadosBusqueda = await _repository.buscarRutasPorDestino(
        destino,
        miLat,
        miLng,
        radioKm: radioKm,
      );
      print('✅ Resultados: ${_resultadosBusqueda.length}');
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al buscar rutas: $e';
      _cargando = false;
      _resultadosBusqueda = [];
      notifyListeners();
      print('❌ Error en búsqueda: $e');
    }
  }

  /// Seleccionar una ruta (cargar coordenadas completas)
  Future<void> seleccionarRuta(int rutaId) async {
    await cargarRutaPorId(rutaId);
  }

  /// Limpiar ruta seleccionada
  void limpiarRutaSeleccionada() {
    _rutaSeleccionada = null;
    notifyListeners();
    print('🗑️ Ruta deseleccionada');
  }

  /// Limpiar resultados de búsqueda
  void limpiarBusqueda() {
    _resultadosBusqueda = [];
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // 🚗 MODO CONDUCTOR
  // ════════════════════════════════════════════════════════

  /// Cargar ruta del conductor por código de línea
  Future<void> cargarRutaConductor(String codigoLinea) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('🚗 Cargando ruta del conductor - Línea: $codigoLinea');

      // Buscar ruta por código (L18, L22, etc.)
      _rutaSeleccionada = await _repository.getRutaPorCodigo(codigoLinea);

      if (_rutaSeleccionada != null) {
        print('✅ Ruta del conductor cargada: ${_rutaSeleccionada!.nombre}');
      } else {
        _error = 'No se encontró la ruta $codigoLinea';
        print('❌ Ruta $codigoLinea no encontrada');
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar ruta del conductor: $e';
      _cargando = false;
      notifyListeners();
      print('❌ Error al cargar ruta del conductor: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 🚏 PARADAS
  // ════════════════════════════════════════════════════════

  /// Cargar paradas cercanas
  Future<void> cargarParadasCercanas(double lat, double lng) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _paradas = await _repository.getParadasCercanas(lat, lng);
      _cargando = false;
      notifyListeners();
      print('✅ Paradas cercanas: ${_paradas.length}');
    } catch (e) {
      _error = 'Error al cargar paradas: $e';
      _cargando = false;
      notifyListeners();
      print('❌ Error al cargar paradas: $e');
    }
  }

  /// Cargar ruta con paradas
  Future<Map<String, dynamic>?> cargarRutaConParadas(int rutaId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getRutaConParadas(rutaId);
      _cargando = false;
      notifyListeners();
      return data;
    } catch (e) {
      _error = 'Error al cargar ruta con paradas: $e';
      _cargando = false;
      notifyListeners();
      print('❌ Error al cargar ruta con paradas: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔧 UTILIDADES
  // ════════════════════════════════════════════════════════

  /// Obtener ruta por ID (sin cambiar la seleccionada)
  RutaModel? obtenerRutaPorId(int rutaId) {
    try {
      return _rutas.firstWhere((ruta) => ruta.id == rutaId);
    } catch (e) {
      return null;
    }
  }

  /// Obtener ruta por nombre (L18, L22, etc.)
  RutaModel? obtenerRutaPorNombre(String nombre) {
    try {
      return _rutas.firstWhere(
        (ruta) => ruta.nombre.toLowerCase().contains(nombre.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  /// Refrescar rutas
  Future<void> refrescar() async {
    await cargarRutas();
  }

  /// Verificar si hay una ruta seleccionada
  bool get tieneRutaSeleccionada => _rutaSeleccionada != null;

  /// Obtener todas las rutas disponibles (nombres)
  List<String> get nombresRutas {
    return _rutas.map((ruta) => ruta.nombre).toList();
  }

  /// Obtener rutas por nombre (búsqueda local)
  List<RutaModel> buscarRutasPorNombre(String query) {
    if (query.trim().isEmpty) return [];

    final queryLower = query.toLowerCase();
    return _rutas.where((ruta) {
      return ruta.nombre.toLowerCase().contains(queryLower);
    }).toList();
  }

  @override
  void dispose() {
    print('🛑 RutaProvider dispose');
    super.dispose();
  }
}
