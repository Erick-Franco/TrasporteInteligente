// lib/widgets/marcador_bus_widget.dart

import 'package:flutter/material.dart';
import '../data/models/bus_model.dart';
import '../utils/map_utils.dart';

class MarcadorBusWidget extends StatelessWidget {
  final BusModel bus;
  final VoidCallback? onTap;
  final bool esSeleccionado;

  const MarcadorBusWidget({
    Key? key,
    required this.bus,
    this.onTap,
    this.esSeleccionado = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final velocidad = bus.velocidad != null
        ? double.tryParse(bus.velocidad.toString()) ?? 0.0
        : 0.0;

    final color = MapUtils.obtenerColorPorVelocidad(velocidad);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sombra animada si está seleccionado
          if (esSeleccionado)
            Positioned(
              left: 0,
              right: 0,
              bottom: -5,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),

          // Marcador principal
          Container(
            width: esSeleccionado ? 50 : 40,
            height: esSeleccionado ? 50 : 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: esSeleccionado ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_bus,
              color: Colors.white,
              size: esSeleccionado ? 25 : 20,
            ),
          ),

          // Indicador de velocidad
          if (velocidad > 0)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '${velocidad.round()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Widget para marcador de parada
class MarcadorParadaWidget extends StatelessWidget {
  final String nombre;
  final bool esPrincipal;
  final VoidCallback? onTap;

  const MarcadorParadaWidget({
    Key? key,
    required this.nombre,
    this.esPrincipal = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: esPrincipal ? 35 : 25,
            height: esPrincipal ? 35 : 25,
            decoration: BoxDecoration(
              color: esPrincipal ? Colors.red.shade600 : Colors.blue.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              esPrincipal ? Icons.location_city : Icons.place,
              color: Colors.white,
              size: esPrincipal ? 20 : 14,
            ),
          ),
          if (esPrincipal)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
