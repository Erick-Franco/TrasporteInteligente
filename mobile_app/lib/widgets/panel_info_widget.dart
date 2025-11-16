// lib/widgets/panel_info_widget.dart

import 'package:flutter/material.dart';
import '../data/models/bus_model.dart';

class PanelInfoWidget extends StatelessWidget {
  final BusModel? busSeleccionado;
  final VoidCallback? onCerrar;
  final VoidCallback? onVerDetalle;

  const PanelInfoWidget({
    Key? key,
    this.busSeleccionado,
    this.onCerrar,
    this.onVerDetalle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (busSeleccionado == null) {
      return const SizedBox.shrink();
    }

    final bus = busSeleccionado!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con botón de cerrar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.indigo.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.placa ?? 'Bus ${bus.busId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      bus.rutaNombre ?? 'Ruta desconocida',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCerrar,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Información del bus
          _InfoRow(
            icon: Icons.speed,
            label: 'Velocidad',
            value: '${bus.velocidad ?? 0} km/h',
            color: _getColorVelocidad(bus.velocidad),
          ),

          const SizedBox(height: 8),

          _InfoRow(
            icon: Icons.navigation,
            label: 'Dirección',
            value: '${bus.direccion ?? 0}°',
            color: Colors.blue.shade700,
          ),

          const SizedBox(height: 8),

          _InfoRow(
            icon: Icons.info_outline,
            label: 'Estado',
            value: bus.estado ?? 'activo',
            color: Colors.green.shade700,
          ),

          const SizedBox(height: 16),

          // Botón ver más detalles
          if (onVerDetalle != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onVerDetalle,
                icon: const Icon(Icons.info),
                label: const Text('Ver detalles completos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getColorVelocidad(dynamic velocidad) {
    final vel =
        velocidad != null ? double.tryParse(velocidad.toString()) ?? 0 : 0;
    if (vel == 0) return Colors.grey.shade700;
    if (vel < 15) return Colors.orange.shade700;
    if (vel < 30) return Colors.green.shade700;
    return Colors.blue.shade700;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Widget de estadísticas generales
class EstadisticasWidget extends StatelessWidget {
  final int totalBuses;
  final int busesActivos;
  final double velocidadPromedio;

  const EstadisticasWidget({
    Key? key,
    required this.totalBuses,
    required this.busesActivos,
    required this.velocidadPromedio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Estadistica(
            icono: Icons.directions_bus,
            valor: totalBuses.toString(),
            label: 'Total',
            color: Colors.indigo.shade700,
          ),
          _Estadistica(
            icono: Icons.check_circle,
            valor: busesActivos.toString(),
            label: 'Activos',
            color: Colors.green.shade700,
          ),
          _Estadistica(
            icono: Icons.speed,
            valor: '${velocidadPromedio.round()}',
            label: 'km/h',
            color: Colors.blue.shade700,
          ),
        ],
      ),
    );
  }
}

class _Estadistica extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String label;
  final Color color;

  const _Estadistica({
    required this.icono,
    required this.valor,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
