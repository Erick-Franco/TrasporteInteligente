// lib/widgets/lineas_cercanas_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models/ruta_model.dart';

// ════════════════════════════════════════════════════════
// 🆕 CAMBIADO A StatefulWidget para manejar expansión
// ════════════════════════════════════════════════════════
class LineasCercanasWidget extends StatefulWidget {
  final List<RutaModel> rutasCercanas;
  final bool cargando;
  final Function(RutaModel) onVerRuta;
  final double? miLatitud;
  final double? miLongitud;

  const LineasCercanasWidget({
    Key? key,
    required this.rutasCercanas,
    required this.onVerRuta,
    this.cargando = false,
    this.miLatitud,
    this.miLongitud,
  }) : super(key: key);

  @override
  State<LineasCercanasWidget> createState() => _LineasCercanasWidgetState();
}

class _LineasCercanasWidgetState extends State<LineasCercanasWidget>
    with SingleTickerProviderStateMixin {
  // 🆕 Estado de expansión
  bool _expandido = true; // Por defecto expandido
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador de animación para la flecha
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animación de rotación (0 = abajo, 0.5 = arriba)
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Iniciar expandido
    if (_expandido) {
      _animationController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _expandido = !_expandido;
      if (_expandido) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ════════════════════════════════════════════════════════
    // ESTADO: CARGANDO
    // ════════════════════════════════════════════════════════
    if (widget.cargando) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ════════════════════════════════════════════════════════
    // ESTADO: SIN RUTAS
    // ════════════════════════════════════════════════════════
    if (widget.rutasCercanas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay rutas cerca de ti',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ════════════════════════════════════════════════════════
    // WIDGET PRINCIPAL: EXPANDIBLE
    // ════════════════════════════════════════════════════════
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ════════════════════════════════════════════════════════
          // HEADER CLICKEABLE (con flecha animada)
          // ════════════════════════════════════════════════════════
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.near_me, color: Colors.indigo.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Cerca de ti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),

                  // Badge con cantidad de líneas
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.rutasCercanas.length} ${widget.rutasCercanas.length == 1 ? "línea" : "líneas"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 🆕 FLECHA ANIMADA
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.indigo.shade700,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ════════════════════════════════════════════════════════
          // CONTENIDO EXPANDIBLE (con animación)
          // ════════════════════════════════════════════════════════
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expandido
                ? Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Lista de rutas (máximo 3)
                            ...widget.rutasCercanas.take(3).map((ruta) {
                              final distancia = _calcularDistanciaCercana(ruta);
                              return _RutaItem(
                                ruta: ruta,
                                distancia: distancia,
                                onTap: () => widget.onVerRuta(ruta),
                              );
                            }).toList(),

                            // Botón "Ver más" (si hay más de 3)
                            if (widget.rutasCercanas.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () {
                                    _mostrarTodasLasRutas(context);
                                  },
                                  child: Text(
                                    'Ver ${widget.rutasCercanas.length - 3} más',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // MOSTRAR TODAS LAS RUTAS EN BOTTOM SHEET
  // ════════════════════════════════════════════════════════
  void _mostrarTodasLasRutas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle del bottom sheet
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.near_me, color: Colors.indigo.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Todas las líneas cerca de ti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Lista completa
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.rutasCercanas.length,
                  itemBuilder: (context, index) {
                    final ruta = widget.rutasCercanas[index];
                    final distancia = _calcularDistanciaCercana(ruta);
                    return _RutaItem(
                      ruta: ruta,
                      distancia: distancia,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onVerRuta(ruta);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // CALCULAR DISTANCIA CERCANA
  // ════════════════════════════════════════════════════════
  double? _calcularDistanciaCercana(RutaModel ruta) {
    if (widget.miLatitud == null || widget.miLongitud == null) return null;

    double? menorDistancia;

    // Buscar el punto más cercano en IDA
    for (final coord in ruta.coordinadasIda) {
      final dist = _calcularDistanciaKm(
        widget.miLatitud!,
        widget.miLongitud!,
        coord.latitude,
        coord.longitude,
      );
      if (menorDistancia == null || dist < menorDistancia) {
        menorDistancia = dist;
      }
    }

    // Buscar el punto más cercano en VUELTA
    for (final coord in ruta.coordinadasVuelta) {
      final dist = _calcularDistanciaKm(
        widget.miLatitud!,
        widget.miLongitud!,
        coord.latitude,
        coord.longitude,
      );
      if (menorDistancia == null || dist < menorDistancia) {
        menorDistancia = dist;
      }
    }

    return menorDistancia;
  }

  double _calcularDistanciaKm(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}

// ════════════════════════════════════════════════════════
// Widget individual para cada ruta
// ════════════════════════════════════════════════════════
class _RutaItem extends StatelessWidget {
  final RutaModel ruta;
  final double? distancia;
  final VoidCallback onTap;

  const _RutaItem({
    required this.ruta,
    required this.distancia,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(ruta.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícono de bus con color de la ruta
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Información de la ruta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (distancia != null)
                      Text(
                        _formatearDistancia(distancia!),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),

              // Botón "Ver ruta"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VER RUTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.indigo;

    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.indigo;
    }
  }

  String _formatearDistancia(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    } else {
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
