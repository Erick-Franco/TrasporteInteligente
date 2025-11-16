// lib/widgets/mapa_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/constants.dart';

class MapaWidget extends StatelessWidget {
  final MapController controller;
  final LatLng centro;
  final double zoom;
  final List<Marker> marcadores;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;

  const MapaWidget({
    Key? key,
    required this.controller,
    required this.centro,
    this.zoom = 15.0,
    this.marcadores = const [],
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: centro,
        initialZoom: zoom,
        minZoom: 12.0,
        maxZoom: 18.0,
        onTap: onTap != null ? (_, point) => onTap!(point) : null,
        onLongPress:
            onLongPress != null ? (_, point) => onLongPress!(point) : null,
      ),
      children: [
        // Capa de tiles (mapa base)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mobile_app',
          maxZoom: 19,
        ),

        // Capa de marcadores
        if (marcadores.isNotEmpty) MarkerLayer(markers: marcadores),
      ],
    );
  }
}

// Widget auxiliar para crear marcadores personalizados
class MarcadorPersonalizado extends StatelessWidget {
  final IconData icono;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const MarcadorPersonalizado({
    Key? key,
    required this.icono,
    this.color = Colors.blue,
    this.size = 40,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
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
        child: Icon(
          icono,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
