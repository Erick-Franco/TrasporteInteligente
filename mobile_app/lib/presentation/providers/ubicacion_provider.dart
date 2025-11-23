// lib/presentation/providers/ubicacion_provider.dart

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';

class UbicacionProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _posicionActual;
  bool _cargando = false;
  String? _error;
  bool _permisosOtorgados = false;

  Position? get posicionActual => _posicionActual;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get permisosOtorgados => _permisosOtorgados;

  // Verificar y solicitar permisos
  Future<bool> verificarPermisos() async {
    try {
      // Verificar si el servicio está habilitado
      final servicioHabilitado =
          await _locationService.isLocationServiceEnabled();

      if (!servicioHabilitado) {
        _error = 'Servicio de ubicación deshabilitado';
        notifyListeners();
        return false;
      }

      // Solicitar permisos
      _permisosOtorgados = await _locationService.requestLocationPermission();

      notifyListeners();
      return _permisosOtorgados;
    } catch (e) {
      _error = 'Error al verificar permisos: $e';
      notifyListeners();
      return false;
    }
  }

  // Obtener ubicación actual
  Future<void> obtenerUbicacionActual() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _posicionActual = await _locationService.getCurrentLocation();

      if (_posicionActual == null) {
        _error = 'No se pudo obtener la ubicación. Verifica los permisos.';
      } else {
        _permisosOtorgados = true;
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al obtener ubicación: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  // Iniciar seguimiento continuo de ubicación
  void iniciarSeguimiento() {
    _locationService.getLocationStream().listen(
      (Position position) {
        _posicionActual = position;
        _permisosOtorgados = true;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Error en seguimiento: $error';
        notifyListeners();
      },
    );
  }

  // Calcular distancia a un punto (en metros)
  double? calcularDistancia(double lat, double lng) {
    if (_posicionActual == null) return null;

    return _locationService.calculateDistance(
      _posicionActual!.latitude,
      _posicionActual!.longitude,
      lat,
      lng,
    );
  }

  // Calcular distancia a un punto (en kilómetros)
  double? calcularDistanciaKm(double lat, double lng) {
    if (_posicionActual == null) return null;

    return _locationService.calculateDistanceInKm(
      _posicionActual!.latitude,
      _posicionActual!.longitude,
      lat,
      lng,
    );
  }

  // Limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
