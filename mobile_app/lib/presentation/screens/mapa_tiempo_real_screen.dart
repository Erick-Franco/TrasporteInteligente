// ════════════════════════════════════════════════════════
// 🗺️ PANTALLA MAPA EN TIEMPO REAL - TRANSPORTE INTELIGENTE
// lib/presentation/screens/mapa_tiempo_real_screen.dart
// ════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/bus_provider.dart';
import '../providers/ruta_provider.dart';
import '../../config/constants.dart';
import '../../data/models/bus_model.dart';

class MapaTiempoRealScreen extends StatefulWidget {
  final bool modoConductor;
  final String? conductorId; // ID del conductor (String para Firebase)
  final String? rutaId; // ID de la ruta del conductor (String para Firebase)

  const MapaTiempoRealScreen({
    Key? key,
    this.modoConductor = false,
    this.conductorId,
    this.rutaId,
  }) : super(key: key);

  @override
  State<MapaTiempoRealScreen> createState() => _MapaTiempoRealScreenState();
}

class _MapaTiempoRealScreenState extends State<MapaTiempoRealScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  String _sentidoActual = 'ida'; // Sentido del conductor

  // Mapeo anual manual (comentado hasta que se aplique la implementación completa)
  // bool _isAnnualMapping = false;
  // List<LatLng> _annualMappingPoints = [];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionUsuario();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarMapa();
    });
  }

  // ════════════════════════════════════════════════════════
  // 🚀 INICIALIZACIÓN
  // ════════════════════════════════════════════════════════

  Future<void> _inicializarMapa() async {
    try {
      await _conectarWebSocket();
      await _cargarDatosIniciales();
    } catch (e) {
      print('❌ Error al inicializar mapa: $e');
      _mostrarError('Error al cargar el mapa');
    }
  }

  Future<void> _conectarWebSocket() async {
    final busProvider = Provider.of<BusProvider>(context, listen: false);

    if (!busProvider.webSocketConectado) {
      await busProvider.conectarWebSocket();
      print('✅ WebSocket conectado en mapa');
    }
  }

  Future<void> _cargarDatosIniciales() async {
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    final rutaProvider = Provider.of<RutaProvider>(context, listen: false);

    if (widget.modoConductor && widget.rutaId != null) {
      // ════════════════════════════════════════════════════════
      // MODO CONDUCTOR: Cargar solo su ruta y buses de su línea
      // ════════════════════════════════════════════════════════

      // Cargar ruta del conductor
      await rutaProvider.cargarRutaPorId(widget.rutaId!);

      // Cargar buses de la misma ruta
      await busProvider.cargarBusesPorRuta(widget.rutaId!);

      print('✅ Modo conductor - Ruta ${widget.rutaId} cargada');
    } else {
      // ════════════════════════════════════════════════════════
      // MODO USUARIO: Cargar todas las rutas
      // ════════════════════════════════════════════════════════

      await rutaProvider.cargarRutas();
      await busProvider.cargarBusesActivos();

      print('✅ Modo usuario - Todas las rutas cargadas');
    }
  }

  // ════════════════════════════════════════════════════════
  // 📍 UBICACIÓN GPS
  // ════════════════════════════════════════════════════════

  Future<void> _obtenerUbicacionUsuario() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _mostrarError('Permisos de ubicación denegados');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Centrar mapa en ubicación del usuario
      _mapController.move(_userLocation!, 15.0);

      // 🆕 MODO CONDUCTOR: Iniciar envío de GPS en tiempo real
      if (widget.modoConductor && widget.conductorId != null) {
        _iniciarEnvioGPS();
      }
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
      setState(() => _isLoadingLocation = false);
      _mostrarError('No se pudo obtener tu ubicación');
    }
  }

  // ════════════════════════════════════════════════════════
  // 📡 ENVÍO DE GPS (MODO CONDUCTOR)
  // ════════════════════════════════════════════════════════

  void _iniciarEnvioGPS() {
    if (!widget.modoConductor || widget.conductorId == null) return;

    // Escuchar cambios de posición cada 5 segundos
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    ).listen((Position position) {
      _enviarUbicacionAlServidor(position);
    });

    print('📍 Envío de GPS activado para conductor ${widget.conductorId}');
  }

  Future<void> _enviarUbicacionAlServidor(Position position) async {
    if (!widget.modoConductor || widget.conductorId == null) return;

    final busProvider = Provider.of<BusProvider>(context, listen: false);

    try {
      await busProvider.enviarUbicacionConductor(
        conductorId: widget.conductorId!,
        latitud: position.latitude,
        longitud: position.longitude,
        velocidad: position.speed * 3.6, // m/s a km/h
        direccion: position.heading,
        sentido: _sentidoActual,
      );

      // Actualizar marcador del usuario
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('❌ Error al enviar ubicación: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎨 CONSTRUCCIÓN DE LA UI
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMapa(),
          if (widget.modoConductor) _buildBannerConductor(),
          if (_isLoadingLocation) _buildLoadingOverlay(),
          if (_userLocation != null) _buildBotones(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 🗺️ MAPA
  // ════════════════════════════════════════════════════════

  Widget _buildMapa() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          AppConstants.defaultLat,
          AppConstants.defaultLng,
        ),
        initialZoom: AppConstants.defaultZoom,
        minZoom: 12.0,
        maxZoom: 18.0,
      ),
      children: [
        // Tiles de OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.transporte_inteligente.app',
          maxZoom: 19,
        ),

        // Rutas (líneas azules/rojas)
        _buildRutasLayer(),

        // Marcadores de buses
        _buildBusesLayer(),

        // Marcador del usuario/conductor
        if (_userLocation != null) _buildMarcadorUsuario(),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // 🛣️ CAPA DE RUTAS (IDA Y VUELTA)
  // ════════════════════════════════════════════════════════

  Widget _buildRutasLayer() {
    return Consumer<RutaProvider>(
      builder: (context, rutaProvider, child) {
        final ruta = widget.modoConductor
            ? rutaProvider.rutaSeleccionada // Ruta del conductor
            : rutaProvider.rutaSeleccionada; // Ruta seleccionada por usuario

        if (ruta == null) return const SizedBox.shrink();

        return PolylineLayer(
          polylines: [
            // LÍNEA IDA
            if (ruta.coordinadasIda.isNotEmpty)
              Polyline(
                points: ruta.coordinadasIda,
                color: widget.modoConductor
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
                strokeWidth: widget.modoConductor ? 6.0 : 5.0,
                borderColor: Colors.white,
                borderStrokeWidth: 2.0,
              ),

            // LÍNEA VUELTA
            if (ruta.coordinadasVuelta.isNotEmpty)
              Polyline(
                points: ruta.coordinadasVuelta,
                color: widget.modoConductor
                    ? Colors.orange.shade500
                    : Colors.red.shade700,
                strokeWidth: widget.modoConductor ? 6.0 : 5.0,
                borderColor: Colors.white,
                borderStrokeWidth: 2.0,
              ),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  // 🚌 CAPA DE BUSES
  // ════════════════════════════════════════════════════════

  Widget _buildBusesLayer() {
    return Consumer<BusProvider>(
      builder: (context, busProvider, child) {
        // Filtrar buses según modo
        final List<BusModel> buses =
            widget.modoConductor && widget.rutaId != null
                ? busProvider.buses
                    .where((bus) => bus.rutaId == widget.rutaId)
                    .toList()
                : busProvider.buses;

        return MarkerLayer(
          markers: buses
              .where((bus) => bus.tieneUbicacion) // Solo buses con GPS válido
              .map((bus) => _crearMarcadorBus(bus))
              .toList(),
        );
      },
    );
  }

  Marker _crearMarcadorBus(BusModel bus) {
    final Color colorBus = widget.modoConductor
        ? Colors.orange.shade700
        : (bus.sentido == 'ida' ? Colors.blue.shade700 : Colors.red.shade700);

    return Marker(
      point: LatLng(bus.latitud!, bus.longitud!),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _mostrarInfoBus(bus),
        child: Container(
          decoration: BoxDecoration(
            color: colorBus,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 👤 MARCADOR DEL USUARIO/CONDUCTOR
  // ════════════════════════════════════════════════════════

  Widget _buildMarcadorUsuario() {
    return MarkerLayer(
      markers: [
        Marker(
          point: _userLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: widget.modoConductor
                  ? Colors.orange.shade500
                  : Colors.green.shade500,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: (widget.modoConductor ? Colors.orange : Colors.green)
                      .withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              widget.modoConductor ? Icons.directions_bus : Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // 🎨 UI COMPONENTS
  // ════════════════════════════════════════════════════════

  Widget _buildBannerConductor() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Consumer<BusProvider>(
        builder: (context, busProvider, child) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MODO CONDUCTOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Sentido: ${_sentidoActual.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: busProvider.webSocketConectado
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        busProvider.webSocketConectado
                            ? Icons.gps_fixed
                            : Icons.gps_off,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        busProvider.webSocketConectado ? 'ACTIVO' : 'INACTIVO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Obteniendo ubicación...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotones() {
    return Positioned(
      bottom: widget.modoConductor ? 120 : 80,
      left: 16,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón: Mi ubicación
            FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 16.0);
                }
              },
              heroTag: 'mi_ubicacion',
              child: Icon(
                Icons.my_location,
                color: widget.modoConductor
                    ? Colors.orange.shade700
                    : Colors.indigo.shade700,
              ),
            ),

            const SizedBox(height: 8),

            // Botón: Cambiar sentido (SOLO MODO CONDUCTOR)
            if (widget.modoConductor)
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _mostrarDialogoSentido,
                heroTag: 'cambiar_sentido',
                child: Icon(Icons.swap_horiz, color: Colors.blue.shade700),
              ),

            const SizedBox(height: 8),

            // Botón: Limpiar ruta (SOLO MODO USUARIO)
            if (!widget.modoConductor)
              Consumer<RutaProvider>(
                builder: (context, rutaProvider, child) {
                  if (rutaProvider.rutaSeleccionada == null) {
                    return const SizedBox.shrink();
                  }

                  return FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      rutaProvider.limpiarRutaSeleccionada();
                    },
                    heroTag: 'limpiar_ruta',
                    child: Icon(Icons.close, color: Colors.red.shade700),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 💬 DIÁLOGOS Y MODALES
  // ════════════════════════════════════════════════════════

  void _mostrarDialogoSentido() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Sentido'),
        content: Text('Sentido actual: ${_sentidoActual.toUpperCase()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _sentidoActual = 'ida');
              Navigator.pop(context);
              _mostrarSnackbar('Sentido cambiado a IDA', Colors.blue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: const Text('IDA'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _sentidoActual = 'vuelta');
              Navigator.pop(context);
              _mostrarSnackbar('Sentido cambiado a VUELTA', Colors.red);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('VUELTA'),
          ),
        ],
      ),
    );
  }

  void _mostrarInfoBus(BusModel bus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de arrastre
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header con icono y placa
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bus.sentido == 'ida'
                        ? Colors.blue.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: bus.sentido == 'ida'
                        ? Colors.blue.shade700
                        : Colors.red.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.placa ?? 'Sin placa',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${bus.rutaNombre ?? 'Ruta desconocida'} - ${bus.sentido.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Información del bus
            _InfoRow(
              icon: Icons.speed,
              label: 'Velocidad',
              value: '${(bus.velocidad ?? 0).toStringAsFixed(1)} km/h',
            ),
            _InfoRow(
              icon: Icons.navigation,
              label: 'Dirección',
              value: '${(bus.direccion ?? 0).toStringAsFixed(0)}°',
            ),
            _InfoRow(
              icon:
                  bus.sentido == 'ida' ? Icons.arrow_forward : Icons.arrow_back,
              label: 'Sentido',
              value: bus.sentido.toUpperCase(),
            ),
            if (bus.conductorNombre != null)
              _InfoRow(
                icon: Icons.person,
                label: 'Conductor',
                value: bus.conductorNombre!,
              ),
            if (bus.datosActualizados)
              _InfoRow(
                icon: Icons.access_time,
                label: 'Última actualización',
                value: bus.tiempoDesdeActualizacion,
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 🛠️ UTILIDADES
  // ════════════════════════════════════════════════════════

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════
// 📊 WIDGET DE INFORMACIÓN
// ════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
