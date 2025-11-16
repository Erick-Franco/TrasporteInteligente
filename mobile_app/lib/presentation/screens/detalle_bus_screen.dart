// lib/presentation/screens/detalle_bus_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/bus_model.dart';
import '../providers/bus_provider.dart';
import '../../utils/location_helper.dart';

class DetalleBusScreen extends StatefulWidget {
  final BusModel bus;

  const DetalleBusScreen({
    Key? key,
    required this.bus,
  }) : super(key: key);

  @override
  State<DetalleBusScreen> createState() => _DetalleBusScreenState();
}

class _DetalleBusScreenState extends State<DetalleBusScreen> {
  bool _cargandoHistorial = false;
  List<dynamic> _historial = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _cargandoHistorial = true);

    try {
      final busProvider = context.read<BusProvider>();
      // Aquí podrías cargar el historial si lo implementas
      // _historial = await busProvider.obtenerHistorial(widget.bus.busId);
    } catch (e) {
      print('Error al cargar historial: $e');
    }

    setState(() => _cargandoHistorial = false);
  }

  @override
  Widget build(BuildContext context) {
    final velocidad = widget.bus.velocidad != null
        ? double.tryParse(widget.bus.velocidad.toString()) ?? 0.0
        : 0.0;

    final direccion = widget.bus.direccion ?? 0;
    final direccionCardinal = LocationHelper.obtenerDireccionCardinal(
      direccion.toDouble(),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Bus ${widget.bus.placa ?? widget.bus.busId}'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarHistorial,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado con información principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.indigo.shade700,
                    Colors.indigo.shade600,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.bus.placa ?? 'Sin placa',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.bus.rutaNombre ?? 'Ruta desconocida',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEstadoChip(widget.bus.estado),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Velocidad y dirección
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.speed,
                      title: 'Velocidad',
                      value: velocidad.toStringAsFixed(1),
                      unit: 'km/h',
                      color: _getColorVelocidad(velocidad),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.navigation,
                      title: 'Dirección',
                      value: direccion.toString(),
                      unit: '° $direccionCardinal',
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Información detallada
            _buildSeccion(
              titulo: 'Ubicación actual',
              children: [
                _buildInfoTile(
                  icon: Icons.location_on,
                  label: 'Latitud',
                  valor: widget.bus.latitud?.toString() ?? 'N/A',
                ),
                _buildInfoTile(
                  icon: Icons.location_on,
                  label: 'Longitud',
                  valor: widget.bus.longitud?.toString() ?? 'N/A',
                ),
                _buildInfoTile(
                  icon: Icons.pin_drop,
                  label: 'Coordenadas',
                  valor: LocationHelper.formatearCoordenadas(
                    double.tryParse(widget.bus.latitud?.toString() ?? '0') ?? 0,
                    double.tryParse(widget.bus.longitud?.toString() ?? '0') ??
                        0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información del bus
            _buildSeccion(
              titulo: 'Detalles del bus',
              children: [
                _buildInfoTile(
                  icon: Icons.badge,
                  label: 'ID del Bus',
                  valor: widget.bus.busId.toString(),
                ),
                _buildInfoTile(
                  icon: Icons.route,
                  label: 'ID de Ruta',
                  valor: widget.bus.rutaId?.toString() ?? 'N/A',
                ),
                _buildInfoTile(
                  icon: Icons.info_outline,
                  label: 'Estado',
                  valor: widget.bus.estado ?? 'activo',
                ),
                if (widget.bus.ultimaActualizacion != null)
                  _buildInfoTile(
                    icon: Icons.update,
                    label: 'Última actualización',
                    valor: _formatearFecha(widget.bus.ultimaActualizacion!),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Historial (futuro)
            if (_cargandoHistorial)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_historial.isNotEmpty)
              _buildSeccion(
                titulo: 'Historial reciente',
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Historial de ubicaciones...'),
                  ),
                ],
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String? estado) {
    final estadoActual = estado ?? 'activo';
    Color color;
    IconData icono;

    switch (estadoActual.toLowerCase()) {
      case 'activo':
        color = Colors.green;
        icono = Icons.check_circle;
        break;
      case 'mantenimiento':
        color = Colors.orange;
        icono = Icons.build;
        break;
      case 'fuera_de_servicio':
        color = Colors.red;
        icono = Icons.block;
        break;
      default:
        color = Colors.grey;
        icono = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            estadoActual.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorVelocidad(double velocidad) {
    if (velocidad == 0) return Colors.grey.shade700;
    if (velocidad < 15) return Colors.orange.shade700;
    if (velocidad < 30) return Colors.green.shade700;
    return Colors.blue.shade700;
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inSeconds < 60) {
      return 'Hace ${diferencia.inSeconds} segundos';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minutos';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} horas';
    } else {
      return 'Hace ${diferencia.inDays} días';
    }
  }
}
