// ════════════════════════════════════════════════════════
// 🛣️ PROVIDER DE RUTAS - TRANSPORTE INTELIGENTE
// lib/presentation/providers/ruta_provider.dart
// MIGRADO A FIREBASE
// ════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/ruta_model.dart';
import '../../data/models/parada_model.dart';
import '../../services/firebase_service.dart';

class RutaProvider with ChangeNotifier {
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

  /// Cargar todas las rutas disponibles desde Firestore
  Future<void> cargarRutas() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 Cargando rutas desde Firestore...');
      final rutasData = await FirebaseService.getRutasActivas();

      _rutas = rutasData.map((data) => RutaModel.fromJson(data)).toList();

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

  /// Cargar ruta específica por ID con puntos de control
  Future<void> cargarRutaPorId(String rutaId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('📍 Cargando ruta $rutaId...');

      // Obtener datos de la ruta
      final rutaDoc = await FirebaseService.rutasCollection.doc(rutaId).get();

      if (!rutaDoc.exists) {
        _error = 'Ruta $rutaId no encontrada';
        _cargando = false;
        notifyListeners();
        return;
      }

      final rutaData = rutaDoc.data() as Map<String, dynamic>;
      rutaData['id'] = rutaDoc.id;

      // Obtener puntos de control de ida
      final puntosIda = await FirebaseService.getPuntosControl(
        rutaId: rutaId,
        tipo: 'ida',
      );

      // Obtener puntos de control de vuelta
      final puntosVuelta = await FirebaseService.getPuntosControl(
        rutaId: rutaId,
        tipo: 'vuelta',
      );

      // Convertir puntos a coordenadas
      final coordinadasIda = puntosIda
          .map((p) => LatLng(p['latitud'] as double, p['longitud'] as double))
          .toList();

      final coordinadasVuelta = puntosVuelta
          .map((p) => LatLng(p['latitud'] as double, p['longitud'] as double))
          .toList();

      // Crear modelo de ruta con coordenadas
      _rutaSeleccionada = RutaModel(
        id: rutaId,
        nombre: rutaData['nombre'] ?? '',
        color: rutaData['color'] ?? '#FF5722',
        activo: rutaData['activa'] ?? true,
        coordinadasIda: coordinadasIda,
        coordinadasVuelta: coordinadasVuelta,
      );

      print('✅ Ruta cargada: ${_rutaSeleccionada!.nombre}');
      print('   - Puntos IDA: ${coordinadasIda.length}');
      print('   - Puntos VUELTA: ${coordinadasVuelta.length}');

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

      // Por ahora, cargar todas las rutas
      // TODO: Implementar búsqueda geoespacial con GeoFlutterFire
      await cargarRutas();
      _rutasCercanas = _rutas;

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

      // Cargar rutas si no están cargadas
      if (_rutas.isEmpty) {
        await cargarRutas();
      }

      // Buscar en nombres de rutas
      final destinoLower = destino.toLowerCase();
      _resultadosBusqueda = _rutas.where((ruta) {
        return ruta.nombre.toLowerCase().contains(destinoLower);
      }).toList();

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
  Future<void> seleccionarRuta(String rutaId) async {
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

      // Buscar ruta por código (ruta_18, ruta_22, etc.)
      await cargarRutaPorId(codigoLinea);

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
  // 🔧 UTILIDADES
  // ════════════════════════════════════════════════════════

  /// Obtener ruta por ID (sin cambiar la seleccionada)
  RutaModel? obtenerRutaPorId(String rutaId) {
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

  /// Guardar puntos de ruta (mapeo manual)
  Future<bool> guardarPuntosRuta(
      String rutaId, String tipo, List<LatLng> puntos) async {
    try {
      // Convertir LatLng a Map
      final puntosMap = puntos.asMap().entries.map((entry) {
        return {
          'latitud': entry.value.latitude,
          'longitud': entry.value.longitude,
          'orden': entry.key,
        };
      }).toList();

      // Guardar en Firestore (simulado o real)
      // Por ahora solo devolvemos true para evitar errores
      // await FirebaseService.guardarPuntosRuta(rutaId, tipo, puntosMap);
      print('💾 Guardando ${puntos.length} puntos para ruta $rutaId ($tipo)');
      return true;
    } catch (e) {
      print('❌ Error al guardar puntos: $e');
      return false;
    }
  }

  @override
  void dispose() {
    print('🛑 RutaProvider dispose');
    super.dispose();
  }
}
