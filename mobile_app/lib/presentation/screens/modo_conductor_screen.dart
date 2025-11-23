// ════════════════════════════════════════════════════════
// 🚗 PANTALLA MODO CONDUCTOR - TRANSPORTE INTELIGENTE
// lib/presentation/screens/modo_conductor_screen.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/conductor_provider.dart';
import '../providers/ruta_provider.dart';
import 'home_screen.dart';
import 'mapa_tiempo_real_screen.dart';

class ModoConductorScreen extends StatefulWidget {
  const ModoConductorScreen({Key? key}) : super(key: key);

  @override
  State<ModoConductorScreen> createState() => _ModoConductorScreenState();
}

class _ModoConductorScreenState extends State<ModoConductorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarRutaConductor();
    });
  }

  // ════════════════════════════════════════════════════════
  // 🚀 INICIALIZACIÓN
  // ════════════════════════════════════════════════════════

  Future<void> _cargarRutaConductor() async {
    final conductorProvider = context.read<ConductorProvider>();
    final rutaProvider = context.read<RutaProvider>();

    final conductor = conductorProvider.conductor;

    if (conductor == null) {
      print('❌ No hay conductor logueado');
      return;
    }

    // Cargar ruta por ID si está disponible
    if (conductor.rutaId != null) {
      await rutaProvider.cargarRutaPorId(conductor.rutaId!);
      print('✅ Ruta ${conductor.rutaId} cargada para conductor');
    } else {
      print('⚠️ Conductor sin ruta asignada');
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎨 UI
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Consumer<ConductorProvider>(
      builder: (context, conductorProvider, child) {
        final conductor = conductorProvider.conductor;

        // Verificar si el conductor existe
        if (conductor == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.red,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'No se encontró información del conductor',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final username = await _obtenerUsername();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HomeScreen(username: username),
                          ),
                        );
                      }
                    },
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Modo Conductor'),
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            actions: [
              // Indicador de GPS
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  conductorProvider.gpsActivo ? Icons.gps_fixed : Icons.gps_off,
                  color: conductorProvider.gpsActivo
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _confirmarLogout(context),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: Column(
            children: [
              // ════════════════════════════════════════════════════════
              // HEADER INFO CONDUCTOR
              // ════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade700,
                      child: Text(
                        conductor.nombre[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conductor.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            conductor.rutaCompleta,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            conductor.vehiculoInfo,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      conductorProvider.sentidoActual == 'ida'
                                          ? Colors.blue.shade100
                                          : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Sentido: ${conductorProvider.sentidoActual.toUpperCase()}',
                                  style: TextStyle(
                                    color:
                                        conductorProvider.sentidoActual == 'ida'
                                            ? Colors.blue.shade700
                                            : Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (conductor.tieneViajeActivo)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.directions_bus,
                                        size: 12,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'En viaje',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      conductorProvider.estaLogeado
                          ? Icons.check_circle
                          : Icons.error,
                      color: conductorProvider.estaLogeado
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 28,
                    ),
                  ],
                ),
              ),

              // ════════════════════════════════════════════════════════
              // MAPA CON LA RUTA DEL CONDUCTOR
              // ════════════════════════════════════════════════════════
              Expanded(
                child: MapaTiempoRealScreen(
                  modoConductor: true,
                  conductorId: conductor.id,
                  rutaId: conductor.rutaId,
                ),
              ),

              // ════════════════════════════════════════════════════════
              // PANEL DE CONTROL CONDUCTOR
              // ════════════════════════════════════════════════════════
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Info ruta
                    Consumer<RutaProvider>(
                      builder: (context, rutaProvider, child) {
                        final ruta = rutaProvider.rutaSeleccionada;
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ruta: ${conductor.rutaCompleta}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        conductorProvider.gpsActivo
                                            ? Icons.gps_fixed
                                            : Icons.gps_off,
                                        size: 14,
                                        color: conductorProvider.gpsActivo
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        conductorProvider.gpsActivo
                                            ? 'GPS Activado'
                                            : 'GPS Desactivado',
                                        style: TextStyle(
                                          color: conductorProvider.gpsActivo
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (ruta != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Puntos: ${ruta.coordinadasIda.length} ida, ${ruta.coordinadasVuelta.length} vuelta',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      'Cargando ruta...',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Botones de control
                    Row(
                      children: [
                        // Botón cambiar sentido
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _cambiarSentido(context),
                            icon: const Icon(Icons.swap_horiz, size: 20),
                            label: const Text('Cambiar Sentido'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón iniciar/finalizar viaje
                        Expanded(
                          child: conductor.tieneViajeActivo
                              ? ElevatedButton.icon(
                                  onPressed: () => _finalizarViaje(context),
                                  icon: const Icon(Icons.stop, size: 20),
                                  label: const Text('Finalizar Viaje'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _iniciarViaje(context),
                                  icon: const Icon(Icons.play_arrow, size: 20),
                                  label: const Text('Iniciar Viaje'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  // 🎯 ACCIONES
  // ════════════════════════════════════════════════════════

  /// Cambiar sentido del recorrido
  void _cambiarSentido(BuildContext context) {
    final conductorProvider = context.read<ConductorProvider>();
    final sentidoActual = conductorProvider.sentidoActual;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Sentido'),
        content: Text('Sentido actual: ${sentidoActual.toUpperCase()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              conductorProvider.cambiarSentido('ida');
              _mostrarSnackbar('Sentido cambiado a IDA', Colors.blue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: const Text('IDA'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              conductorProvider.cambiarSentido('vuelta');
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

  /// Iniciar viaje
  Future<void> _iniciarViaje(BuildContext context) async {
    final conductorProvider = context.read<ConductorProvider>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Viaje'),
        content: const Text('¿Estás listo para iniciar el viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final success = await conductorProvider.iniciarViaje();
      if (success) {
        _mostrarSnackbar('Viaje iniciado', Colors.green);
      } else {
        _mostrarSnackbar(
          conductorProvider.error ?? 'No se pudo iniciar el viaje',
          Colors.red,
        );
      }
    }
  }

  /// Finalizar viaje
  Future<void> _finalizarViaje(BuildContext context) async {
    final conductorProvider = context.read<ConductorProvider>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Viaje'),
        content: const Text('¿Deseas finalizar el viaje actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final success = await conductorProvider.finalizarViaje();
      if (success) {
        _mostrarSnackbar('Viaje finalizado', Colors.orange);
      } else {
        _mostrarSnackbar(
          conductorProvider.error ?? 'No se pudo finalizar el viaje',
          Colors.red,
        );
      }
    }
  }

  /// Confirmar logout
  Future<void> _confirmarLogout(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
            '¿Estás seguro de que quieres salir del modo conductor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final conductorProvider = context.read<ConductorProvider>();
      await conductorProvider.logout();

      if (context.mounted) {
        final username = await _obtenerUsername();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: username),
          ),
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔧 UTILIDADES
  // ════════════════════════════════════════════════════════

  /// Obtener username de SharedPreferences
  Future<String> _obtenerUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('username') ?? 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }

  /// Mostrar snackbar
  void _mostrarSnackbar(String mensaje, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
