// ════════════════════════════════════════════════════════
// 🏠 PANTALLA HOME - TRANSPORTE INTELIGENTE
// lib/presentation/screens/home_screen.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mapa_tiempo_real_screen.dart';
import '../../data/models/ruta_model.dart';
import '../../widgets/chat_floating_button.dart';
import '../../widgets/lineas_cercanas_widget.dart';
import '../../widgets/buscador_destino_widget.dart';
import '../../widgets/resultado_busqueda_widget.dart';
import '../providers/ruta_provider.dart';
import '../providers/ubicacion_provider.dart';
import '../providers/conductor_provider.dart';
import '../providers/bus_provider.dart';
import 'welcome_screen.dart';
import 'login_conductor_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _mostrandoResultados = false;
  String _textoBusqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarDatos();
    });
  }

  // ════════════════════════════════════════════════════════
  // 🚀 INICIALIZACIÓN
  // ════════════════════════════════════════════════════════

  Future<void> _inicializarDatos() async {
    final ubicacionProvider = context.read<UbicacionProvider>();
    final rutaProvider = context.read<RutaProvider>();
    final conductorProvider = context.read<ConductorProvider>();
    final busProvider = context.read<BusProvider>();

    // Verificar permisos de ubicación
    await ubicacionProvider.verificarPermisos();

    // Obtener ubicación actual (se mantiene para que el mapa se centre correctamente)
    await ubicacionProvider.obtenerUbicacionActual();

    // Iniciar seguimiento continuo
    ubicacionProvider.iniciarSeguimiento();

    // Conectar WebSocket para buses en tiempo real (no await para evitar bloqueos si el backend no responde)
    busProvider.conectarWebSocket();

    // Diferenciar entre modo usuario y conductor
    if (conductorProvider.estaLogeado) {
      // ════════════════════════════════════════════════════════
      // MODO CONDUCTOR
      // ════════════════════════════════════════════════════════
      final conductor = conductorProvider.conductor;

      if (conductor != null && conductor.rutaId != null) {
        // Cargar ruta del conductor y buses, pero con timeout para no bloquear la UI
        rutaProvider
            .cargarRutaPorId(conductor.rutaId!)
            .timeout(const Duration(seconds: 8), onTimeout: () {
          print('⚠️ Timeout cargando ruta ${conductor.rutaId}');
          return Future.value();
        }).catchError((e) {
          print('❌ Error cargando ruta conductor: $e');
        });

        busProvider
            .cargarBusesPorRuta(conductor.rutaId!)
            .timeout(const Duration(seconds: 8), onTimeout: () {
          print('⚠️ Timeout cargando buses ruta ${conductor.rutaId}');
          return Future.value();
        }).catchError((e) {
          print('❌ Error cargando buses conductor: $e');
        });

        print(
            '🚗 Modo conductor activo - Carga iniciada para ruta ${conductor.rutaId}');
      }
    } else {
      // ════════════════════════════════════════════════════════
      // MODO USUARIO
      // ════════════════════════════════════════════════════════
      // Se usa la posición del provider (o fallback a Juliaca) para cargar rutas cercanas.
      final double latInicial =
          ubicacionProvider.posicionActual?.latitude ?? -15.50;
      final double lngInicial =
          ubicacionProvider.posicionActual?.longitude ?? -70.13;
      await rutaProvider.cargarRutasCercanas(
        latInicial,
        lngInicial,
        radioKm: 5.0,
      );

      // Cargar todos los buses activos
      await busProvider.cargarBusesActivos();

      print(
          '👤 Modo usuario (con ubicación fija de prueba) - Rutas y buses cargados');
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔍 BÚSQUEDA
  // ════════════════════════════════════════════════════════

  Future<void> _buscarRutas(String destino) async {
    setState(() {
      _textoBusqueda = destino;
      _mostrandoResultados = true;
    });

    final rutaProvider = context.read<RutaProvider>();

    // Usamos la ubicación del provider para la búsqueda por destino
    await rutaProvider.buscarPorDestino(
      destino,
      context.read<UbicacionProvider>().posicionActual?.latitude ??
          -15.50, // Fallback a Juliaca
      context.read<UbicacionProvider>().posicionActual?.longitude ??
          -70.13, // Fallback a Juliaca
      radioKm: 5.0,
    );
  }

  void _limpiarBusqueda() {
    setState(() {
      _mostrandoResultados = false;
      _textoBusqueda = '';
    });
    context.read<RutaProvider>().limpiarBusqueda();
  }

  void _verRuta(RutaModel ruta) async {
    final rutaProvider = context.read<RutaProvider>();
    final busProvider = context.read<BusProvider>();

    // Seleccionar la ruta (carga coordenadas completas)
    await rutaProvider.seleccionarRuta(ruta.id);

    // Cargar buses de esa ruta
    await busProvider.cargarBusesPorRuta(ruta.id);

    // Limpiar búsqueda si estaba activa
    if (_mostrandoResultados) {
      _limpiarBusqueda();
    }
  }

  // ════════════════════════════════════════════════════════
  // 👤 PERFIL Y SESIÓN
  // ════════════════════════════════════════════════════════

  void _mostrarMenuPerfil() async {
    final conductorProvider = context.read<ConductorProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastre
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: conductorProvider.estaLogeado
                  ? Colors.orange.shade700
                  : Colors.indigo.shade700,
              child: Text(
                widget.username[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nombre
            Text(
              widget.username,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Info conductor si está logueado
            if (conductorProvider.estaLogeado) ...[
              const SizedBox(height: 8),
              Text(
                'Conductor - ${conductorProvider.conductor?.rutaCompleta ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vehículo: ${conductorProvider.conductor?.vehiculoInfo ?? 'Sin asignar'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Opciones según modo
            if (conductorProvider.estaLogeado) ...[
              // MODO CONDUCTOR ACTIVO
              ListTile(
                leading:
                    Icon(Icons.directions_bus, color: Colors.orange.shade700),
                title: const Text('Modo Conductor Activo'),
                subtitle: Text(conductorProvider.conductor?.rutaCompleta ?? ''),
                trailing:
                    Icon(Icons.check_circle, color: Colors.green.shade700),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.orange.shade700),
                title: const Text('Salir del Modo Conductor'),
                onTap: () {
                  Navigator.pop(context);
                  _salirModoConductor();
                },
              ),
              const Divider(),
            ] else ...[
              // MODO USUARIO NORMAL
              ListTile(
                leading:
                    Icon(Icons.directions_bus, color: Colors.orange.shade700),
                title: const Text('Modo Conductor'),
                subtitle: const Text('Iniciar sesión como conductor'),
                onTap: () {
                  Navigator.pop(context);
                  _irALoginConductor();
                },
              ),
              const Divider(),
            ],

            // Opciones comunes
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Cambiar nombre'),
              onTap: () {
                Navigator.pop(context);
                _cambiarNombre();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _cerrarSesion();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salirModoConductor() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del Modo Conductor'),
        content: const Text(
            '¿Estás seguro de que quieres salir del modo conductor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final conductorProvider = context.read<ConductorProvider>();
      await conductorProvider.logout();

      // Recargar datos en modo usuario
      if (mounted) {
        // Navegar a una nueva instancia de HomeScreen para forzar una recarga completa.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: widget.username),
          ),
        );
      }
    }
  }

  void _irALoginConductor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginConductorScreen(),
      ),
    ).then((_) {
      // Recargar datos después del login
      _inicializarDatos();
    });
  }

  Future<void> _cambiarNombre() async {
    final controller = TextEditingController(text: widget.username);

    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar nombre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nuevo nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoNombre != null &&
        nuevoNombre.isNotEmpty &&
        nuevoNombre != widget.username) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', nuevoNombre);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: nuevoNombre),
          ),
        );
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');

      // Cerrar sesión de conductor si estaba activo
      final conductorProvider = context.read<ConductorProvider>();
      if (conductorProvider.estaLogeado) {
        await conductorProvider.logout();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎨 UI
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Hola, '),
            Text(
              widget.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(' 👋'),
          ],
        ),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _mostrarMenuPerfil,
            tooltip: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ChatFloatingButton(username: widget.username),
        ),
      ),
      body: Stack(
        children: [
          // ════════════════════════════════════════════════════════
          // MAPA PRINCIPAL
          // ════════════════════════════════════════════════════════
          Consumer<ConductorProvider>(
            builder: (context, conductorProvider, child) {
              return MapaTiempoRealScreen(
                modoConductor: conductorProvider.estaLogeado,
                conductorId: conductorProvider.conductor?.id,
                rutaId: conductorProvider.conductor?.rutaId,
              );
            },
          ),

          // ════════════════════════════════════════════════════════
          // WIDGETS SOBRE EL MAPA
          // ════════════════════════════════════════════════════════
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer<RutaProvider>(
                    builder: (context, rutaProvider, child) {
                      return BuscadorDestinoWidget(
                        onBuscar: _buscarRutas,
                        onLimpiar: _limpiarBusqueda,
                        cargando: rutaProvider.cargando,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Líneas cercanas o resultados de búsqueda
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer2<RutaProvider, UbicacionProvider>(
                    builder: (context, rutaProvider, ubicacionProvider, child) {
                      if (_mostrandoResultados) {
                        return ResultadoBusquedaWidget(
                          resultados: rutaProvider.resultadosBusqueda,
                          textoBusqueda: _textoBusqueda,
                          onVerRuta: _verRuta,
                        );
                      }

                      return LineasCercanasWidget(
                        rutasCercanas: rutaProvider.rutasCercanas,
                        cargando: rutaProvider.cargando,
                        onVerRuta: _verRuta,
                        miLatitud: ubicacionProvider.posicionActual?.latitude ??
                            -15.50, // Fallback a Juliaca
                        miLongitud:
                            ubicacionProvider.posicionActual?.longitude ??
                                -70.13, // Fallback a Juliaca
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
